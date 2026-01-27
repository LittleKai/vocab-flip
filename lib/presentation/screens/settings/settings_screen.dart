import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              // Appearance section
              _SectionHeader(title: 'Appearance'),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: settings.isDarkMode,
                onChanged: (value) => settings.setDarkMode(value),
                secondary: const Icon(Icons.dark_mode),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(settings.locale == 'vi' ? 'Tiếng Việt' : 'English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, settings),
              ),

              const Divider(),

              // Study settings
              _SectionHeader(title: 'Study'),
              ListTile(
                leading: const Icon(Icons.fiber_new),
                title: const Text('New cards per day'),
                subtitle: Text('${settings.newCardsPerDay} cards'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showNumberPicker(
                  context,
                  'New cards per day',
                  settings.newCardsPerDay,
                  (value) => settings.setNewCardsPerDay(value),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.replay),
                title: const Text('Review cards per day'),
                subtitle: Text('${settings.reviewCardsPerDay} cards'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showNumberPicker(
                  context,
                  'Review cards per day',
                  settings.reviewCardsPerDay,
                  (value) => settings.setReviewCardsPerDay(value),
                ),
              ),
              SwitchListTile(
                title: const Text('Show phonetic'),
                subtitle: const Text('Display pronunciation on cards'),
                value: settings.showPhonetic,
                onChanged: (value) => settings.setShowPhonetic(value),
                secondary: const Icon(Icons.record_voice_over),
              ),
              SwitchListTile(
                title: const Text('Auto-play audio'),
                subtitle: const Text('Automatically play pronunciation'),
                value: settings.autoPlayAudio,
                onChanged: (value) => settings.setAutoPlayAudio(value),
                secondary: const Icon(Icons.volume_up),
              ),

              const Divider(),

              // Backup section
              _SectionHeader(title: 'Backup & Sync'),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Backup to Cloud'),
                subtitle: const Text('Save your data to the cloud'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement backup
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Firebase not configured')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: const Text('Restore from Cloud'),
                subtitle: const Text('Restore your data from the cloud'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement restore
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Firebase not configured')),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Auto-sync'),
                subtitle: const Text('Automatically sync when online'),
                value: settings.autoSync,
                onChanged: (value) => settings.setAutoSync(value),
                secondary: const Icon(Icons.sync),
              ),

              const Divider(),

              // Import/Export section
              _SectionHeader(title: 'Import & Export'),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Import Deck'),
                subtitle: const Text('Import from JSON file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement import
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Export All Decks'),
                subtitle: const Text('Export to JSON file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement export
                },
              ),

              const Divider(),

              // About section
              _SectionHeader(title: 'About'),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text('Send Feedback'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement feedback
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Rate App'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement rate app
                },
              ),

              const Divider(),

              // Danger zone
              _SectionHeader(title: 'Danger Zone', color: AppColors.error),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
                title: const Text(
                  'Reset All Data',
                  style: TextStyle(color: AppColors.error),
                ),
                subtitle: const Text('Delete all decks and cards'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
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

  void _showNumberPicker(
    BuildContext context,
    String title,
    int currentValue,
    Function(int) onChanged,
  ) {
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of cards',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                onChanged(value);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your decks, flashcards, and study progress. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement reset
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data has been reset')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
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
