import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/api/api_client.dart';
import '../../data/auth/alpha_auth_session.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/image_service.dart';
import '../../data/remote/mongo/vocab_api_helpers.dart';

class ProfileProvider extends ChangeNotifier {
  final AppPreferences _preferences;
  final ImageService _imageService = ImageService();
  final ApiClient _apiClient = ApiClient();
  final AlphaAuthSession _authSession = AlphaAuthSession();
  UserProfile _profile = const UserProfile();
  String? _owner;
  int _generation = 0;
  bool _isLoading = false;

  ProfileProvider({required AppPreferences preferences})
      : _preferences = preferences {
    _owner = _authSession.userId;
    _loadProfile();
    _authSession.addListener(_accountChanged);
    if (_owner != null) loadFromRemote();
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
    _profile = const UserProfile();
    final json = _preferences.profileJsonFor(_owner);
    if (json == null) return;
    try {
      _profile = UserProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(json) as Map));
    } catch (_) {/* A damaged cache cannot become another account's profile. */}
  }

  void _accountChanged() {
    if (_owner == _authSession.userId) return;
    ++_generation;
    _owner = _authSession.userId;
    _isLoading = false;
    _loadProfile();
    notifyListeners();
    if (_owner != null) loadFromRemote();
  }

  bool _current(int generation) => generation == _generation;

  Future<void> _save(UserProfile profile) async {
    final owner = _owner;
    final generation = ++_generation;
    final session = _apiClient.sessionVersion;
    // One snapshot write targets the captured account even if storage yields.
    await _preferences.setProfileJsonFor(owner, jsonEncode(profile.toJson()));
    if (!_current(generation)) return;
    _profile = profile;
    _isLoading = false;
    notifyListeners();
    await _syncToRemote(profile, owner, generation, session);
  }

  Future<String?> pickAvatarImage() async {
    final generation = _generation;
    final saved =
        await _imageService.pickAndSaveImage(maxWidth: 300, useB2: true);
    if (!_current(generation)) return null;
    if (saved != null) await setCustomAvatarPath(saved);
    return saved;
  }

  Future<void> setCustomAvatarPath(String? path) => _save(UserProfile(
        nickname: nickname,
        gender: gender,
        avatarIndex: avatarIndex,
        customAvatarUrl: path,
        bio: bio,
        updatedAt: DateTime.now(),
      ));
  Future<void> removeCustomAvatar() => setCustomAvatarPath(null);
  Future<void> setNickname(String? value) => _save(UserProfile(
        nickname: value,
        gender: gender,
        avatarIndex: avatarIndex,
        customAvatarUrl: customAvatarPath,
        bio: bio,
        updatedAt: DateTime.now(),
      ));
  Future<void> setGender(Gender value) => updateProfile(gender: value);
  Future<void> setAvatarIndex(int value) => updateProfile(avatarIndex: value);
  Future<void> setBio(String? value) => _save(UserProfile(
        nickname: nickname,
        gender: gender,
        avatarIndex: avatarIndex,
        customAvatarUrl: customAvatarPath,
        bio: value,
        updatedAt: DateTime.now(),
      ));

  Future<void> updateProfile(
          {String? nickname, Gender? gender, int? avatarIndex, String? bio}) =>
      _save(UserProfile(
        nickname: nickname == null
            ? this.nickname
            : (nickname.isEmpty ? null : nickname),
        gender: gender ?? this.gender,
        avatarIndex: avatarIndex ?? this.avatarIndex,
        customAvatarUrl: customAvatarPath,
        bio: bio == null ? this.bio : (bio.isEmpty ? null : bio),
        updatedAt: DateTime.now(),
      ));

  Future<void> resetProfile() => _save(UserProfile(updatedAt: DateTime.now()));

  Future<void> _syncToRemote(
      UserProfile profile, String? owner, int generation, int session) async {
    if (owner == null || !_current(generation)) return;
    try {
      await _apiClient.dio.put('/vocab/profile',
          data: {
            ...profile.toJson(),
            'avatar_url': profile.customAvatarUrl,
          'updated_at': profile.updatedAt?.toUtc().toIso8601String(),
          },
          options: Options(
              extra: {'syncOwnerUserId': owner, 'sessionVersion': session}));
    } catch (_) {
      debugPrint('Profile sync unavailable; account cache retained.');
    }
  }

  Future<void> loadFromRemote() async {
    final owner = _owner;
    if (owner == null) return;
    final generation = ++_generation;
    final session = _apiClient.sessionVersion;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/vocab/profile',
          options: Options(extra: {
            'syncOwnerUserId': owner,
            'sessionVersion': session,
          }));
      if (!_current(generation)) return;
      final data = unwrapApiMap(response.data);
      if (data == null) {
        await _syncToRemote(_profile, owner, generation, session);
        return;
      }
      final remote = UserProfile.fromJson({
        ...data,
        'custom_avatar_url': data['avatar_url'] ?? data['custom_avatar_url'],
      });
      if (_profile.updatedAt == null ||
          (remote.updatedAt != null &&
              remote.updatedAt!.isAfter(_profile.updatedAt!))) {
        await _preferences.setProfileJsonFor(
            owner, jsonEncode(remote.toJson()));
        if (!_current(generation)) return;
        _profile = remote;
      } else {
        await _syncToRemote(_profile, owner, generation, session);
      }
    } catch (_) {
      debugPrint('Profile load unavailable; account cache retained.');
    } finally {
      if (_current(generation)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<String?> checkNicknameAvailability(String nickname) async {
    if (nickname.trim().isEmpty) return null;
    final generation = _generation;
    try {
      final response = await _apiClient.dio.get(
          '/vocab/profiles/check-nickname',
          queryParameters: {'nickname': nickname.trim()});
      if (!_current(generation)) return null;
      final data = unwrapApiMap(response.data);
      final userId = data?['user_id']?.toString() ?? data?['id']?.toString();
      return userId != _owner ? userId : null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    ++_generation;
    _authSession.removeListener(_accountChanged);
    super.dispose();
  }
}
