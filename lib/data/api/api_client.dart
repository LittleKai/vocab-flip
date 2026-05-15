import 'package:dio/dio.dart';
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

  ApiClient._internal() {
    final baseUrl =
        dotenv.env['API_URL'] ?? 'https://alpha-studio-backend.fly.dev/api';

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
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          await clearToken();
          // Could trigger a stream or callback to logout user
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> setToken(String token) async {
    await _secureStorage.write(key: tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    persistWebSsoToken(token);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    clearStoredWebSsoToken();
    AlphaAuthSession().clear();
  }

  Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(key: tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final persistedToken = prefs.getString(tokenKey);
    if (persistedToken != null && persistedToken.isNotEmpty) {
      await _secureStorage.write(key: tokenKey, value: persistedToken);
      return persistedToken;
    }

    return null;
  }
}
