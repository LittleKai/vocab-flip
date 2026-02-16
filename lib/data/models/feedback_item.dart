class FeedbackItem {
  final String id;
  final String category;
  final String message;
  final String? email;
  final String appVersion;
  final String platform;
  final DateTime createdAt;
  final String? userId;

  FeedbackItem({
    required this.id,
    required this.category,
    required this.message,
    this.email,
    required this.appVersion,
    required this.platform,
    required this.createdAt,
    this.userId,
  });

  factory FeedbackItem.fromMap(Map<String, dynamic> map) {
    return FeedbackItem(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      message: map['message'] ?? '',
      email: map['email'],
      appVersion: map['app_version'] ?? '',
      platform: map['platform'] ?? '',
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
      userId: map['user_id'],
    );
  }
}
