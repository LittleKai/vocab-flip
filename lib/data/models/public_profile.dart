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
