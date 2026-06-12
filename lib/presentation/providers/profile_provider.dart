import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/auth/alpha_auth_session.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/image_service.dart';
import '../../data/remote/mongo/vocab_api_helpers.dart';

/// Provider for managing user profile state.
class ProfileProvider extends ChangeNotifier {
  final AppPreferences _preferences;
  final ImageService _imageService = ImageService();
  final ApiClient _apiClient = ApiClient();
  final AlphaAuthSession _authSession = AlphaAuthSession();

  UserProfile _profile = const UserProfile();
  bool _isLoading = false;

  ProfileProvider({required AppPreferences preferences})
      : _preferences = preferences {
    _loadProfile();
  }

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

  String getDisplayName(String? fallback) => _profile.getDisplayName(fallback);

  void _loadProfile() {
    final gender = Gender.values.firstWhere(
      (g) => g.name == _preferences.profileGender,
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

  Future<String?> pickAvatarImage() async {
    final savedPath = await _imageService.pickAndSaveImage(maxWidth: 300, useB2: true);
    if (savedPath != null) {
      await setCustomAvatarPath(savedPath);
    }
    return savedPath;
  }

  Future<void> setCustomAvatarPath(String? path) async {
    if (_profile.customAvatarUrl != null && _profile.customAvatarUrl != path) {
      await _imageService.deleteImage(_profile.customAvatarUrl!);
    }

    await _preferences.setProfileCustomAvatarPath(path);
    final now = DateTime.now();
    _profile = _profile.copyWith(customAvatarUrl: path, updatedAt: now);
    await _preferences.setProfileUpdatedAt(now);
    notifyListeners();
    _syncToRemote();
  }

  Future<void> removeCustomAvatar() async {
    if (_profile.customAvatarUrl != null) {
      await _imageService.deleteImage(_profile.customAvatarUrl!);
    }
    await _preferences.setProfileCustomAvatarPath(null);
    await _preferences.setProfileCloudAvatarUrl(null);
    final now = DateTime.now();
    _profile = UserProfile(
      nickname: _profile.nickname,
      gender: _profile.gender,
      avatarIndex: _profile.avatarIndex,
      customAvatarUrl: null,
      bio: _profile.bio,
      updatedAt: now,
    );
    await _preferences.setProfileUpdatedAt(now);
    notifyListeners();
    _syncToRemote();
  }

  Future<void> setNickname(String? value) async {
    await _preferences.setProfileNickname(value);
    final now = DateTime.now();
    _profile = _profile.copyWith(nickname: value, updatedAt: now);
    await _preferences.setProfileUpdatedAt(now);
    notifyListeners();
    _syncToRemote();
  }

  Future<void> setGender(Gender value) async {
    await _preferences.setProfileGender(value.name);
    final now = DateTime.now();
    _profile = _profile.copyWith(gender: value, updatedAt: now);
    await _preferences.setProfileUpdatedAt(now);
    notifyListeners();
    _syncToRemote();
  }

  Future<void> setAvatarIndex(int value) async {
    await _preferences.setProfileAvatarIndex(value);
    final now = DateTime.now();
    _profile = _profile.copyWith(avatarIndex: value, updatedAt: now);
    await _preferences.setProfileUpdatedAt(now);
    notifyListeners();
    _syncToRemote();
  }

  Future<void> setBio(String? value) async {
    await _preferences.setProfileBio(value);
    final now = DateTime.now();
    _profile = _profile.copyWith(bio: value, updatedAt: now);
    await _preferences.setProfileUpdatedAt(now);
    notifyListeners();
    _syncToRemote();
  }

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

      final now = DateTime.now();
      await _preferences.setProfileUpdatedAt(now);
      _profile = UserProfile(
        nickname: nickname ?? _profile.nickname,
        gender: gender ?? _profile.gender,
        avatarIndex: avatarIndex ?? _profile.avatarIndex,
        customAvatarUrl: _profile.customAvatarUrl,
        bio: bio ?? _profile.bio,
        updatedAt: now,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    _syncToRemote();
  }

  Future<void> resetProfile() async {
    if (_profile.customAvatarUrl != null) {
      await _imageService.deleteImage(_profile.customAvatarUrl!);
    }
    await _preferences.setProfileNickname(null);
    await _preferences.setProfileGender(Gender.preferNotToSay.name);
    await _preferences.setProfileAvatarIndex(0);
    await _preferences.setProfileCustomAvatarPath(null);
    await _preferences.setProfileCloudAvatarUrl(null);
    await _preferences.setProfileBio(null);
    await _preferences.setProfileUpdatedAt(DateTime.now());

    _profile = const UserProfile();
    notifyListeners();
    _syncToRemote();
  }

  Future<void> _syncToRemote() async {
    if (!_authSession.isAuthenticated) return;

    try {
      await _apiClient.dio.put('/vocab/profile', data: {
        'nickname': _profile.nickname,
        'gender': _profile.gender.name,
        'avatar_index': _profile.avatarIndex,
        'avatar_url': _profile.customAvatarUrl,
        'bio': _profile.bio,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('ProfileProvider: remote profile sync error: $e');
    }
  }

  Future<void> loadFromRemote() async {
    if (!_authSession.isAuthenticated) return;

    try {
      final response = await _apiClient.dio.get('/vocab/profile');
      final data = unwrapApiMap(response.data);
      if (data == null) {
        _syncToRemote();
        return;
      }

      final remoteProfile = _profileFromApi(data);
      final localUpdatedAt = _profile.updatedAt;
      final remoteUpdatedAt = remoteProfile.updatedAt;

      if (remoteUpdatedAt != null &&
          (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
        await _preferences.setProfileNickname(remoteProfile.nickname);
        await _preferences.setProfileGender(remoteProfile.gender.name);
        await _preferences.setProfileAvatarIndex(remoteProfile.avatarIndex);
        await _preferences.setProfileCustomAvatarPath(remoteProfile.customAvatarUrl);
        await _preferences.setProfileCloudAvatarUrl(remoteProfile.customAvatarUrl);
        await _preferences.setProfileBio(remoteProfile.bio);
        await _preferences.setProfileUpdatedAt(remoteUpdatedAt);
        _loadProfile();
        notifyListeners();
      } else {
        _syncToRemote();
      }
    } catch (e) {
      debugPrint('ProfileProvider: load remote profile error: $e');
    }
  }

  Future<String?> checkNicknameAvailability(String nickname) async {
    if (nickname.trim().isEmpty) return null;

    try {
      final response = await _apiClient.dio.get(
        '/vocab/profiles/check-nickname',
        queryParameters: {'nickname': nickname.trim()},
      );
      final data = unwrapApiMap(response.data);
      final userId = data?['user_id']?.toString() ?? data?['id']?.toString();
      if (userId != null && userId != _authSession.userId) {
        return userId;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      debugPrint('ProfileProvider: checkNicknameAvailability error: $e');
      return null;
    } catch (e) {
      debugPrint('ProfileProvider: checkNicknameAvailability error: $e');
      return null;
    }
  }

  UserProfile _profileFromApi(Map<String, dynamic> data) {
    return UserProfile(
      nickname: data['nickname'] as String?,
      gender: Gender.values.firstWhere(
        (g) => g.name == data['gender'],
        orElse: () => Gender.preferNotToSay,
      ),
      avatarIndex: data['avatar_index'] as int? ?? 0,
      customAvatarUrl: data['avatar_url'] as String? ??
          data['custom_avatar_url'] as String?,
      bio: data['bio'] as String?,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }
}
