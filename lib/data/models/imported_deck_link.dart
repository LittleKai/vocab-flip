import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking the link between an imported deck and its public source
class ImportedDeckLink {
  final String id;
  final String publicDeckId;
  final String localDeckId;
  final String userId;
  final int importedVersion;
  final DateTime importedAt;
  final DateTime? lastSyncedAt;
  final bool autoSync;

  ImportedDeckLink({
    required this.id,
    required this.publicDeckId,
    required this.localDeckId,
    required this.userId,
    required this.importedVersion,
    DateTime? importedAt,
    this.lastSyncedAt,
    this.autoSync = true,
  }) : importedAt = importedAt ?? DateTime.now();

  /// Check if there's an update available
  bool hasUpdate(int currentPublicVersion) {
    return currentPublicVersion > importedVersion;
  }

  ImportedDeckLink copyWith({
    String? id,
    String? publicDeckId,
    String? localDeckId,
    String? userId,
    int? importedVersion,
    DateTime? importedAt,
    DateTime? lastSyncedAt,
    bool? autoSync,
  }) {
    return ImportedDeckLink(
      id: id ?? this.id,
      publicDeckId: publicDeckId ?? this.publicDeckId,
      localDeckId: localDeckId ?? this.localDeckId,
      userId: userId ?? this.userId,
      importedVersion: importedVersion ?? this.importedVersion,
      importedAt: importedAt ?? this.importedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      autoSync: autoSync ?? this.autoSync,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'public_deck_id': publicDeckId,
      'local_deck_id': localDeckId,
      'user_id': userId,
      'imported_version': importedVersion,
      'imported_at': Timestamp.fromDate(importedAt),
      'last_synced_at': lastSyncedAt != null ? Timestamp.fromDate(lastSyncedAt!) : null,
      'auto_sync': autoSync,
    };
  }

  factory ImportedDeckLink.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ImportedDeckLink(
      id: doc.id,
      publicDeckId: data['public_deck_id'] as String,
      localDeckId: data['local_deck_id'] as String,
      userId: data['user_id'] as String,
      importedVersion: data['imported_version'] as int,
      importedAt: (data['imported_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSyncedAt: (data['last_synced_at'] as Timestamp?)?.toDate(),
      autoSync: data['auto_sync'] as bool? ?? true,
    );
  }

  /// For local SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'public_deck_id': publicDeckId,
      'local_deck_id': localDeckId,
      'user_id': userId,
      'imported_version': importedVersion,
      'imported_at': importedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'auto_sync': autoSync ? 1 : 0,
    };
  }

  factory ImportedDeckLink.fromMap(Map<String, dynamic> map) {
    return ImportedDeckLink(
      id: map['id'] as String,
      publicDeckId: map['public_deck_id'] as String,
      localDeckId: map['local_deck_id'] as String,
      userId: map['user_id'] as String,
      importedVersion: map['imported_version'] as int,
      importedAt: DateTime.parse(map['imported_at'] as String),
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.parse(map['last_synced_at'] as String)
          : null,
      autoSync: (map['auto_sync'] as int?) == 1,
    );
  }

  @override
  String toString() =>
      'ImportedDeckLink(id: $id, publicDeckId: $publicDeckId, localDeckId: $localDeckId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImportedDeckLink && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
