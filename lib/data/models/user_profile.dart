/// Gender options for user profile
enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  String get displayNameVi {
    switch (this) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
      case Gender.preferNotToSay:
        return 'Không muốn nói';
    }
  }
}

/// User profile data model
class UserProfile {
  final String? nickname;
  final Gender gender;
  final int avatarIndex; // Index of predefined avatar (0-11)
  final String? customAvatarUrl;
  final String? bio;
  final DateTime? updatedAt;

  const UserProfile({
    this.nickname,
    this.gender = Gender.preferNotToSay,
    this.avatarIndex = 0,
    this.customAvatarUrl,
    this.bio,
    this.updatedAt,
  });

  /// Check if profile has been customized
  bool get isCustomized => nickname != null || avatarIndex != 0 || customAvatarUrl != null || bio != null;

  /// Whether user has a custom avatar image
  bool get hasCustomAvatar => customAvatarUrl != null && customAvatarUrl!.isNotEmpty;

  /// Get display name (nickname or fallback)
  String getDisplayName(String? fallback) {
    if (nickname != null && nickname!.isNotEmpty) {
      return nickname!;
    }
    return fallback ?? 'User';
  }

  /// Get avatar emoji based on index
  String get avatarEmoji => predefinedAvatars[avatarIndex % predefinedAvatars.length];

  /// Predefined avatar emojis
  static const List<String> predefinedAvatars = [
    '😊', // 0 - Default smile
    '😎', // 1 - Cool
    '🤓', // 2 - Nerd
    '🦊', // 3 - Fox
    '🐱', // 4 - Cat
    '🐶', // 5 - Dog
    '🦁', // 6 - Lion
    '🐼', // 7 - Panda
    '🦄', // 8 - Unicorn
    '🌸', // 9 - Flower
    '⭐', // 10 - Star
    '🎓', // 11 - Graduate
  ];

  UserProfile copyWith({
    String? nickname,
    Gender? gender,
    int? avatarIndex,
    String? customAvatarUrl,
    String? bio,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      customAvatarUrl: customAvatarUrl ?? this.customAvatarUrl,
      bio: bio ?? this.bio,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'gender': gender.name,
      'avatar_index': avatarIndex,
      'custom_avatar_url': customAvatarUrl,
      'bio': bio,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nickname: json['nickname'] as String?,
      gender: Gender.values.firstWhere(
        (g) => g.name == json['gender'],
        orElse: () => Gender.preferNotToSay,
      ),
      avatarIndex: json['avatar_index'] as int? ?? 0,
      customAvatarUrl: json['custom_avatar_url'] as String?,
      bio: json['bio'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  String toString() => 'UserProfile(nickname: $nickname, gender: ${gender.name}, avatar: $avatarIndex)';
}
