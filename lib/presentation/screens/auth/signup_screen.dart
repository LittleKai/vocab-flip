import 'package:flutter/material.dart';
import '../../widgets/dialogs/login_dialog.dart';

/// Signup screen now redirects to LoginDialog (Google-only auth).
/// Kept as a redirect for backward compatibility.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context); // popup this screen
      LoginDialog.show(context);
    });
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}
