import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/supported_languages.dart';
import '../../../data/services/tts_service.dart';
import '../common/selectable_radio_tile.dart';
import 'standard_dialog.dart';

/// Shows a dialog letting the user pick which installed voice reads each
/// supported language, with a shortcut to the OS voice-download settings.
class TtsVoicePickerDialog {
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showStandardDialog(
      context: context,
      title: l10n.ttsVoice,
      primaryButtonText: l10n.done,
      customContent: const _TtsVoicePickerContent(),
    );
  }
}

class _TtsVoicePickerContent extends StatefulWidget {
  const _TtsVoicePickerContent();

  @override
  State<_TtsVoicePickerContent> createState() =>
      _TtsVoicePickerContentState();
}

class _TtsVoicePickerContentState extends State<_TtsVoicePickerContent> {
  final TtsService _ttsService = TtsService();
  bool _loading = true;

  bool get _canOpenSystemSettings =>
      !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _ttsService.init();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openSystemVoiceSettings() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(action: 'android.settings.TTS_SETTINGS');
        await intent.launch();
      } else if (Platform.isWindows) {
        await launchUrl(Uri.parse('ms-settings:speech'));
      }
    } catch (_) {
      // No system voice settings screen available on this device; ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final localeCode = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ttsVoiceDesc,
            style: TextStyle(
                color: AppColors.textSecondary(context), fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final lang in SupportedLanguage.values) ...[
            _buildLanguageSection(context, lang, l10n, localeCode),
            const SizedBox(height: 12),
          ],
          if (_canOpenSystemSettings)
            OutlinedButton.icon(
              onPressed: _openSystemVoiceSettings,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(l10n.ttsVoiceAddMore),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(
    BuildContext context,
    SupportedLanguage lang,
    AppLocalizations l10n,
    String localeCode,
  ) {
    final voices = _ttsService.getVoicesForLanguage(lang);
    final selected = _ttsService.getSelectedVoice(lang);
    final selectedKey =
        selected == null ? null : '${selected['name']}::${selected['locale']}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              lang.getName(localeCode),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        if (voices.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 4, bottom: 4),
            child: Text(
              l10n.ttsVoiceNoneAvailable,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 13),
            ),
          )
        else
          ...voices.map((voice) {
            final key = '${voice['name']}::${voice['locale']}';
            return SelectableRadioTile(
              title: voice['name'] ?? '',
              subtitle: voice['locale'],
              selected: key == selectedKey,
              onTap: () async {
                await _ttsService.setPreferredVoice(lang, voice);
                if (mounted) setState(() {});
              },
            );
          }),
      ],
    );
  }
}
