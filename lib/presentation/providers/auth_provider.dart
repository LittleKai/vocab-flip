import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/remote/firebase/firebase_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  AuthStatus _status = AuthStatus.initial;
  String? _error;
  User? _user;

  /// Callback triggered after successful sign-in (used to sync profile, etc.)
  void Function()? onSignIn;

  AuthStatus get status => _status;
  String? get error => _error;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName;

  AuthProvider() {
    _init();
  }

  void _init() {
    _firebaseService.initialize();

    // Listen to auth state changes
    _firebaseService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    debugPrint('AuthProvider.signInWithGoogle: Starting...');
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final credential = await _firebaseService.signInWithGoogle();
      debugPrint('AuthProvider.signInWithGoogle: credential=${credential != null ? 'present' : 'null'}, user=${credential?.user?.email ?? 'null'}');

      if (credential?.user != null) {
        _user = credential!.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        debugPrint('AuthProvider.signInWithGoogle: Success, calling onSignIn...');
        onSignIn?.call();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _error = 'Google sign in was cancelled';
      debugPrint('AuthProvider.signInWithGoogle: Cancelled or null credential');
      notifyListeners();
      return false;
    } catch (e, stack) {
      debugPrint('AuthProvider.signInWithGoogle ERROR: $e');
      debugPrint('AuthProvider.signInWithGoogle STACK: $stack');
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _firebaseService.signOut();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
