import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import 'standard_dialog.dart';

/// Dialog for editing user profile
class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({super.key});

  /// Show the profile edit dialog
  static Future<void> show(BuildContext context) {
    return showStandardDialog(
      context: context,
      title: AppLocalizations.of(context)!.editProfile,
      customContent: const ProfileEditDialog(),
    );
  }

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  late Gender _selectedGender;
  bool _isSaving = false;
  bool _isPickingImage = false;
  String? _nicknameError;
  bool _isCheckingNickname = false;
  Timer? _nicknameDebounce;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nicknameController = TextEditingController(text: profile.nickname ?? '');
    _bioController = TextEditingController(text: profile.bio ?? '');
    _selectedGender = profile.gender;
    _nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _nicknameDebounce?.cancel();
    _nicknameController.removeListener(_onNicknameChanged);
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onNicknameChanged() {
    _nicknameDebounce?.cancel();
    final value = _nicknameController.text.trim();
    final currentNickname = context.read<ProfileProvider>().profile.nickname;

    // Clear error if empty or same as current
    if (value.isEmpty || value == currentNickname) {
      setState(() {
        _nicknameError = null;
        _isCheckingNickname = false;
      });
      return;
    }

    setState(() => _isCheckingNickname = true);

    _nicknameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final provider = context.read<ProfileProvider>();
      final takenBy = await provider.checkNicknameAvailability(value);
      if (mounted && _nicknameController.text.trim() == value) {
        setState(() {
          _isCheckingNickname = false;
          _nicknameError = takenBy != null
              ? AppLocalizations.of(context)!.nicknameTaken
              : null;
        });
      }
    });
  }

  Future<void> _pickAvatarImage() async {
    setState(() => _isPickingImage = true);
    try {
      await context.read<ProfileProvider>().pickAvatarImage();
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    await context.read<ProfileProvider>().removeCustomAvatar();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      await context.read<ProfileProvider>().updateProfile(
        nickname: _nicknameController.text.trim(),
        gender: _selectedGender,
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar upload
              Text(
                l10n.selectAvatar,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildAvatarSection(),

              const SizedBox(height: 20),

              // Nickname
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: l10n.nickname,
                  hintText: l10n.enterNickname,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  errorText: _nicknameError,
                  suffixIcon: _isCheckingNickname
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _nicknameError == null &&
                              _nicknameController.text.trim().isNotEmpty &&
                              _nicknameController.text.trim() !=
                                  context.read<ProfileProvider>().profile.nickname
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                ),
                maxLength: 30,
              ),

              const SizedBox(height: 12),

              // Gender
              Text(
                l10n.gender,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildGenderSelection(isVi),

              const SizedBox(height: 16),

              // Bio
              TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: l10n.bio,
                  hintText: l10n.enterBio,
                  prefixIcon: const Icon(Icons.edit_note),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
                maxLength: 100,
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving || _nicknameError != null || _isCheckingNickname
                        ? null
                        : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Consumer2<ProfileProvider, AuthProvider>(
      builder: (context, provider, auth, _) {
        final authAvatar = auth.user?.avatar;
        final hasCustom = provider.hasCustomAvatar || (authAvatar != null && authAvatar.isNotEmpty);
        final avatarUrl = provider.customAvatarPath ?? authAvatar;
        final l10n = AppLocalizations.of(context)!;

        return Center(
          child: Column(
            children: [
              // Avatar preview
              GestureDetector(
                onTap: _isPickingImage ? null : _pickAvatarImage,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _isPickingImage
                            ? const Center(
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : hasCustom
                                ? (avatarUrl!.startsWith('http')
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        width: 96,
                                        height: 96,
                                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            provider.avatarEmoji,
                                            style: const TextStyle(fontSize: 40),
                                          ),
                                        ),
                                      )
                                    : Image.file(
                                        File(provider.customAvatarPath!),
                                        fit: BoxFit.cover,
                                        width: 96,
                                        height: 96,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            provider.avatarEmoji,
                                            style: const TextStyle(fontSize: 40),
                                          ),
                                        ),
                                      ))
                                : Center(
                                    child: Text(
                                      provider.avatarEmoji,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                      ),
                    ),
                    // Camera icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _isPickingImage ? null : _pickAvatarImage,
                    icon: const Icon(Icons.upload, size: 16),
                    label: Text(l10n.uploadImage),
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (hasCustom) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _removeAvatar,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(l10n.removeImage),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderSelection(bool isVi) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Gender.values.map((gender) {
        final isSelected = gender == _selectedGender;
        return ChoiceChip(
          label: Text(isVi ? gender.displayNameVi : gender.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedGender = gender);
            }
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
        );
      }).toList(),
    );
  }
}

/// Compact profile card widget for display in other screens
class ProfileCard extends StatelessWidget {
  final VoidCallback? onTap;

  const ProfileCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileProvider, AuthProvider>(
      builder: (context, profileProvider, authProvider, _) {
        final profile = profileProvider.profile;
        final authAvatar = authProvider.user?.avatar;
        final hasAvatar = profile.hasCustomAvatar || (authAvatar != null && authAvatar.isNotEmpty);
        final avatarUrl = profile.customAvatarUrl ?? authAvatar;

        return Card(
          child: InkWell(
            onTap: onTap ?? () => ProfileEditDialog.show(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: hasAvatar
                          ? (avatarUrl!.startsWith('http')
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      profile.avatarEmoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                )
                              : Image.file(
                                  File(profile.customAvatarUrl!),
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      profile.avatarEmoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ))
                          : Center(
                              child: Text(
                                profile.avatarEmoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.getDisplayName(null),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (profile.bio != null && profile.bio!.isNotEmpty)
                          Text(
                            profile.bio!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
