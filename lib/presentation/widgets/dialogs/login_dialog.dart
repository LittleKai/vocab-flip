import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginDialog {
  static void show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _nameController = TextEditingController();
    bool _isRegistering = false;
    final primaryColor = Theme.of(context).colorScheme.primary;

    AwesomeDialog(
      context: context,
      width: 520,
      dialogType: kIsWeb ? DialogType.noHeader : DialogType.info,
      customHeader: kIsWeb
          ? CircleAvatar(
              radius: 32,
              backgroundColor: primaryColor.withOpacity(0.12),
              child: Icon(Icons.login_rounded, size: 36, color: primaryColor),
            )
          : null,
      animType: AnimType.bottomSlide,
      dialogBackgroundColor: Theme.of(context).colorScheme.surface,
      body: StatefulBuilder(
        builder: (context, setState) {
          final auth = context.watch<AuthProvider>();

          void _submit() async {
            final email = _emailController.text.trim();
            final password = _passwordController.text;
            final name = _nameController.text.trim();

            if (email.isEmpty || password.isEmpty) return;

            bool success = false;
            if (_isRegistering) {
              success = await auth.register(
                  email, password, name.isEmpty ? 'User' : name);
            } else {
              success = await auth.login(email, password);
            }

            if (success && context.mounted) {
              Navigator.pop(context);
            }
          }

          return SafeArea(
            top: false,
            left: false,
            right: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.72,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isRegistering ? l10n.signUp : l10n.signIn,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(context),
                                ),
                      ),
                      const SizedBox(height: 24),

                      // Error message
                      if (auth.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(
                                      color: AppColors.error, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_isRegistering) ...[
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.nickname,
                            border: const OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isRegistering ? l10n.signUp : l10n.signIn,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                            auth.clearError();
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary(context),
                        ),
                        child: Text(
                          _isRegistering
                              ? '${l10n.alreadyHaveAccount} ${l10n.signIn}'
                              : l10n.createAccount,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).show();
  }
}
