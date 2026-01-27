import 'package:uuid/uuid.dart';
import '../../core/constants/supported_languages.dart';
import 'flashcard.dart';

class Deck {
  final String id;
  final String name;
  final String? description;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int cardCount;
  final int newCount;
  final int learningCount;
  final int reviewCount;

  // Public library linking fields
  final String? linkedPublicDeckId; // ID of source public deck if imported
  final int? linkedVersion; // Version when last synced
  final bool isPublished; // Whether this deck is published to library
  final String? publishedDeckId; // ID on public library if published

  Deck({
    String? id,
    required this.name,
    this.description,
    required this.sourceLanguage,
    this.targetLanguage = 'vi',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.cardCount = 0,
    this.newCount = 0,
    this.learningCount = 0,
    this.reviewCount = 0,
    this.linkedPublicDeckId,
    this.linkedVersion,
    this.isPublished = false,
    this.publishedDeckId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  SupportedLanguage get sourceLang => SupportedLanguage.fromCode(sourceLanguage);
  SupportedLanguage get targetLang => SupportedLanguage.fromCode(targetLanguage);

  /// Total cards due for review today
  int get dueCount => reviewCount + newCount;

  /// Check if deck is empty
  bool get isEmpty => cardCount == 0;

  /// Check if deck has cards to study
  bool get hasCardsToStudy => dueCount > 0;

  /// Check if this deck is linked to a public deck (imported from library)
  bool get isLinked => linkedPublicDeckId != null;

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cardCount,
    int? newCount,
    int? learningCount,
    int? reviewCount,
    String? linkedPublicDeckId,
    int? linkedVersion,
    bool? isPublished,
    String? publishedDeckId,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      cardCount: cardCount ?? this.cardCount,
      newCount: newCount ?? this.newCount,
      learningCount: learningCount ?? this.learningCount,
      reviewCount: reviewCount ?? this.reviewCount,
      linkedPublicDeckId: linkedPublicDeckId ?? this.linkedPublicDeckId,
      linkedVersion: linkedVersion ?? this.linkedVersion,
      isPublished: isPublished ?? this.isPublished,
      publishedDeckId: publishedDeckId ?? this.publishedDeckId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'linked_public_deck_id': linkedPublicDeckId,
      'linked_version': linkedVersion,
      'is_published': isPublished ? 1 : 0,
      'published_deck_id': publishedDeckId,
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map, {
    int cardCount = 0,
    int newCount = 0,
    int learningCount = 0,
    int reviewCount = 0,
  }) {
    return Deck(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      sourceLanguage: map['source_language'] as String,
      targetLanguage: map['target_language'] as String? ?? 'vi',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      cardCount: cardCount,
      newCount: newCount,
      learningCount: learningCount,
      reviewCount: reviewCount,
      linkedPublicDeckId: map['linked_public_deck_id'] as String?,
      linkedVersion: map['linked_version'] as int?,
      isPublished: (map['is_published'] as int?) == 1,
      publishedDeckId: map['published_deck_id'] as String?,
    );
  }

  Map<String, dynamic> toJson(List<Flashcard> cards) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      sourceLanguage: json['source_language'] as String,
      targetLanguage: json['target_language'] as String? ?? 'vi',
    );
  }

  @override
  String toString() {
    return 'Deck(id: $id, name: $name, cards: $cardCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deck && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
