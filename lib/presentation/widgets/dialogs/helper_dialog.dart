import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/preferences/app_preferences.dart';
import 'tts_help_dialog.dart';
import 'standard_dialog.dart';

/// Helper dialog that contains various help options
class HelperDialog extends StatelessWidget {
  const HelperDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await showStandardDialog(
      context: context,
      title: l10n.helper,
      icon: Icons.help_outline,
      customContent: const HelperDialog(),
      secondaryButtonText: l10n.close,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TTS Help
            _HelperItem(
              icon: Icons.record_voice_over,
              title: l10n.ttsSettings,
              subtitle: l10n.ttsHelp,
              onTap: () {
                Navigator.pop(context);
                TtsHelpDialog.show(context);
              },
            ),

            // Reset TTS Warning (only on Windows/Linux)
            if (!kIsWeb && (Platform.isWindows || Platform.isLinux))
              _HelperItem(
                icon: Icons.refresh,
                title: l10n.resetTtsWarning,
                subtitle: l10n.resetTtsWarningDesc,
                onTap: () async {
                  final prefs = AppPreferences();
                  await prefs.init();
                  await prefs.setHideTtsWarning(false);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.ttsWarningReset)),
                    );
                  }
                },
              ),

            const Divider(height: 24),

            // Future helpers can be added here
            // Example placeholder:
            // _HelperItem(
            //   icon: Icons.keyboard,
            //   title: 'Keyboard Shortcuts',
            //   subtitle: 'View all keyboard shortcuts',
            //   onTap: () {},
            // ),
          ],
        ),
    );
  }
}

class _HelperItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelperItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondaryLight,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
