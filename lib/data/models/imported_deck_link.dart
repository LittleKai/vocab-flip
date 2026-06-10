
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
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    DateTime? parseDateNullable(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    return ImportedDeckLink(
      id: map['id'] as String,
      publicDeckId: map['public_deck_id'] as String,
      localDeckId: map['local_deck_id'] as String,
      userId: map['user_id'] as String,
      importedVersion: map['imported_version'] as int,
      importedAt: parseDate(map['imported_at']),
      lastSyncedAt: parseDateNullable(map['last_synced_at']),
      autoSync: map['auto_sync'] is int
          ? (map['auto_sync'] as int) == 1
          : map['auto_sync'] as bool? ?? true,
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
