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

  Future<bool> signInWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _user = credential.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _error = 'Sign in failed';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, {String? displayName}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final credential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }

        _user = credential.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _error = 'Sign up failed';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final credential = await _firebaseService.signInWithGoogle();

      if (credential?.user != null) {
        _user = credential!.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _error = 'Google sign in was cancelled';
      notifyListeners();
      return false;
    } catch (e) {
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

  Future<bool> resetPassword(String email) async {
    _error = null;

    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
