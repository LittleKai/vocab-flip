import 'dart:convert';
import 'dart:io' show HttpServer, HttpStatus, ContentType, Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  bool _initialized = false;

  FirebaseAuth get auth {
    _ensureInitialized();
    return _auth!;
  }

  User? get currentUser {
    _ensureInitialized();
    return _auth?.currentUser;
  }
  bool get isSignedIn => currentUser != null;
  bool get isInitialized => _initialized;
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? Stream.value(null);

  String? get userId => currentUser?.uid;
  String? get userName => currentUser?.displayName;
  String? get userEmail => currentUser?.email;

  /// Ensure service is initialized (call this lazily)
  void _ensureInitialized() {
    if (_initialized) return;

    try {
      // Firebase should already be initialized in main.dart
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _initialized = true;

        // GoogleSignIn plugin is not available on Windows
        if (kIsWeb || !Platform.isWindows) {
          try {
            _googleSignIn = GoogleSignIn();
          } catch (e) {
            debugPrint('GoogleSignIn not available on this platform: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize FirebaseService: $e');
      _initialized = false;
    }
  }

  Future<void> initialize() async {
    _ensureInitialized();
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (!_initialized) return null;

    // On Windows, use browser-based OAuth flow
    if (!kIsWeb && Platform.isWindows) {
      return _signInWithGoogleDesktop();
    }

    // On mobile/web, use GoogleSignIn plugin
    debugPrint('FirebaseService.signInWithGoogle: Starting mobile/web flow');
    debugPrint('FirebaseService.signInWithGoogle: _googleSignIn=${_googleSignIn != null}, _auth=${_auth != null}');

    if (_googleSignIn == null) {
      debugPrint('FirebaseService.signInWithGoogle: _googleSignIn is null, cannot proceed');
      return null;
    }

    try {
      debugPrint('FirebaseService.signInWithGoogle: Calling _googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      debugPrint('FirebaseService.signInWithGoogle: googleUser=${googleUser?.email ?? 'null (cancelled)'}');
      if (googleUser == null) return null;

      debugPrint('FirebaseService.signInWithGoogle: Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint('FirebaseService.signInWithGoogle: accessToken=${googleAuth.accessToken != null ? '(present)' : 'null'}, idToken=${googleAuth.idToken != null ? '(present)' : 'null'}');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('FirebaseService.signInWithGoogle: Signing in to Firebase with credential...');
      final result = await _auth!.signInWithCredential(credential);
      debugPrint('FirebaseService.signInWithGoogle: Success! user=${result.user?.email}');
      return result;
    } catch (e, stack) {
      debugPrint('FirebaseService.signInWithGoogle ERROR: $e');
      debugPrint('FirebaseService.signInWithGoogle STACK: $stack');
      return null;
    }
  }

  /// Google Sign-In on Windows via browser OAuth flow
  Future<UserCredential?> _signInWithGoogleDesktop() async {
    final clientId = dotenv.env['GOOGLE_OAUTH_CLIENT_ID'];
    final clientSecret = dotenv.env['GOOGLE_OAUTH_CLIENT_SECRET'];

    if (clientId == null || clientId.isEmpty) {
      debugPrint('FirebaseService: GOOGLE_OAUTH_CLIENT_ID not configured in .env');
      return null;
    }

    try {
      // Start local server to receive OAuth callback
      final server = await HttpServer.bind('localhost', 0);
      final redirectUri = 'http://localhost:${server.port}';

      // Build authorization URL
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'email profile openid',
        'access_type': 'offline',
        'prompt': 'select_account',
      });

      // Open browser for authentication
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        await server.close();
        debugPrint('FirebaseService: Could not open browser');
        return null;
      }

      // Wait for callback
      String? authCode;
      await for (final request in server) {
        if (request.uri.path == '/' || request.uri.path.isEmpty) {
          authCode = request.uri.queryParameters['code'];

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write('''
              <html>
              <head><title>VocabFlip</title></head>
              <body style="font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5;">
                <div style="text-align: center; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                  <h2>${authCode != null ? '✓ Sign in successful!' : '✗ Sign in failed'}</h2>
                  <p>You can close this window and return to VocabFlip.</p>
                </div>
              </body>
              </html>
            ''');
          await request.response.close();
          break;
        }
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found');
        await request.response.close();
      }
      await server.close();

      if (authCode == null) {
        debugPrint('FirebaseService: No authorization code received');
        return null;
      }

      // Exchange code for tokens
      final tokenBody = <String, String>{
        'client_id': clientId,
        'code': authCode,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      };
      if (clientSecret != null && clientSecret.isNotEmpty) {
        tokenBody['client_secret'] = clientSecret;
      }

      final tokenResponse = await http.post(
        Uri.https('oauth2.googleapis.com', '/token'),
        body: tokenBody,
      );

      if (tokenResponse.statusCode != 200) {
        debugPrint('FirebaseService: Token exchange failed: ${tokenResponse.body}');
        return null;
      }

      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final idToken = tokenData['id_token'] as String?;
      final accessToken = tokenData['access_token'] as String?;

      if (idToken == null) {
        debugPrint('FirebaseService: No id_token in response');
        return null;
      }

      // Sign in to Firebase with the Google credential
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      debugPrint('FirebaseService: Desktop Google sign-in failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;

    await _googleSignIn?.signOut();
    await _auth?.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    if (!_initialized || currentUser == null) return;

    await currentUser!.updateDisplayName(name);
  }

  /// Get Firebase ID token for REST API authentication
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (!_initialized) {
      debugPrint('FirebaseService: getIdToken failed - not initialized');
      return null;
    }
    if (currentUser == null) {
      debugPrint('FirebaseService: getIdToken failed - currentUser is null (initialized=$_initialized, auth=${_auth != null})');
      return null;
    }

    try {
      return await currentUser!.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('FirebaseService: getIdToken exception: $e');
      return null;
    }
  }
}
