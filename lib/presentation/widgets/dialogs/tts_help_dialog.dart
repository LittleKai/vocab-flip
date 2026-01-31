import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/services/tts_service.dart';
import '../../../data/local/preferences/app_preferences.dart';

/// Shows TTS installation help dialog
class TtsHelpDialog extends StatelessWidget {
  final List<SupportedLanguage> missingLanguages;
  final bool showDontShowAgain;
  final VoidCallback? onDontShowAgainChanged;

  const TtsHelpDialog({
    super.key,
    this.missingLanguages = const [],
    this.showDontShowAgain = false,
    this.onDontShowAgainChanged,
  });

  static Future<void> show(
    BuildContext context, {
    List<SupportedLanguage> missingLanguages = const [],
    bool showDontShowAgain = false,
  }) async {
    bool dontShowAgain = false;

    await showDialog(
      context: context,
      builder: (context) => _TtsHelpDialogContent(
        missingLanguages: missingLanguages,
        showDontShowAgain: showDontShowAgain,
        onDontShowAgainChanged: (value) => dontShowAgain = value,
      ),
    );

    if (dontShowAgain) {
      await AppPreferences().setHideTtsWarning(true);
    }
  }

  /// Check and show warning if needed for a specific language
  static Future<void> checkAndShowWarningForLanguage(
    BuildContext context,
    TtsService ttsService,
    SupportedLanguage language,
  ) async {
    debugPrint('TTS Dialog: checking for language ${language.code}');

    // Only show on Windows/desktop
    if (kIsWeb) {
      debugPrint('TTS Dialog: skipping - web platform');
      return;
    }
    if (!Platform.isWindows && !Platform.isLinux) {
      debugPrint('TTS Dialog: skipping - not Windows/Linux');
      return;
    }

    // Initialize preferences
    final prefs = AppPreferences();
    await prefs.init();

    final hideWarning = prefs.hideTtsWarning;
    debugPrint('TTS Dialog: hideTtsWarning=$hideWarning');
    if (hideWarning) return;

    // Initialize TTS and check language
    if (!ttsService.isInitialized) {
      debugPrint('TTS Dialog: initializing TTS...');
      await ttsService.init();
    }

    // Check if this specific language is supported
    final isSupported = ttsService.isLanguageSupported(language);
    debugPrint('TTS Dialog: language ${language.code} supported=$isSupported');

    if (isSupported) return;

    debugPrint('TTS Dialog: showing warning dialog');
    if (context.mounted) {
      await show(
        context,
        missingLanguages: [language],
        showDontShowAgain: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TtsHelpDialogContent(
      missingLanguages: missingLanguages,
      showDontShowAgain: showDontShowAgain,
      onDontShowAgainChanged: (_) => onDontShowAgainChanged?.call(),
    );
  }
}

class _TtsHelpDialogContent extends StatefulWidget {
  final List<SupportedLanguage> missingLanguages;
  final bool showDontShowAgain;
  final ValueChanged<bool>? onDontShowAgainChanged;

  const _TtsHelpDialogContent({
    required this.missingLanguages,
    required this.showDontShowAgain,
    this.onDontShowAgainChanged,
  });

  @override
  State<_TtsHelpDialogContent> createState() => _TtsHelpDialogContentState();
}

class _TtsHelpDialogContentState extends State<_TtsHelpDialogContent> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWarning = widget.missingLanguages.isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.help_outline,
            color: isWarning ? AppColors.warning : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isWarning ? l10n.ttsLanguagesMissing : l10n.ttsHelp,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWarning) ...[
              Text(
                l10n.ttsLanguagesMissingDesc,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...widget.missingLanguages.map((lang) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(lang.nameEn),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],

            Text(
              l10n.ttsInstallInstructions,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            if (!kIsWeb && Platform.isWindows) ...[
              _buildStep('1', l10n.ttsStepOpenSettings),
              _buildStep('2', l10n.ttsStepTimeLanguage),
              _buildStep('3', l10n.ttsStepAddLanguage),
              _buildStep('4', l10n.ttsStepSelectLanguage),
              _buildStep('5', l10n.ttsStepDownloadSpeech),
              _buildStep('6', l10n.ttsStepRestartApp),
            ] else ...[
              Text(l10n.ttsGenericInstructions),
            ],

            if (widget.showDontShowAgain) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _dontShowAgain,
                onChanged: (value) {
                  setState(() => _dontShowAgain = value ?? false);
                  widget.onDontShowAgainChanged?.call(_dontShowAgain);
                },
                title: Text(l10n.dontShowAgain),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.done),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
