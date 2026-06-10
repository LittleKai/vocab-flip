class SyncQueueItem {
  final String id;
  final String entityType; // 'deck', 'flashcard', 'study_session', etc.
  final String entityId;
  final String operation; // 'CREATE', 'UPDATE', 'DELETE'
  final String? payload; // JSON representation of the entity
  final DateTime createdAt;

  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      entityType: map['entity_type'],
      entityId: map['entity_id'],
      operation: map['operation'],
      payload: map['payload'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
