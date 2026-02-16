import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/dialogs/helper_dialog.dart';
import '../../widgets/dialogs/update_dialog.dart';
import '../../widgets/dialogs/profile_edit_dialog.dart';
import '../../widgets/dialogs/feedback_dialog.dart';
import '../../providers/admin_feedback_provider.dart';
import 'backup_screen.dart';

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
      body: Consumer3<SettingsProvider, AuthProvider, UpdateProvider>(
        builder: (context, settings, auth, updateProvider, child) {
          // Always init to load version info (idempotent)
          updateProvider.init(settings.preferences);
          return ListView(
            children: [
              // Account & Profile section
              _SectionHeader(title: l10n.account),
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  final profile = profileProvider.profile;

                  if (auth.isAuthenticated) {
                    return Column(
                      children: [
                        // Sign out
                        ListTile(
                          leading: const Icon(Icons.logout, color: AppColors.error),
                          title: Text(
                            l10n.signOut,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          subtitle: Text(l10n.signedInAs(auth.email ?? '')),
                          onTap: () => _confirmSignOut(context, auth, l10n),
                        ),
                        // Profile card
                        ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: profile.hasCustomAvatar
                                  ? Image.file(
                                      File(profile.customAvatarUrl!),
                                      fit: BoxFit.cover,
                                      width: 48,
                                      height: 48,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          profile.avatarEmoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        profile.avatarEmoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(
                            profile.getDisplayName(auth.displayName ?? auth.email),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (profile.bio != null && profile.bio!.isNotEmpty)
                                Text(
                                  profile.bio!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => ProfileEditDialog.show(context),
                        ),
                      ],
                    );
                  } else {
                    return ListTile(
                      leading: const Icon(Icons.login),
                      title: Text(l10n.signInGoogle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await auth.signInWithGoogle();
                      },
                    );
                  }
                },
              ),

              // Admin section (only for admin user)
              if (auth.isAdmin) ...[
                const Divider(),
                _SectionHeader(title: l10n.adminSection),
                Consumer<AdminFeedbackProvider>(
                  builder: (context, adminProvider, _) {
                    return ListTile(
                      leading: const Icon(Icons.feedback),
                      title: Text(l10n.adminFeedback),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (adminProvider.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.nNewFeedback(adminProvider.unreadCount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/admin-feedback'),
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
                leading: const Icon(Icons.cloud),
                title: Text(l10n.googleDriveBackup),
                subtitle: Text(l10n.saveDataToCloud),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  );
                },
              ),

              const Divider(),

              // About section
              _SectionHeader(title: l10n.about),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(l10n.version),
                subtitle: Text(updateProvider.currentVersion),
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: Text(l10n.sendFeedback),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  FeedbackDialog.show(context);
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

              // Support / Donate section
              _SectionHeader(title: l10n.support),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.pink),
                title: Text(l10n.donate),
                subtitle: Text(l10n.donateDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDonateDialog(context, l10n),
              ),

              // Updates section
              if (!kIsWeb) ...[
                const Divider(),
                _SectionHeader(title: l10n.updates),
                if (updateProvider.isAutoUpdateSupported)
                  SwitchListTile(
                    title: Text(l10n.autoCheckUpdates),
                    subtitle: Text(l10n.autoCheckUpdatesDesc),
                    value: updateProvider.autoCheckUpdates,
                    onChanged: (value) => updateProvider.setAutoCheckUpdates(value),
                    secondary: const Icon(Icons.update),
                  ),
                ListTile(
                  leading: updateProvider.isChecking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  title: Text(l10n.checkForUpdates),
                  subtitle: Text(
                    updateProvider.hasUpdate
                        ? l10n.updateAvailableVersion(
                            updateProvider.availableUpdate!.version)
                        : l10n.checkingForUpdates,
                  ),
                  trailing: updateProvider.hasUpdate
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.newLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    if (updateProvider.hasUpdate) {
                      if (updateProvider.isAutoUpdateSupported) {
                        UpdateDialog.show(
                          context,
                          version: updateProvider.availableUpdate!,
                          isMandatory: updateProvider.availableUpdate!.isMandatory,
                        );
                      } else {
                        await updateProvider.openReleasesPage();
                      }
                    } else {
                      await updateProvider.checkForUpdates();
                      if (context.mounted) {
                        if (updateProvider.hasUpdate) {
                          if (updateProvider.isAutoUpdateSupported) {
                            UpdateDialog.show(
                              context,
                              version: updateProvider.availableUpdate!,
                              isMandatory:
                                  updateProvider.availableUpdate!.isMandatory,
                            );
                          } else {
                            await updateProvider.openReleasesPage();
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.noUpdatesAvailable)),
                          );
                        }
                      }
                    }
                  },
                ),
              ],

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

  void _showDonateDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.pink),
            const SizedBox(width: 8),
            Text(l10n.donate),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.donateMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://img.vietqr.io/image/VCB-0071000718658-compact.png',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 250,
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 250,
                      height: 250,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Could not load QR code'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.donateBank,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _saveQrImage(context, l10n),
            icon: const Icon(Icons.download),
            label: Text(l10n.saveQrImage),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQrImage(BuildContext context, AppLocalizations l10n) async {
    try {
      final response = await http.get(
        Uri.parse('https://img.vietqr.io/image/VCB-0071000718658-compact.png'),
      );
      if (response.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.qrSaveFailed)),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/vocabflip_donate_qr.png');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.donate,
      );
    } catch (e) {
      debugPrint('Save QR failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.qrSaveFailed)),
        );
      }
    }
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
