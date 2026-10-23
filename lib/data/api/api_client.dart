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
  void Function()? onUnauthorized;
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;
  String? _token;
  bool _tokenKnown = false;
  Future<void> _storageWork = Future<void>.value();

  ApiClient._internal() {
    var baseUrl =
        dotenv.env['API_URL'] ?? 'https://alpha-studio-backend.fly.dev/api';
    if (kIsWeb) baseUrl = getWebBaseUrl() ?? baseUrl;
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final version = options.extra['sessionVersion'] ?? _sessionVersion;
        try {
          final token =
              options.extra['logoutToken'] as String? ?? await getToken();
          final owner = options.extra['syncOwnerUserId'];
          if (version != _sessionVersion ||
              (options.extra.containsKey('syncOwnerUserId') &&
                  (owner == null || owner != AlphaAuthSession().userId))) {
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Account changed before request dispatch',
            ));
          }
          options.extra['sessionVersion'] = version;
          options.headers.remove('Authorization');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        } catch (error) {
          handler.reject(DioException(requestOptions: options, error: error));
        }
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        final isLogin = options.path == '/auth/login' ||
            options.path == '/auth/register' ||
            options.path == '/auth/logout';
        if (error.response?.statusCode == 401 &&
            !isLogin &&
            options.headers.containsKey('Authorization') &&
            options.extra['sessionVersion'] == _sessionVersion) {
          final clearing = clearToken();
          // Invalidate UI requests immediately, before storage can yield to a new login.
          onUnauthorized?.call();
          try {
            await clearing;
          } catch (_) {/* Memory stays signed out. */}
        }
        handler.next(error);
      },
    ));
  }

  Future<void> _store(Future<void> Function() action) {
    final work = _storageWork.then((_) => action());
    _storageWork =
        work.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return work;
  }

  Future<void> setToken(String token) {
    if (token.isEmpty)
      throw ArgumentError.value(null, 'token', 'Must not be empty');
    ++_sessionVersion;
    _tokenKnown = true;
    _token = token;
    AlphaAuthSession().clear();
    return _store(() async {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, token);
        persistWebSsoToken(token);
      } else {
        await _secureStorage.write(key: tokenKey, value: token);
      }
    });
  }

  Future<void> clearToken() {
    final departingToken = _token;
    ++_sessionVersion;
    _tokenKnown = true;
    _token = null;
    AlphaAuthSession().clear();
    // Clear aliases immediately, before the serialized storage operation.
    if (kIsWeb) clearStoredWebSsoToken(departingToken: departingToken);
    return _store(() async {
      // A preceding setToken may finish its awaited write after immediate clear.
      if (kIsWeb) clearStoredWebSsoToken(departingToken: departingToken);
      if (!kIsWeb) await _secureStorage.delete(key: tokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
    });
  }

  Future<String?> getToken() async {
    final version = _sessionVersion;
    await _storageWork;
    if (version != _sessionVersion || _tokenKnown) return _token;
    String? stored;
    if (kIsWeb) {
      stored = getStoredWebSsoToken();
      stored ??= (await SharedPreferences.getInstance()).getString(tokenKey);
    } else {
      stored = await _secureStorage.read(key: tokenKey);
      if (version != _sessionVersion) return _token;
      if (stored == null || stored.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        if (version != _sessionVersion) return _token;
        stored = prefs.getString(tokenKey);
        if (stored != null && stored.isNotEmpty) {
          final migrating = stored;
          await _store(() async {
            if (version != _sessionVersion) return;
            await _secureStorage.write(key: tokenKey, value: migrating);
            await prefs.remove(tokenKey);
          });
        }
      }
    }
    if (version != _sessionVersion) return _token;
    _token = stored == null || stored.isEmpty ? null : stored;
    _tokenKnown = true;
    return _token;
  }
}
