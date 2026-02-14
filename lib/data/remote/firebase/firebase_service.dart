import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

        // GoogleSignIn may not work on all platforms (e.g., Windows)
        try {
          _googleSignIn = GoogleSignIn();
        } catch (e) {
          debugPrint('GoogleSignIn not available on this platform: $e');
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
    if (!_initialized || _googleSignIn == null) return null;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_initialized) return null;

    try {
      return await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    if (!_initialized) return null;

    try {
      return await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;

    await _googleSignIn?.signOut();
    await _auth?.signOut();
  }

  Future<void> resetPassword(String email) async {
    if (!_initialized) return;

    await _auth?.sendPasswordResetEmail(email: email);
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
