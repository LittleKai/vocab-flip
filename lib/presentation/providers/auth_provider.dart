import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  static const String _adminEmail = 'aduc5525@gmail.com';
  final AuthRepository _authRepository = AuthRepository();
  int _loadVersion = 0;

  AuthStatus _status = AuthStatus.initial;
  String? _error;
  AppUser? _user;

  /// Callback triggered after successful sign-in
  void Function()? onSignIn;

  AuthStatus get status => _status;
  String? get error => _error;
  AppUser? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => isAuthenticated && _user?.email == _adminEmail;
  bool get isLoading => _status == AuthStatus.loading;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName;
  int get balance => _user?.balance ?? 0;

  AuthProvider({String? initialToken}) {
    ApiClient().onUnauthorized = _handleUnauthorized;
    _init(initialToken: initialToken);
  }

  void _handleUnauthorized() {
    if (_status != AuthStatus.unauthenticated) {
      debugPrint('AuthProvider: Received unauthorized signal, logging out user.');
      _user = null;
      _status = AuthStatus.unauthenticated;
      _error = 'Session expired. Please log in again.';
      notifyListeners();
    }
  }

  Future<void> _init({String? initialToken}) async {
    final version = ++_loadVersion;
    _status = AuthStatus.loading;
    notifyListeners();

    debugPrint('AuthProvider._init: initialToken=${initialToken != null ? "${initialToken.length} chars" : "null"}, kIsWeb=$kIsWeb');

    if (initialToken != null && initialToken.isNotEmpty) {
      await _authRepository.setToken(initialToken);
    } else if (kIsWeb) {
      // In the embedded web build the Alpha Studio shell sends the JWT via
      // postMessage after the iframe is ready. Avoid calling /auth/me before
      // that token arrives, otherwise the startup request logs a noisy 401.
      debugPrint('AuthProvider._init: kIsWeb and no initialToken, setting unauthenticated');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Check if token exists and fetch user profile
    debugPrint('AuthProvider._init: calling getMe()...');
    final AppUser? me = await _authRepository.getMe();
    if (version != _loadVersion) return;

    debugPrint('AuthProvider._init: getMe() returned ${me != null ? "user: ${me.email}" : "null"}');
    if (me != null) {
      _user = me;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> applyToken(String token) async {
    if (token.isEmpty) return;

    debugPrint('AuthProvider.applyToken: received token (${token.length} chars)');
    final wasAuthenticated = isAuthenticated;
    final version = ++_loadVersion;

    await _authRepository.setToken(token);
    debugPrint('AuthProvider.applyToken: token stored, now calling getMe()...');
    final me = await _authRepository.getMe();
    if (version != _loadVersion) {
      debugPrint('AuthProvider.applyToken: version mismatch, aborting');
      return;
    }

    debugPrint('AuthProvider.applyToken: getMe() returned ${me != null ? "user: ${me.email}" : "null"}');
    if (me != null) {
      _user = me;
      _status = AuthStatus.authenticated;
      _error = null;
      if (!wasAuthenticated) {
        onSignIn?.call();
      }
    } else {
      _user = null;
      _status = AuthStatus.unauthenticated;
      debugPrint('AuthProvider.applyToken: getMe returned null => unauthenticated');
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authRepository.login(email, password);

    if (result['success'] == true) {
      final me =
          AppUser.fromAuthResponse(result) ?? await _authRepository.getMe();
      if (me != null) {
        _user = me;
        _status = AuthStatus.authenticated;
        onSignIn?.call();
        notifyListeners();
        return true;
      }
    }

    _status = AuthStatus.unauthenticated;
    _error = result['message']?.toString() ?? 'Login failed';
    notifyListeners();
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authRepository.register(email, password, name);

    if (result['success'] == true) {
      final me =
          AppUser.fromAuthResponse(result) ?? await _authRepository.getMe();
      if (me != null) {
        _user = me;
        _status = AuthStatus.authenticated;
        onSignIn?.call();
        notifyListeners();
        return true;
      }
    }

    _status = AuthStatus.unauthenticated;
    _error = result['message']?.toString() ?? 'Registration failed';
    notifyListeners();
    return false;
  }

  Future<bool> signInWithGoogle() async {
    // Left as stub for backward compatibility in UI, or wait to implement actual alpha-studio login Google
    _error =
        'Not available in Alpha Studio integration mode yet. Please login manually.';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<void> refreshProfile() async {
    final version = ++_loadVersion;
    final me = await _authRepository.getMe();
    if (version != _loadVersion) return;

    if (me != null) {
      _user = me;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } else {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void openTopupWallet() async {
    final url = Uri.parse('https://alphastudio.vercel.app/workflow');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not open Alpha Studio topup page');
    }
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authRepository.logout();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status =
          _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
