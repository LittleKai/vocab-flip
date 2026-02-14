/// Metadata for a backup stored in Google Drive
class BackupMetadata {
  final String id;
  final String name;
  final String backupVersion;
  final String appVersion;
  final DateTime createdAt;
  final int deckCount;
  final int cardCount;
  final int fileSize;

  const BackupMetadata({
    required this.id,
    required this.name,
    required this.backupVersion,
    required this.appVersion,
    required this.createdAt,
    required this.deckCount,
    required this.cardCount,
    this.fileSize = 0,
  });

  factory BackupMetadata.fromJson(Map<String, dynamic> json, {String? fileId, int? size}) {
    return BackupMetadata(
      id: fileId ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Backup',
      backupVersion: json['backup_version'] ?? '1.0',
      appVersion: json['app_version'] ?? 'Unknown',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      deckCount: json['summary']?['deck_count'] ?? 0,
      cardCount: json['summary']?['card_count'] ?? 0,
      fileSize: size ?? json['file_size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backup_version': backupVersion,
      'app_version': appVersion,
      'created_at': createdAt.toIso8601String(),
      'summary': {
        'deck_count': deckCount,
        'card_count': cardCount,
      },
    };
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} min ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'BackupMetadata(id: $id, decks: $deckCount, cards: $cardCount, date: $formattedDate)';
}

/// Represents backup data including metadata and deck content
class BackupData {
  final BackupMetadata metadata;
  final Map<String, dynamic> data;

  const BackupData({
    required this.metadata,
    required this.data,
  });

  factory BackupData.fromJson(Map<String, dynamic> json, {String? fileId, int? fileSize}) {
    return BackupData(
      metadata: BackupMetadata.fromJson(json, fileId: fileId, size: fileSize),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...metadata.toJson(),
      'data': data,
    };
  }
}
