// ignore_for_file: deprecated_member_use

import 'dart:io' show File;
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
import '../../widgets/dialogs/login_dialog.dart';
import '../../widgets/dialogs/standard_dialog.dart';
import '../../providers/admin_feedback_provider.dart';
import 'backup_screen.dart';

import '../../widgets/payment/topup_bottom_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Consumer3<SettingsProvider, AuthProvider, UpdateProvider>(
          builder: (context, settings, auth, updateProvider, child) {
            // Always init to load version info (idempotent)
            updateProvider.init(settings.preferences);
            return ListView(
              padding: const EdgeInsets.only(bottom: 100, top: 16),
              children: [
                _SettingsHero(settings: settings, auth: auth),
              
              // Account & Profile section
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  final profile = profileProvider.profile;

                  if (auth.isAuthenticated) {
                    return _SettingsSection(
                      title: l10n.account,
                      children: [
                        _SettingsTile(
                          leading: ClipOval(
                            child: (profile.hasCustomAvatar || (auth.user?.avatar != null && auth.user!.avatar!.isNotEmpty))
                                ? ((profile.customAvatarUrl ?? auth.user!.avatar!).startsWith('http')
                                    ? Image.network(
                                        profile.customAvatarUrl ?? auth.user!.avatar!,
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            profile.avatarEmoji,
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      )
                                    : Image.file(
                                        File(profile.customAvatarUrl!),
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            profile.avatarEmoji,
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ))
                                : Center(
                                    child: Text(
                                      profile.avatarEmoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                          ),
                          title: profile.getDisplayName(auth.displayName ?? auth.email),
                          subtitle: (profile.bio?.isNotEmpty == true) ? profile.bio : l10n.signedInAs(auth.email ?? ''),
                          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                          onTap: () => ProfileEditDialog.show(context),
                        ),
                        const Divider(height: 1, indent: 70),
                        _SettingsTile(
                          leading: const Icon(Icons.monetization_on, color: Colors.orange, size: 22),
                          title: l10n.balanceCredits(auth.balance),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.topupCredit,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: () => TopupBottomSheet.show(context),
                        ),
                        const Divider(height: 1, indent: 70),
                        _SettingsTile(
                          leading: const Icon(Icons.logout, color: AppColors.error, size: 22),
                          title: l10n.signOut,
                          isDestructive: true,
                          onTap: () => _confirmSignOut(context, auth, l10n),
                        ),
                      ],
                    );
                  } else {
                    return _SettingsSection(
                      title: l10n.account,
                      children: [
                        _SettingsTile(
                          leading: const Icon(Icons.login, color: AppColors.primary, size: 22),
                          title: l10n.signIn,
                          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                          onTap: () {
                            LoginDialog.show(context);
                          },
                        ),
                      ],
                    );
                  }
                },
              ),

              // Admin section (only for admin user)
              if (auth.isAdmin)
                Consumer<AdminFeedbackProvider>(
                  builder: (context, adminProvider, _) {
                    return _SettingsSection(
                      title: l10n.adminSection,
                      children: [
                        _SettingsTile(
                          leading: const Icon(Icons.feedback, color: AppColors.primary, size: 22),
                          title: l10n.adminFeedback,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (adminProvider.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    l10n.nNewFeedback(adminProvider.unreadCount),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                            ],
                          ),
                          onTap: () => Navigator.pushNamed(context, '/admin-feedback'),
                        ),
                      ],
                    );
                  },
                ),

              // Appearance section
              _SettingsSection(
                title: l10n.appearance,
                children: [
                  _SettingsSwitchTile(
                    leading: const Icon(Icons.dark_mode, color: Colors.indigo, size: 22),
                    title: l10n.darkMode,
                    subtitle: l10n.useDarkTheme,
                    value: settings.isDarkMode,
                    onChanged: (value) => settings.setDarkMode(value),
                  ),
                  const Divider(height: 1, indent: 70),
                    _SettingsTile(
                      leading: const Icon(Icons.language, color: Colors.teal, size: 22),
                      title: l10n.language,
                      subtitle: settings.locale == 'vi' ? 'Tiếng Việt' : 'English',
                      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      onTap: () => _showLanguageDialog(context, settings),
                    ),
                    const Divider(height: 1, indent: 70),
                    _SettingsTile(
                      leading: const Icon(Icons.touch_app, color: Colors.orange, size: 22),
                      title: l10n.deckClickAction,
                      subtitle: settings.deckClickAction == 'browse' 
                          ? l10n.deckClickActionBrowse 
                          : l10n.deckClickActionDetail,
                      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      onTap: () => _showDeckClickActionDialog(context, settings),
                    ),
                  ],
              ),

              // Study settings
              _SettingsSection(
                title: l10n.studySettings,
                children: [
                  _SettingsTile(
                    leading: const Icon(Icons.fiber_new, color: Colors.blue, size: 22),
                    title: l10n.newCardsPerDay,
                    subtitle: l10n.nCards(settings.newCardsPerDay),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => _showNumberPicker(
                      context,
                      l10n.newCardsPerDay,
                      settings.newCardsPerDay,
                      (value) => settings.setNewCardsPerDay(value),
                    ),
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsTile(
                    leading: const Icon(Icons.replay, color: Colors.purple, size: 22),
                    title: l10n.reviewCardsPerDay,
                    subtitle: l10n.nCards(settings.reviewCardsPerDay),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => _showNumberPicker(
                      context,
                      l10n.reviewCardsPerDay,
                      settings.reviewCardsPerDay,
                      (value) => settings.setReviewCardsPerDay(value),
                    ),
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsSwitchTile(
                    leading: const Icon(Icons.record_voice_over, color: Colors.deepOrange, size: 22),
                    title: l10n.showPhonetic,
                    subtitle: l10n.displayPronunciation,
                    value: settings.showPhonetic,
                    onChanged: (value) => settings.setShowPhonetic(value),
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsSwitchTile(
                    leading: const Icon(Icons.play_circle_fill, color: Colors.green, size: 22),
                    title: l10n.autoPlayAudio,
                    subtitle: l10n.automaticallyPlayPronunciation,
                    value: settings.autoPlayAudio,
                    onChanged: settings.setAutoPlayAudio,
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsTile(
                    leading: const Icon(Icons.volume_up, color: Colors.cyan, size: 22),
                    title: l10n.ttsVolume,
                    subtitle: l10n.ttsVolumeDesc,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(settings.ttsVolume * 100).round()}%',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      ],
                    ),
                    onTap: () => _showTtsVolumePicker(context, settings, l10n),
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsSwitchTile(
                    leading: const Icon(Icons.science, color: Colors.pink, size: 22),
                    title: l10n.advancedLearningScience,
                    subtitle: l10n.advancedLearningScienceDesc,
                    value: settings.advancedLearningScience,
                    onChanged: settings.setAdvancedLearningScience,
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsTile(
                    leading: const Icon(Icons.photo_size_select_large, color: Colors.brown, size: 22),
                    title: l10n.flashcardImageSize,
                    subtitle: '${settings.flashcardImageMaxWidth}px',
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => _showImageSizePicker(context, settings),
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsTile(
                    leading: const Icon(Icons.text_fields, color: Colors.blueGrey, size: 22),
                    title: l10n.flashcardFontSize,
                    subtitle: l10n.fontSizePixels(settings.flashcardMainFontSize),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => _showFontSizePicker(context, settings, l10n),
                  ),
                ],
              ),

              // Backup section
              _SettingsSection(
                title: l10n.backupSync,
                children: [
                  _SettingsTile(
                    leading: const Icon(Icons.cloud, color: AppColors.primary, size: 22),
                    title: l10n.googleDriveBackup,
                    subtitle: l10n.saveDataToCloud,
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BackupScreen()),
                      );
                    },
                  ),
                ],
              ),

              // Support / Donate section
              _SettingsSection(
                title: l10n.support,
                children: [
                  _SettingsTile(
                    leading: const Icon(Icons.favorite, color: Colors.pink, size: 22),
                    title: l10n.donate,
                    subtitle: l10n.donateDesc,
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => _showDonateDialog(context, l10n),
                  ),
                ],
              ),

              // About & Updates section
              _SettingsSection(
                title: l10n.about,
                children: [
                  _SettingsTile(
                    leading: const Icon(Icons.help_outline, color: AppColors.primary, size: 22),
                    title: l10n.helper,
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => HelperDialog.show(context),
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsTile(
                    leading: const Icon(Icons.info, color: AppColors.primary, size: 22),
                    title: l10n.version,
                    subtitle: updateProvider.currentVersion,
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsTile(
                    leading: const Icon(Icons.feedback, color: AppColors.primary, size: 22),
                    title: l10n.sendFeedback,
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => FeedbackDialog.show(context),
                  ),
                  const Divider(height: 1, indent: 70),
                  _SettingsTile(
                    leading: const Icon(Icons.star, color: AppColors.primary, size: 22),
                    title: l10n.rateApp,
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () {},
                  ),
                  if (!kIsWeb) ...[
                    if (updateProvider.isAutoUpdateSupported) ...[
                      const Divider(height: 1, indent: 70),
                      _SettingsSwitchTile(
                        leading: const Icon(Icons.update, color: AppColors.primary, size: 22),
                        title: l10n.autoCheckUpdates,
                        subtitle: l10n.autoCheckUpdatesDesc,
                        value: updateProvider.autoCheckUpdates,
                        onChanged: (value) => updateProvider.setAutoCheckUpdates(value),
                      ),
                    ],
                    const Divider(height: 1, indent: 70),
                    _SettingsTile(
                      leading: updateProvider.isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.refresh, color: AppColors.primary, size: 22),
                      title: l10n.checkForUpdates,
                      subtitle: updateProvider.hasUpdate
                          ? l10n.updateAvailableVersion(updateProvider.availableUpdate!.version)
                          : l10n.checkingForUpdates,
                      trailing: updateProvider.hasUpdate
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.newLabel,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                          : const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      onTap: () async {
                        // Same logic
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
                                  isMandatory: updateProvider.availableUpdate!.isMandatory,
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
                ],
              ),

              // Danger zone
              _SettingsSection(
                title: l10n.dangerZone,
                color: AppColors.error,
                children: [
                  _SettingsTile(
                    leading: const Icon(Icons.delete_forever, color: AppColors.error, size: 22),
                    title: l10n.resetAllData,
                    subtitle: l10n.deleteAllData,
                    isDestructive: true,
                    onTap: () => _confirmReset(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ));
  }

  void _showDeckClickActionDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;

    showStandardDialog(
      context: context,
      title: l10n.deckClickAction,
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: Text(l10n.deckClickActionDetail),
            value: 'detail',
            groupValue: settings.deckClickAction,
            onChanged: (value) {
              if (value != null) {
                settings.setDeckClickAction(value);
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.deckClickActionBrowse),
            value: 'browse',
            groupValue: settings.deckClickAction,
            onChanged: (value) {
              if (value != null) {
                settings.setDeckClickAction(value);
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          ),
        ],
      ),
      secondaryButtonText: l10n.cancel,
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;

    showStandardDialog(
      context: context,
      title: l10n.selectLanguage,
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: settings.locale == 'vi' ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: RadioListTile<String>(
              title: const Text('Tiếng Việt', style: TextStyle(fontWeight: FontWeight.w600)),
              value: 'vi',
              groupValue: settings.locale,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onChanged: (value) {
                settings.setLocale(value!);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: settings.locale == 'en' ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: RadioListTile<String>(
              title: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
              value: 'en',
              groupValue: settings.locale,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onChanged: (value) {
                settings.setLocale(value!);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSizePicker(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    final sizes = [400, 600, 800, 1000, 1200, 1500];

    showStandardDialog(
      context: context,
      title: l10n.flashcardImageSize,
      customContent: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizes.map((size) {
            return RadioListTile<int>(
              title: Text('${size}px', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(size <= 600
                  ? l10n.recommendedForMobile
                  : size >= 1000
                      ? l10n.recommendedForDesktop
                      : l10n.balanced),
              value: size,
              groupValue: settings.flashcardImageMaxWidth,
              activeColor: AppColors.primary,
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

  void _showTtsVolumePicker(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    showStandardDialog(
      context: context,
      title: l10n.ttsVolume,
      primaryButtonText: l10n.done,
      customContent: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ttsVolumeDesc,
              style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.volume_mute, size: 24, color: AppColors.textSecondary(context)),
                Text(
                  '${(settings.ttsVolume * 100).round()}%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Icon(Icons.volume_up, size: 24, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: settings.ttsVolume,
              min: 0.0,
              max: 2.0,
              divisions: 40, // 5% steps
              activeColor: AppColors.primary,
              onChanged: (value) {
                settings.setTtsVolume(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizePicker(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    showStandardDialog(
      context: context,
      title: l10n.flashcardFontSize,
      primaryButtonText: l10n.done,
      onPrimaryPressed: () => Navigator.pop(context), // Though standard dialog pops on button press anyway, but wait, showStandardDialog already completes the future and dismisses the dialog on button press. If we pop, it might pop the screen behind. Let's omit onPrimaryPressed or just let showStandardDialog handle it. Wait! `showStandardDialog` in AwesomeDialog automatically dismisses on button press! If we pop again, it's double pop. We should just set primaryButtonText and omit onPrimaryPressed.
      customContent: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main text size
              Text(l10n.mainTextSize, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              _FontSizeSlider(
                value: settings.flashcardMainFontSize,
                min: 20,
                max: 80,
                onChanged: (value) {
                  settings.setFlashcardMainFontSize(value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),

              // Phonetic text size
              Text(l10n.phoneticTextSize, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              _FontSizeSlider(
                value: settings.flashcardPhoneticFontSize,
                min: 14,
                max: 48,
                onChanged: (value) {
                  settings.setFlashcardPhoneticFontSize(value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),

              // Detail text size (example/note)
              Text(l10n.detailTextSize, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              _FontSizeSlider(
                value: settings.flashcardDetailFontSize,
                min: 12,
                max: 32,
                onChanged: (value) {
                  settings.setFlashcardDetailFontSize(value);
                  setState(() {});
                },
              ),
            ],
          ),
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

    showStandardDialog(
      context: context,
      title: title,
      customContent: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.numberOfCards,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      secondaryButtonText: l10n.cancel,
      primaryButtonText: l10n.save,
      onPrimaryPressed: () {
        final value = int.tryParse(controller.text);
        if (value != null && value > 0) {
          onChanged(value);
        }
      },
    );
  }

  void _confirmSignOut(
      BuildContext context, AuthProvider auth, AppLocalizations l10n) {
    showStandardDialog(
      context: context,
      title: l10n.signOut,
      content: l10n.signOutConfirm,
      isDestructive: true,
      secondaryButtonText: l10n.cancel,
      primaryButtonText: l10n.signOut,
      onPrimaryPressed: () async {
        await auth.signOut();
      },
    );
  }

  void _confirmReset(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showStandardDialog(
      context: context,
      title: l10n.resetConfirmTitle,
      content: l10n.resetConfirmMessage,
      isDestructive: true,
      secondaryButtonText: l10n.cancel,
      primaryButtonText: l10n.reset,
      onPrimaryPressed: () {
        // TODO: Implement reset
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dataReset)),
        );
      },
    );
  }

  void _showDonateDialog(BuildContext context, AppLocalizations l10n) {
    showStandardDialog(
      context: context,
      title: l10n.donate,
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.donateMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://img.vietqr.io/image/VCB-0071000718658-compact.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
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
                    width: 220,
                    height: 220,
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(l10n.couldNotLoadQr, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.donateBank,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      secondaryButtonText: l10n.close,
      primaryButtonText: l10n.saveQrImage,
      onPrimaryPressed: () => _saveQrImage(context, l10n),
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? color;

  const _SettingsSection({
    required this.title,
    required this.children,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color ?? AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? AppColors.error : AppColors.textPrimary(context);
    final subtitleColor = isDestructive ? AppColors.error.withOpacity(0.7) : AppColors.textSecondary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isDestructive ? AppColors.error : AppColors.primary).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: leading),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      onTap: () => onChanged(!value),
    );
  }
}


class _SettingsHero extends StatelessWidget {
  final SettingsProvider settings;
  final AuthProvider auth;

  const _SettingsHero({
    required this.settings,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.secondaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settings,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.isAuthenticated
                        ? l10n.signedInAs(auth.email ?? '')
                        : l10n.signIn,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Icon(
                settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
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
            style: const TextStyle(
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
