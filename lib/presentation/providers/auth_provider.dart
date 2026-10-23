import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/api/api_client.dart';
import '../../data/auth/alpha_auth_session.dart';

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
    ++_loadVersion;
    _authRepository.invalidatePending();
    if (_status != AuthStatus.unauthenticated) {
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

    if (initialToken != null && initialToken.isNotEmpty) {
      await _authRepository.setToken(initialToken);
      if (version != _loadVersion) return;
    } else if (kIsWeb) {
      // In the embedded web build the Alpha Studio shell sends the JWT via
      // postMessage after the iframe is ready. Avoid calling /auth/me before
      // that token arrives, otherwise the startup request logs a noisy 401.
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Check if token exists and fetch user profile
    final AppUser? me = await _authRepository.getMe();
    if (version != _loadVersion) return;

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

    final wasAuthenticated = isAuthenticated;
    final version = ++_loadVersion;

    await _authRepository.setToken(token);
    if (version != _loadVersion) return;
    final me = await _authRepository.getMe();
    if (version != _loadVersion) {
      return;
    }

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
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final version = ++_loadVersion;
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authRepository.login(email, password);

    if (version != _loadVersion) return false;
    if (result['success'] == true) {
      final me =
          AppUser.fromAuthResponse(result) ?? await _authRepository.getMe();
      if (version != _loadVersion) return false;
      if (me != null) {
        AlphaAuthSession().setUser(
            userId: me.id, email: me.email, displayName: me.displayName);
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
    final version = ++_loadVersion;
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authRepository.register(email, password, name);

    if (version != _loadVersion) return false;
    if (result['success'] == true) {
      final me =
          AppUser.fromAuthResponse(result) ?? await _authRepository.getMe();
      if (version != _loadVersion) return false;
      if (me != null) {
        AlphaAuthSession().setUser(
            userId: me.id, email: me.email, displayName: me.displayName);
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

  Future<void> signOut() async {
    ++_loadVersion;
    _authRepository.invalidatePending();
    // Update UI immediately; an offline or delayed revoke cannot restore it.
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    AlphaAuthSession().clear();
    final logout = _authRepository.logout();
    notifyListeners();
    await logout;
  }

  @override
  void dispose() {
    ++_loadVersion;
    _authRepository.invalidatePending();
    ApiClient().onUnauthorized = null;
    super.dispose();
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
