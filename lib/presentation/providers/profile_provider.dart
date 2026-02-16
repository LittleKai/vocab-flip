import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/remote/firebase/firebase_service.dart';
import '../../data/remote/firebase/firestore_rest_client.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/services/image_service.dart';

/// Provider for managing user profile state
class ProfileProvider extends ChangeNotifier {
  final AppPreferences _preferences;
  final ImageService _imageService = ImageService();
  final FirebaseService _firebaseService = FirebaseService();
  final FirestoreRestClient _firestoreClient = FirestoreRestClient();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Check if we should use REST API (Windows) or native SDK
  bool get _useRest => FirestoreRestClient.shouldUseRest;
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
    _syncToFirebase(avatarChanged: true);
  }

  /// Remove custom avatar (revert to emoji)
  Future<void> removeCustomAvatar() async {
    if (_profile.customAvatarUrl != null) {
      await _imageService.deleteImage(_profile.customAvatarUrl!);
    }
    await _preferences.setProfileCustomAvatarPath(null);
    await _preferences.setProfileCloudAvatarUrl(null);
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
    _syncToFirebase();
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
    _syncToFirebase();
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
    _syncToFirebase();
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
    _syncToFirebase();
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
    _syncToFirebase();
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
    _syncToFirebase();
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
    await _preferences.setProfileCloudAvatarUrl(null);
    await _preferences.setProfileBio(null);

    _profile = const UserProfile();
    notifyListeners();
  }

  /// Sync profile to Firebase (fire-and-forget)
  Future<void> _syncToFirebase({bool avatarChanged = false}) async {
    debugPrint('ProfileProvider._syncToFirebase() called, avatarChanged=$avatarChanged');
    debugPrint('ProfileProvider._syncToFirebase: isSignedIn=${_firebaseService.isSignedIn}, _useRest=$_useRest');
    if (!_firebaseService.isSignedIn) {
      debugPrint('ProfileProvider._syncToFirebase: NOT signed in, returning');
      return;
    }

    final userId = _firebaseService.userId;
    if (userId == null) {
      debugPrint('ProfileProvider._syncToFirebase: userId is NULL, returning');
      return;
    }
    debugPrint('ProfileProvider._syncToFirebase: userId=$userId');

    try {
      String? cloudAvatarUrl = _preferences.profileCloudAvatarUrl;

      // Upload custom avatar to Cloudinary if changed
      if (avatarChanged && _profile.hasCustomAvatar) {
        final localPath = _profile.customAvatarUrl!;
        if (CloudinaryService.isLocalPath(localPath)) {
          final result = await _cloudinaryService.uploadImage(
            localPath,
            subfolder: 'avatars',
          );
          if (result.success && result.url != null) {
            cloudAvatarUrl = result.url;
            await _preferences.setProfileCloudAvatarUrl(cloudAvatarUrl);
          } else {
            debugPrint('ProfileProvider: Avatar upload failed: ${result.error}');
          }
        }
      } else if (avatarChanged && !_profile.hasCustomAvatar) {
        // Avatar was removed
        cloudAvatarUrl = null;
        await _preferences.setProfileCloudAvatarUrl(null);
      }

      final data = _profile.toFirestore(cloudAvatarUrl: cloudAvatarUrl);

      // Public profile data (subset for public visibility)
      final publicData = {
        'nickname': _profile.nickname,
        'avatar_url': cloudAvatarUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (_useRest) {
        final success = await _firestoreClient.setDocument(
          'users', userId, data, merge: true,
        );
        if (success) {
          debugPrint('ProfileProvider: Profile synced to Firebase (REST)');
        } else {
          debugPrint('ProfileProvider: Failed to sync profile to Firebase (REST)');
        }
        // Also sync public profile
        final publicSuccess = await _firestoreClient.setDocument(
          AppConstants.collectionPublicProfiles, userId, publicData, merge: true,
        );
        debugPrint('ProfileProvider: Public profile sync ${publicSuccess ? "OK" : "FAILED"} (REST)');
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(data, SetOptions(merge: true));
        debugPrint('ProfileProvider: Profile synced to Firebase (native)');
        // Also sync public profile
        await FirebaseFirestore.instance
            .collection(AppConstants.collectionPublicProfiles)
            .doc(userId)
            .set(publicData, SetOptions(merge: true));
        debugPrint('ProfileProvider: Public profile synced (native)');
      }
    } catch (e) {
      debugPrint('ProfileProvider: Sync error: $e');
    }
  }

  /// Load profile from Firebase (called after sign-in)
  Future<void> loadFromFirebase() async {
    debugPrint('ProfileProvider.loadFromFirebase() called');
    debugPrint('ProfileProvider: isSignedIn=${_firebaseService.isSignedIn}');
    debugPrint('ProfileProvider: userId=${_firebaseService.userId}');
    debugPrint('ProfileProvider: _useRest=$_useRest (platform=${Platform.operatingSystem})');
    debugPrint('ProfileProvider: local profile: nickname=${_profile.nickname}, updatedAt=${_profile.updatedAt}');

    if (!_firebaseService.isSignedIn) {
      debugPrint('ProfileProvider: NOT signed in, returning early');
      return;
    }

    final userId = _firebaseService.userId;
    if (userId == null) {
      debugPrint('ProfileProvider: userId is NULL, returning early');
      return;
    }

    try {
      Map<String, dynamic>? data;
      if (_useRest) {
        debugPrint('ProfileProvider: Using REST to get users/$userId');
        data = await _firestoreClient.getDocument('users', userId, requireAuth: true);
        debugPrint('ProfileProvider: REST getDocument returned: ${data != null ? "data with ${data.keys.length} keys: ${data.keys.toList()}" : "NULL"}');
      } else {
        debugPrint('ProfileProvider: Using NATIVE Firestore to get users/$userId');
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          debugPrint('ProfileProvider: Native doc.exists=${doc.exists}, doc.data keys=${doc.data()?.keys.toList()}');
          data = doc.data();
        } catch (nativeError) {
          debugPrint('ProfileProvider: Native Firestore ERROR: $nativeError');
          rethrow;
        }
      }

      if (data == null) {
        debugPrint('ProfileProvider: No Firebase data exists, pushing local to Firebase');
        _syncToFirebase(avatarChanged: _profile.hasCustomAvatar);
        return;
      }

      debugPrint('ProfileProvider: Firebase data: $data');
      final remoteProfile = UserProfile.fromFirestore(data);
      final localUpdatedAt = _profile.updatedAt;
      final remoteUpdatedAt = remoteProfile.updatedAt;
      debugPrint('ProfileProvider: remote nickname=${remoteProfile.nickname}, remote updatedAt=$remoteUpdatedAt');
      debugPrint('ProfileProvider: local updatedAt=$localUpdatedAt');

      // If remote is newer, update local from Firebase
      if (remoteUpdatedAt != null &&
          (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
        debugPrint('ProfileProvider: Remote is NEWER, updating local from Firebase');
        // Update local preferences
        await _preferences.setProfileNickname(remoteProfile.nickname);
        await _preferences.setProfileGender(remoteProfile.gender.name);
        await _preferences.setProfileAvatarIndex(remoteProfile.avatarIndex);
        await _preferences.setProfileBio(remoteProfile.bio);
        await _preferences.setProfileUpdatedAt(remoteUpdatedAt);

        // Handle cloud avatar URL
        final remoteAvatarUrl = data['avatar_url'] as String?;
        debugPrint('ProfileProvider: remote avatar_url=$remoteAvatarUrl');
        if (remoteAvatarUrl != null && remoteAvatarUrl.isNotEmpty) {
          await _preferences.setProfileCloudAvatarUrl(remoteAvatarUrl);
          // Download avatar image to local if we don't have it
          if (_profile.customAvatarUrl == null || !await _imageExists(_profile.customAvatarUrl!)) {
            final localDir = await _cloudinaryService.getImageDirectory();
            final localPath = await _cloudinaryService.downloadImage(remoteAvatarUrl, localDir);
            if (localPath != null) {
              await _preferences.setProfileCustomAvatarPath(localPath);
            }
          }
        } else {
          await _preferences.setProfileCustomAvatarPath(null);
          await _preferences.setProfileCloudAvatarUrl(null);
        }

        _loadProfile();
        notifyListeners();
        debugPrint('ProfileProvider: Profile loaded from Firebase DONE');
      } else {
        debugPrint('ProfileProvider: Local is newer or same, pushing to Firebase');
        _syncToFirebase(avatarChanged: _profile.hasCustomAvatar);
      }
    } catch (e, stackTrace) {
      debugPrint('ProfileProvider: loadFromFirebase ERROR: $e');
      debugPrint('ProfileProvider: stack trace: $stackTrace');
    }
  }

  /// Check if a nickname is already taken by another user.
  /// Returns the userId of the user who has this nickname, or null if available.
  Future<String?> checkNicknameAvailability(String nickname) async {
    if (nickname.trim().isEmpty) return null;

    try {
      final userId = _firebaseService.userId;

      if (_useRest) {
        final results = await _firestoreClient.getCollection(
          AppConstants.collectionPublicProfiles,
          where: [QueryFilter.isEqualTo('nickname', nickname.trim())],
          limit: 1,
        );
        if (results.isNotEmpty) {
          // Check if it's taken by someone else
          final docId = results.first['id'] as String?;
          if (docId != null && docId != userId) {
            return docId;
          }
        }
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection(AppConstants.collectionPublicProfiles)
            .where('nickname', isEqualTo: nickname.trim())
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final docId = snapshot.docs.first.id;
          if (docId != userId) {
            return docId;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('ProfileProvider: checkNicknameAvailability error: $e');
      return null;
    }
  }

  /// Check if a local file exists
  Future<bool> _imageExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }
}
