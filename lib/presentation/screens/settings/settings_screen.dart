import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dialogs/helper_dialog.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.helper,
            onPressed: () => HelperDialog.show(context),
          ),
        ],
      ),
      body: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, child) {
          return ListView(
            children: [
              // Account section
              _SectionHeader(title: l10n.account),
              if (auth.isAuthenticated) ...[
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (auth.email?.isNotEmpty == true)
                          ? auth.email![0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(auth.displayName ?? auth.email ?? 'User'),
                  subtitle: auth.displayName != null ? Text(auth.email ?? '') : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAccountDialog(context, auth, l10n),
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.login),
                  title: Text(l10n.signIn),
                  subtitle: Text(l10n.signInWithEmail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ],

              const Divider(),

              // Appearance section
              _SectionHeader(title: l10n.appearance),
              SwitchListTile(
                title: Text(l10n.darkMode),
                subtitle: Text(l10n.useDarkTheme),
                value: settings.isDarkMode,
                onChanged: (value) => settings.setDarkMode(value),
                secondary: const Icon(Icons.dark_mode),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(settings.locale == 'vi' ? 'Tiếng Việt' : 'English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, settings),
              ),

              const Divider(),

              // Study settings
              _SectionHeader(title: l10n.studySettings),
              ListTile(
                leading: const Icon(Icons.fiber_new),
                title: Text(l10n.newCardsPerDay),
                subtitle: Text(l10n.nCards(settings.newCardsPerDay)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showNumberPicker(
                  context,
                  l10n.newCardsPerDay,
                  settings.newCardsPerDay,
                  (value) => settings.setNewCardsPerDay(value),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.replay),
                title: Text(l10n.reviewCardsPerDay),
                subtitle: Text(l10n.nCards(settings.reviewCardsPerDay)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showNumberPicker(
                  context,
                  l10n.reviewCardsPerDay,
                  settings.reviewCardsPerDay,
                  (value) => settings.setReviewCardsPerDay(value),
                ),
              ),
              SwitchListTile(
                title: Text(l10n.showPhonetic),
                subtitle: Text(l10n.displayPronunciation),
                value: settings.showPhonetic,
                onChanged: (value) => settings.setShowPhonetic(value),
                secondary: const Icon(Icons.record_voice_over),
              ),
              SwitchListTile(
                title: Text(l10n.autoPlayAudio),
                subtitle: Text(l10n.automaticallyPlayPronunciation),
                value: settings.autoPlayAudio,
                onChanged: (value) => settings.setAutoPlayAudio(value),
                secondary: const Icon(Icons.volume_up),
              ),
              ListTile(
                leading: const Icon(Icons.photo_size_select_large),
                title: Text(l10n.flashcardImageSize),
                subtitle: Text('${settings.flashcardImageMaxWidth}px'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showImageSizePicker(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text(l10n.flashcardFontSize),
                subtitle: Text(l10n.fontSizePixels(settings.flashcardMainFontSize)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFontSizePicker(context, settings, l10n),
              ),

              const Divider(),

              // Backup section
              _SectionHeader(title: l10n.backupSync),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: Text(l10n.backupToCloud),
                subtitle: Text(l10n.saveDataToCloud),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement backup
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.firebaseNotConfigured)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: Text(l10n.restoreFromCloud),
                subtitle: Text(l10n.restoreDataFromCloud),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement restore
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.firebaseNotConfigured)),
                  );
                },
              ),
              SwitchListTile(
                title: Text(l10n.autoSync),
                subtitle: Text(l10n.autoSyncWhenOnline),
                value: settings.autoSync,
                onChanged: (value) => settings.setAutoSync(value),
                secondary: const Icon(Icons.sync),
              ),

              const Divider(),

              // Import/Export section
              _SectionHeader(title: l10n.importExport),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: Text(l10n.importDeck),
                subtitle: Text(l10n.importFromJson),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement import
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: Text(l10n.exportAllDecks),
                subtitle: Text(l10n.exportToJson),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement export
                },
              ),

              const Divider(),

              // About section
              _SectionHeader(title: l10n.about),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(l10n.version),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: Text(l10n.sendFeedback),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement feedback
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: Text(l10n.rateApp),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement rate app
                },
              ),

              const Divider(),

              // Danger zone
              _SectionHeader(title: l10n.dangerZone, color: AppColors.error),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
                title: Text(
                  l10n.resetAllData,
                  style: const TextStyle(color: AppColors.error),
                ),
                subtitle: Text(l10n.deleteAllData),
                onTap: () => _confirmReset(context),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'vi',
              groupValue: settings.locale,
              onChanged: (value) {
                settings.setLocale(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: settings.locale,
              onChanged: (value) {
                settings.setLocale(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSizePicker(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final sizes = [400, 600, 800, 1000, 1200, 1500];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.flashcardImageSize),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizes.map((size) {
            return RadioListTile<int>(
              title: Text('${size}px'),
              subtitle: Text(size <= 600 ? l10n.recommendedForMobile :
                           size >= 1000 ? l10n.recommendedForDesktop : l10n.balanced),
              value: size,
              groupValue: settings.flashcardImageMaxWidth,
              onChanged: (value) {
                if (value != null) {
                  settings.setFlashcardImageMaxWidth(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFontSizePicker(BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.flashcardFontSize),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main text size
                Text(l10n.mainTextSize, style: const TextStyle(fontWeight: FontWeight.bold)),
                _FontSizeSlider(
                  value: settings.flashcardMainFontSize,
                  min: 20,
                  max: 48,
                  onChanged: (value) {
                    settings.setFlashcardMainFontSize(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Phonetic text size
                Text(l10n.phoneticTextSize, style: const TextStyle(fontWeight: FontWeight.bold)),
                _FontSizeSlider(
                  value: settings.flashcardPhoneticFontSize,
                  min: 14,
                  max: 32,
                  onChanged: (value) {
                    settings.setFlashcardPhoneticFontSize(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Detail text size (example/note)
                Text(l10n.detailTextSize, style: const TextStyle(fontWeight: FontWeight.bold)),
                _FontSizeSlider(
                  value: settings.flashcardDetailFontSize,
                  min: 12,
                  max: 24,
                  onChanged: (value) {
                    settings.setFlashcardDetailFontSize(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
  }

  void _showNumberPicker(
    BuildContext context,
    String title,
    int currentValue,
    Function(int) onChanged,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.numberOfCards,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                onChanged(value);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showAccountDialog(BuildContext context, AuthProvider auth, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.account),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 24,
                child: Text(
                  (auth.email?.isNotEmpty == true)
                      ? auth.email![0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              title: Text(auth.displayName ?? 'User'),
              subtitle: Text(auth.email ?? ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _confirmSignOut(context, auth, l10n);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetConfirmTitle),
        content: Text(l10n.resetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement reset
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.dataReset)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color ?? AppColors.textSecondaryLight,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _FontSizeSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _FontSizeSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 45,
          child: Text(
            '${value}px',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ),
      ],
    );
  }
}
