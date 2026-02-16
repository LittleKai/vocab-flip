import 'package:cloud_firestore/cloud_firestore.dart';
import 'flashcard.dart';

/// Model for a flashcard in a public deck
class PublicFlashcard {
  final String id;
  final String publicDeckId;
  final String front;
  final String? frontPhonetic;
  final String back;
  final String? example;
  final String? notes;
  final List<String> tags;
  final int order;
  final String? frontImageUrl;
  final String? backImageUrl;
  final bool shareImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  PublicFlashcard({
    required this.id,
    required this.publicDeckId,
    required this.front,
    this.frontPhonetic,
    required this.back,
    this.example,
    this.notes,
    List<String>? tags,
    this.order = 0,
    this.frontImageUrl,
    this.backImageUrl,
    this.shareImage = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  PublicFlashcard copyWith({
    String? id,
    String? publicDeckId,
    String? front,
    String? frontPhonetic,
    String? back,
    String? example,
    String? notes,
    List<String>? tags,
    int? order,
    String? frontImageUrl,
    String? backImageUrl,
    bool? shareImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PublicFlashcard(
      id: id ?? this.id,
      publicDeckId: publicDeckId ?? this.publicDeckId,
      front: front ?? this.front,
      frontPhonetic: frontPhonetic ?? this.frontPhonetic,
      back: back ?? this.back,
      example: example ?? this.example,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      order: order ?? this.order,
      frontImageUrl: frontImageUrl ?? this.frontImageUrl,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      shareImage: shareImage ?? this.shareImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to a local Flashcard for online browsing
  Flashcard toFlashcard() => Flashcard(
    id: id,
    deckId: publicDeckId,
    front: front,
    frontPhonetic: frontPhonetic,
    back: back,
    example: example,
    notes: notes,
    frontImageUrl: frontImageUrl,
    backImageUrl: backImageUrl,
    shareImage: shareImage,
    tags: tags,
  );

  Map<String, dynamic> toFirestore() {
    return {
      'public_deck_id': publicDeckId,
      'front': front,
      'front_phonetic': frontPhonetic,
      'back': back,
      'example': example,
      'notes': notes,
      'tags': tags,
      'order': order,
      'front_image_url': frontImageUrl,
      'back_image_url': backImageUrl,
      'share_image': shareImage,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory PublicFlashcard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PublicFlashcard(
      id: doc.id,
      publicDeckId: data['public_deck_id'] as String,
      front: data['front'] as String,
      frontPhonetic: data['front_phonetic'] as String?,
      back: data['back'] as String,
      example: data['example'] as String?,
      notes: data['notes'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      order: data['order'] as int? ?? 0,
      frontImageUrl: data['front_image_url'] as String?,
      backImageUrl: data['back_image_url'] as String?,
      shareImage: data['share_image'] as bool? ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create from REST API response (Map with parsed values)
  factory PublicFlashcard.fromMap(Map<String, dynamic> data) {
    return PublicFlashcard(
      id: data['id'] as String? ?? '',
      publicDeckId: data['public_deck_id'] as String? ?? '',
      front: data['front'] as String? ?? '',
      frontPhonetic: data['front_phonetic'] as String?,
      back: data['back'] as String? ?? '',
      example: data['example'] as String?,
      notes: data['notes'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      order: data['order'] as int? ?? 0,
      frontImageUrl: data['front_image_url'] as String?,
      backImageUrl: data['back_image_url'] as String?,
      shareImage: data['share_image'] as bool? ?? true,
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  String toString() => 'PublicFlashcard(id: $id, front: $front)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PublicFlashcard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
