import 'dart:convert';
import 'dart:io' show Platform, HttpServer, HttpStatus, ContentType;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

/// Service for Google Drive operations using the appdata folder
class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  // For mobile platforms
  GoogleSignIn? _googleSignIn;

  // For desktop platforms
  auth.AuthClient? _authClient;

  drive.DriveApi? _driveApi;
  bool _isConnected = false;
  String? _userEmail;

  bool get isConnected => _isConnected;
  String? get userEmail => _userEmail;

  static const _backupMimeType = 'application/json';
  static const _backupFilePrefix = 'vocabflip_backup_';
  static const _backupFileExtension = '.json';

  static const _scopes = [
    'email',
    drive.DriveApi.driveAppdataScope,
  ];

  /// Get OAuth2 Client ID from environment
  /// Create a Desktop OAuth client ID in Google Cloud Console and add to .env:
  /// GOOGLE_OAUTH_CLIENT_ID=your_client_id.apps.googleusercontent.com
  /// GOOGLE_OAUTH_CLIENT_SECRET=your_client_secret
  auth.ClientId? get _clientId {
    final clientIdString = dotenv.env['GOOGLE_OAUTH_CLIENT_ID'];
    final clientSecret = dotenv.env['GOOGLE_OAUTH_CLIENT_SECRET'];
    if (clientIdString == null || clientIdString.isEmpty) {
      return null;
    }
    return auth.ClientId(clientIdString, clientSecret);
  }

  String? get _clientSecret => dotenv.env['GOOGLE_OAUTH_CLIENT_SECRET'];

  /// Check if we should use desktop OAuth flow
  bool get _useDesktopAuth {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Connect to Google Drive (sign in if necessary)
  Future<bool> connect() async {
    try {
      if (_useDesktopAuth) {
        return await _connectDesktop();
      } else {
        return await _connectMobile();
      }
    } catch (e) {
      debugPrint('Failed to connect to Google Drive: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Connect using mobile OAuth (google_sign_in)
  Future<bool> _connectMobile() async {
    _googleSignIn ??= GoogleSignIn(scopes: _scopes);

    // Try silent sign in first
    GoogleSignInAccount? account = await _googleSignIn!.signInSilently();

    // If silent sign in fails, prompt user
    account ??= await _googleSignIn!.signIn();

    if (account == null) {
      debugPrint('Google Sign-In cancelled by user');
      return false;
    }

    // Get authenticated HTTP client
    final httpClient = await _googleSignIn!.authenticatedClient();
    if (httpClient == null) {
      debugPrint('Failed to get authenticated client');
      return false;
    }

    _driveApi = drive.DriveApi(httpClient);
    _userEmail = account.email;
    _isConnected = true;

    debugPrint('Connected to Google Drive as ${account.email}');
    return true;
  }

  /// Connect using desktop OAuth (browser flow)
  Future<bool> _connectDesktop() async {
    final clientId = _clientId;
    if (clientId == null) {
      debugPrint('Google OAuth Client ID not configured. Add GOOGLE_OAUTH_CLIENT_ID to .env file.');
      throw Exception('Google Drive backup not configured. Please add GOOGLE_OAUTH_CLIENT_ID to .env file.');
    }

    try {
      // Start local server to receive OAuth callback
      final server = await HttpServer.bind('localhost', 0);
      final redirectUri = 'http://localhost:${server.port}';

      debugPrint('Starting OAuth flow with redirect: $redirectUri');

      // Build authorization URL
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId.identifier,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
      });

      // Open browser for authentication
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        await server.close();
        throw Exception('Could not open browser for authentication');
      }

      // Wait for callback
      String? authCode;
      await for (final request in server) {
        if (request.uri.path == '/' || request.uri.path.isEmpty) {
          authCode = request.uri.queryParameters['code'];

          // Send response to browser
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write('''
              <html>
              <head><title>VocabFlip</title></head>
              <body style="font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0;">
                <div style="text-align: center;">
                  <h2>${authCode != null ? '✓ Authentication successful!' : '✗ Authentication failed'}</h2>
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
        throw Exception('No authorization code received');
      }

      // Exchange code for tokens
      final tokenBody = <String, String>{
        'client_id': clientId.identifier,
        'code': authCode,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      };

      // Add client secret if available (required for Desktop apps)
      if (clientId.secret != null && clientId.secret!.isNotEmpty) {
        tokenBody['client_secret'] = clientId.secret!;
      }

      final tokenResponse = await http.post(
        Uri.https('oauth2.googleapis.com', '/token'),
        body: tokenBody,
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Failed to exchange code for tokens: ${tokenResponse.body}');
      }

      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String?;
      final expiresIn = tokenData['expires_in'] as int;

      // Create credentials
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
        ),
        refreshToken,
        _scopes,
      );

      // Create authenticated client
      _authClient = auth.authenticatedClient(http.Client(), credentials);
      _driveApi = drive.DriveApi(_authClient!);

      // Get user email
      await _fetchUserEmail(accessToken);

      _isConnected = true;
      debugPrint('Connected to Google Drive as $_userEmail');
      return true;
    } catch (e) {
      debugPrint('Desktop OAuth failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Fetch user email from Google
  Future<void> _fetchUserEmail(String accessToken) async {
    try {
      final response = await http.get(
        Uri.https('www.googleapis.com', '/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _userEmail = data['email'] as String?;
      }
    } catch (e) {
      debugPrint('Failed to fetch user email: $e');
    }
  }

  /// Disconnect from Google Drive
  Future<void> disconnect() async {
    try {
      if (_useDesktopAuth) {
        _authClient?.close();
        _authClient = null;
      } else {
        await _googleSignIn?.signOut();
      }
      _driveApi = null;
      _isConnected = false;
      _userEmail = null;
      debugPrint('Disconnected from Google Drive');
    } catch (e) {
      debugPrint('Error disconnecting from Google Drive: $e');
    }
  }

  /// Check if currently connected
  Future<bool> checkConnection() async {
    if (!_isConnected || _driveApi == null) {
      return false;
    }

    try {
      // Test connection by listing app data
      await _driveApi!.files.list(
        spaces: 'appDataFolder',
        pageSize: 1,
      );
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Upload backup data to Google Drive appdata folder
  Future<String?> uploadBackup(Map<String, dynamic> backupData, {
    void Function(int sent, int total)? onProgress,
  }) async {
    if (!_isConnected || _driveApi == null) {
      throw Exception('Not connected to Google Drive');
    }

    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = utf8.encode(jsonString);
      final stream = Stream.value(bytes);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = '$_backupFilePrefix$timestamp$_backupFileExtension';

      final fileMetadata = drive.File()
        ..name = fileName
        ..mimeType = _backupMimeType
        ..parents = ['appDataFolder'];

      final media = drive.Media(stream, bytes.length);

      final result = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      debugPrint('Backup uploaded: ${result.id} (${result.name})');
      return result.id;
    } catch (e) {
      debugPrint('Failed to upload backup: $e');
      rethrow;
    }
  }

  /// Download backup data from Google Drive
  Future<Map<String, dynamic>?> downloadBackup(String fileId) async {
    if (!_isConnected || _driveApi == null) {
      throw Exception('Not connected to Google Drive');
    }

    try {
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      debugPrint('Backup downloaded: $fileId');
      return data;
    } catch (e) {
      debugPrint('Failed to download backup: $e');
      rethrow;
    }
  }

  /// List all backups in the appdata folder
  Future<List<BackupFileInfo>> listBackups() async {
    if (!_isConnected || _driveApi == null) {
      throw Exception('Not connected to Google Drive');
    }

    try {
      final fileList = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name contains '$_backupFilePrefix'",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, size, createdTime, modifiedTime)',
      );

      return (fileList.files ?? []).map((file) => BackupFileInfo(
        id: file.id ?? '',
        name: file.name ?? '',
        size: int.tryParse(file.size ?? '0') ?? 0,
        createdAt: file.createdTime ?? DateTime.now(),
        modifiedAt: file.modifiedTime,
      )).toList();
    } catch (e) {
      debugPrint('Failed to list backups: $e');
      rethrow;
    }
  }

  /// Delete a backup from Google Drive
  Future<void> deleteBackup(String fileId) async {
    if (!_isConnected || _driveApi == null) {
      throw Exception('Not connected to Google Drive');
    }

    try {
      await _driveApi!.files.delete(fileId);
      debugPrint('Backup deleted: $fileId');
    } catch (e) {
      debugPrint('Failed to delete backup: $e');
      rethrow;
    }
  }

  /// Get backup metadata without downloading full content
  Future<Map<String, dynamic>?> getBackupMetadata(String fileId) async {
    if (!_isConnected || _driveApi == null) {
      throw Exception('Not connected to Google Drive');
    }

    try {
      // Download the file to get metadata
      // For larger files, we could parse just the first portion
      final data = await downloadBackup(fileId);
      if (data == null) return null;

      // Return just metadata portion
      return {
        'backup_version': data['backup_version'],
        'app_version': data['app_version'],
        'created_at': data['created_at'],
        'summary': data['summary'],
      };
    } catch (e) {
      debugPrint('Failed to get backup metadata: $e');
      return null;
    }
  }
}

/// Information about a backup file in Google Drive
class BackupFileInfo {
  final String id;
  final String name;
  final int size;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  const BackupFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdAt,
    this.modifiedAt,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'BackupFileInfo(id: $id, name: $name, size: $formattedSize)';
}
