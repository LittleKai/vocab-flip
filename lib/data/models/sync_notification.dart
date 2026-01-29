import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for sync update notifications
class SyncNotification {
  final String id;
  final String userId;
  final String publicDeckId;
  final String deckName;
  final int oldVersion;
  final int newVersion;
  final String? changeDescription;
  final bool isRead;
  final DateTime createdAt;

  SyncNotification({
    required this.id,
    required this.userId,
    required this.publicDeckId,
    required this.deckName,
    required this.oldVersion,
    required this.newVersion,
    this.changeDescription,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SyncNotification copyWith({
    String? id,
    String? userId,
    String? publicDeckId,
    String? deckName,
    int? oldVersion,
    int? newVersion,
    String? changeDescription,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return SyncNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      publicDeckId: publicDeckId ?? this.publicDeckId,
      deckName: deckName ?? this.deckName,
      oldVersion: oldVersion ?? this.oldVersion,
      newVersion: newVersion ?? this.newVersion,
      changeDescription: changeDescription ?? this.changeDescription,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'public_deck_id': publicDeckId,
      'deck_name': deckName,
      'old_version': oldVersion,
      'new_version': newVersion,
      'change_description': changeDescription,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory SyncNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SyncNotification(
      id: doc.id,
      userId: data['user_id'] as String,
      publicDeckId: data['public_deck_id'] as String,
      deckName: data['deck_name'] as String,
      oldVersion: data['old_version'] as int,
      newVersion: data['new_version'] as int,
      changeDescription: data['change_description'] as String?,
      isRead: data['is_read'] as bool? ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory SyncNotification.fromMap(Map<String, dynamic> data) {
    return SyncNotification(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      publicDeckId: data['public_deck_id'] as String,
      deckName: data['deck_name'] as String,
      oldVersion: data['old_version'] as int,
      newVersion: data['new_version'] as int,
      changeDescription: data['change_description'] as String?,
      isRead: data['is_read'] as bool? ?? false,
      createdAt: data['created_at'] is DateTime
          ? data['created_at'] as DateTime
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'SyncNotification(id: $id, deckName: $deckName, v$oldVersion -> v$newVersion)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
