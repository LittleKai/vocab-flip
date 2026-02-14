import 'package:flutter/foundation.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/image_service.dart';

/// Provider for managing user profile state
class ProfileProvider extends ChangeNotifier {
  final AppPreferences _preferences;
  final ImageService _imageService = ImageService();
  UserProfile _profile = const UserProfile();
  bool _isLoading = false;

  ProfileProvider({required AppPreferences preferences})
      : _preferences = preferences {
    _loadProfile();
  }

  // Getters
  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get nickname => _profile.nickname;
  Gender get gender => _profile.gender;
  int get avatarIndex => _profile.avatarIndex;
  String get avatarEmoji => _profile.avatarEmoji;
  String? get customAvatarPath => _profile.customAvatarUrl;
  bool get hasCustomAvatar => _profile.hasCustomAvatar;
  String? get bio => _profile.bio;
  bool get isCustomized => _profile.isCustomized;

  /// Get display name with fallback
  String getDisplayName(String? fallback) => _profile.getDisplayName(fallback);

  /// Load profile from preferences
  void _loadProfile() {
    final genderString = _preferences.profileGender;
    final gender = Gender.values.firstWhere(
      (g) => g.name == genderString,
      orElse: () => Gender.preferNotToSay,
    );

    _profile = UserProfile(
      nickname: _preferences.profileNickname,
      gender: gender,
      avatarIndex: _preferences.profileAvatarIndex,
      customAvatarUrl: _preferences.profileCustomAvatarPath,
      bio: _preferences.profileBio,
      updatedAt: _preferences.profileUpdatedAt,
    );
  }

  /// Pick and save a custom avatar image
  /// Returns the saved path or null if cancelled
  Future<String?> pickAvatarImage() async {
    final savedPath = await _imageService.pickAndSaveImage(maxWidth: 300);
    if (savedPath != null) {
      await setCustomAvatarPath(savedPath);
    }
    return savedPath;
  }

  /// Set custom avatar path
  Future<void> setCustomAvatarPath(String? path) async {
    // Delete old custom avatar if exists
    if (_profile.customAvatarUrl != null && _profile.customAvatarUrl != path) {
      await _imageService.deleteImage(_profile.customAvatarUrl!);
    }

    await _preferences.setProfileCustomAvatarPath(path);
    _profile = _profile.copyWith(
      customAvatarUrl: path,
      updatedAt: DateTime.now(),
    );
    await _preferences.setProfileUpdatedAt(DateTime.now());
    notifyListeners();
  }

  /// Remove custom avatar (revert to emoji)
  Future<void> removeCustomAvatar() async {
    if (_profile.customAvatarUrl != null) {
      await _imageService.deleteImage(_profile.customAvatarUrl!);
    }
    await _preferences.setProfileCustomAvatarPath(null);
    // Use copyWith workaround: create new instance without customAvatarUrl
    _profile = UserProfile(
      nickname: _profile.nickname,
      gender: _profile.gender,
      avatarIndex: _profile.avatarIndex,
      customAvatarUrl: null,
      bio: _profile.bio,
      updatedAt: DateTime.now(),
    );
    await _preferences.setProfileUpdatedAt(DateTime.now());
    notifyListeners();
  }

  /// Update nickname
  Future<void> setNickname(String? value) async {
    await _preferences.setProfileNickname(value);
    _profile = _profile.copyWith(
      nickname: value,
      updatedAt: DateTime.now(),
    );
    await _preferences.setProfileUpdatedAt(DateTime.now());
    notifyListeners();
  }

  /// Update gender
  Future<void> setGender(Gender value) async {
    await _preferences.setProfileGender(value.name);
    _profile = _profile.copyWith(
      gender: value,
      updatedAt: DateTime.now(),
    );
    await _preferences.setProfileUpdatedAt(DateTime.now());
    notifyListeners();
  }

  /// Update avatar index
  Future<void> setAvatarIndex(int value) async {
    await _preferences.setProfileAvatarIndex(value);
    _profile = _profile.copyWith(
      avatarIndex: value,
      updatedAt: DateTime.now(),
    );
    await _preferences.setProfileUpdatedAt(DateTime.now());
    notifyListeners();
  }

  /// Update bio
  Future<void> setBio(String? value) async {
    await _preferences.setProfileBio(value);
    _profile = _profile.copyWith(
      bio: value,
      updatedAt: DateTime.now(),
    );
    await _preferences.setProfileUpdatedAt(DateTime.now());
    notifyListeners();
  }

  /// Update entire profile at once
  Future<void> updateProfile({
    String? nickname,
    Gender? gender,
    int? avatarIndex,
    String? bio,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (nickname != null) {
        await _preferences.setProfileNickname(nickname.isEmpty ? null : nickname);
      }
      if (gender != null) {
        await _preferences.setProfileGender(gender.name);
      }
      if (avatarIndex != null) {
        await _preferences.setProfileAvatarIndex(avatarIndex);
      }
      if (bio != null) {
        await _preferences.setProfileBio(bio.isEmpty ? null : bio);
      }
      await _preferences.setProfileUpdatedAt(DateTime.now());

      _profile = UserProfile(
        nickname: nickname ?? _profile.nickname,
        gender: gender ?? _profile.gender,
        avatarIndex: avatarIndex ?? _profile.avatarIndex,
        customAvatarUrl: _profile.customAvatarUrl,
        bio: bio ?? _profile.bio,
        updatedAt: DateTime.now(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset profile to defaults
  Future<void> resetProfile() async {
    if (_profile.customAvatarUrl != null) {
      await _imageService.deleteImage(_profile.customAvatarUrl!);
    }
    await _preferences.setProfileNickname(null);
    await _preferences.setProfileGender(Gender.preferNotToSay.name);
    await _preferences.setProfileAvatarIndex(0);
    await _preferences.setProfileCustomAvatarPath(null);
    await _preferences.setProfileBio(null);

    _profile = const UserProfile();
    notifyListeners();
  }
}
