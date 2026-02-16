/// Lightweight public profile for author display and nickname uniqueness
class PublicProfile {
  final String userId;
  final String? nickname;
  final String? avatarUrl;
  final DateTime? updatedAt;

  const PublicProfile({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory PublicProfile.fromFirestore(String userId, Map<String, dynamic> data) {
    return PublicProfile(
      userId: userId,
      nickname: data['nickname'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] is DateTime
              ? data['updated_at'] as DateTime
              : DateTime.tryParse(data['updated_at'].toString()))
          : null,
    );
  }

  factory PublicProfile.fromMap(String userId, Map<String, dynamic> map) {
    return PublicProfile(
      userId: userId,
      nickname: map['nickname'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  @override
  String toString() => 'PublicProfile(userId: $userId, nickname: $nickname)';
}
