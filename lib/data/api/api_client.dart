import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/web/web_sso.dart';
import '../auth/alpha_auth_session.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String tokenKey = 'auth_token';

  // Callback to notify AuthProvider when 401 occurs
  void Function()? onUnauthorized;

  ApiClient._internal() {
    var baseUrl =
        dotenv.env['API_URL'] ?? 'https://alpha-studio-backend.fly.dev/api';

    if (kIsWeb) {
      final webBaseUrl = getWebBaseUrl();
      if (webBaseUrl != null) {
        baseUrl = webBaseUrl;
      }
    }

    debugPrint('ApiClient: Initializing with baseUrl=$baseUrl');

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint('ApiClient [REQ] ${options.method} ${options.path} — token attached (${token.length} chars, ...${token.substring(token.length > 10 ? token.length - 10 : 0)})');
        } else {
          debugPrint('ApiClient [REQ] ${options.method} ${options.path} — NO TOKEN');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        final status = error.response?.statusCode;
        debugPrint('ApiClient [ERR] $status on ${error.requestOptions.method} $path');
        if (status == 401) {
          final hasToken = error.requestOptions.headers.containsKey('Authorization');
          final isAuthEndpoint = path.contains('/auth/login') || path.contains('/auth/register');
          
          if (!isAuthEndpoint && (!path.contains('/auth/me') || hasToken)) {
            debugPrint('ApiClient [ERR] 401 on $path — clearing token and notifying listeners');
            await clearToken();
            onUnauthorized?.call();
          } else {
            debugPrint('ApiClient [ERR] 401 on $path — ignoring global unauthorized');
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> setToken(String token) async {
    debugPrint('ApiClient.setToken: storing token (${token.length} chars)');
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, token);
        debugPrint('ApiClient.setToken: SharedPreferences OK');
      } catch (e) {
        debugPrint('ApiClient.setToken: SharedPreferences error: $e');
        rethrow;
      }
      persistWebSsoToken(token);
      debugPrint('ApiClient.setToken: localStorage persisted');
    } else {
      try {
        await _secureStorage.write(key: tokenKey, value: token);
      } catch (e) {
        debugPrint('SecureStorage setToken error: $e');
        rethrow;
      }
      // Tuyệt đối không lưu token vào SharedPreferences trên mobile/desktop
    }
    // Verify token was stored
    final verify = await getToken();
    debugPrint('ApiClient.setToken: verification read back ${verify != null ? "${verify.length} chars" : "NULL"}');
  }

  Future<void> clearToken() async {
    debugPrint('ApiClient.clearToken: CLEARING TOKEN');
    debugPrint('ApiClient.clearToken: caller stack: ${StackTrace.current.toString().split('\n').take(5).join(' | ')}');
    Object? caughtError;
    
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(tokenKey);
      } catch (e) {
        debugPrint('SharedPreferences clearToken error: $e');
        caughtError = e;
      }
      clearStoredWebSsoToken();
      AlphaAuthSession().clear();
    } else {
      try {
        await _secureStorage.delete(key: tokenKey);
      } catch (e) {
        debugPrint('SecureStorage clearToken error: $e');
        caughtError = e;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(tokenKey);
      } catch (e) {
        debugPrint('SharedPreferences clearToken error: $e');
        if (caughtError != null) {
          caughtError = Exception('Multiple errors: 1) $caughtError, 2) $e');
        } else {
          caughtError = e;
        }
      }
      AlphaAuthSession().clear();
    }
    
    debugPrint('ApiClient.clearToken: DONE');
    if (caughtError != null) throw caughtError;
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      final webToken = getStoredWebSsoToken();
      if (webToken != null && webToken.isNotEmpty) {
        debugPrint('ApiClient.getToken: found in localStorage (${webToken.length} chars)');
        return webToken;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        final persistedToken = prefs.getString(tokenKey);
        if (persistedToken != null && persistedToken.isNotEmpty) {
          debugPrint('ApiClient.getToken: found in SharedPreferences (${persistedToken.length} chars)');
          return persistedToken;
        }
      } catch (e) {
        debugPrint('SharedPreferences getToken error: $e');
        rethrow;
      }
      debugPrint('ApiClient.getToken: NO TOKEN found on web');
      return null;
    } else {
      try {
        final secureToken = await _secureStorage.read(key: tokenKey);
        if (secureToken != null && secureToken.isNotEmpty) {
          return secureToken;
        }
      } catch (e) {
        debugPrint('SecureStorage read error: $e');
        rethrow;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final persistedToken = prefs.getString(tokenKey);
        if (persistedToken != null && persistedToken.isNotEmpty) {
          try {
            await _secureStorage.write(key: tokenKey, value: persistedToken);
            await prefs.remove(tokenKey); // Xoá plaintext token sau khi migrate
          } catch (e) {
            debugPrint('SecureStorage write error: $e');
            rethrow;
          }
          return persistedToken;
        }
      } catch (e) {
        debugPrint('SharedPreferences getToken error: $e');
        rethrow;
      }
      return null;
    }
  }
}

