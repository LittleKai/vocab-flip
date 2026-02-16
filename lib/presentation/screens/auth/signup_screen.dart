import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Signup screen now redirects to LoginScreen (Google-only auth).
/// Kept as a redirect for backward compatibility.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to login screen (Google-only)
    return const LoginScreen();
  }
}
