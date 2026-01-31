import 'package:uuid/uuid.dart';
import '../../core/constants/supported_languages.dart';
import 'flashcard.dart';

/// Field types for flashcard structure
enum CardFieldType {
  word,
  phonetic,
  meaning,
  example,
  notes;

  String get displayName {
    switch (this) {
      case CardFieldType.word:
        return 'Word';
      case CardFieldType.phonetic:
        return 'Phonetic';
      case CardFieldType.meaning:
        return 'Meaning';
      case CardFieldType.example:
        return 'Example';
      case CardFieldType.notes:
        return 'Notes';
    }
  }

  String get displayNameVi {
    switch (this) {
      case CardFieldType.word:
        return 'Từ vựng';
      case CardFieldType.phonetic:
        return 'Phiên âm';
      case CardFieldType.meaning:
        return 'Nghĩa';
      case CardFieldType.example:
        return 'Ví dụ';
      case CardFieldType.notes:
        return 'Ghi chú';
    }
  }
}

/// Image display mode for flashcards
enum ImageDisplayMode {
  none,    // No image
  both,    // Show on both sides
  front,   // Show on front only
  back;    // Show on back only

  String get displayName {
    switch (this) {
      case ImageDisplayMode.none:
        return 'No Image';
      case ImageDisplayMode.both:
        return 'Both Sides';
      case ImageDisplayMode.front:
        return 'Front Only';
      case ImageDisplayMode.back:
        return 'Back Only';
    }
  }

  String get displayNameVi {
    switch (this) {
      case ImageDisplayMode.none:
        return 'Không hiển thị';
      case ImageDisplayMode.both:
        return 'Cả hai mặt';
      case ImageDisplayMode.front:
        return 'Chỉ mặt trước';
      case ImageDisplayMode.back:
        return 'Chỉ mặt sau';
    }
  }
}

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

  // Display mode: show back first instead of front
  final bool showBackFirst;

  // Card structure configuration
  final List<CardFieldType> frontFields;
  final List<CardFieldType> backFields;
  final ImageDisplayMode imageDisplayMode;

  // TTS settings
  final bool autoPlayTtsOnFlip;

  // Default structure
  static const List<CardFieldType> defaultFrontFields = [CardFieldType.word, CardFieldType.phonetic];
  static const List<CardFieldType> defaultBackFields = [CardFieldType.meaning, CardFieldType.example, CardFieldType.notes];

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
    this.showBackFirst = false,
    List<CardFieldType>? frontFields,
    List<CardFieldType>? backFields,
    this.imageDisplayMode = ImageDisplayMode.both,
    this.autoPlayTtsOnFlip = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        frontFields = frontFields ?? defaultFrontFields,
        backFields = backFields ?? defaultBackFields;

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
    bool? showBackFirst,
    List<CardFieldType>? frontFields,
    List<CardFieldType>? backFields,
    ImageDisplayMode? imageDisplayMode,
    bool? autoPlayTtsOnFlip,
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
      showBackFirst: showBackFirst ?? this.showBackFirst,
      frontFields: frontFields ?? this.frontFields,
      backFields: backFields ?? this.backFields,
      imageDisplayMode: imageDisplayMode ?? this.imageDisplayMode,
      autoPlayTtsOnFlip: autoPlayTtsOnFlip ?? this.autoPlayTtsOnFlip,
    );
  }

  /// Helper to convert field list to string for database storage
  static String _fieldsToString(List<CardFieldType> fields) {
    return fields.map((f) => f.name).join(',');
  }

  /// Helper to convert string from database to field list
  static List<CardFieldType> _stringToFields(String? str, List<CardFieldType> defaultValue) {
    if (str == null || str.isEmpty) return defaultValue;
    try {
      return str.split(',').map((s) => CardFieldType.values.firstWhere((f) => f.name == s)).toList();
    } catch (_) {
      return defaultValue;
    }
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
      'show_back_first': showBackFirst ? 1 : 0,
      'front_fields': _fieldsToString(frontFields),
      'back_fields': _fieldsToString(backFields),
      'image_display_mode': imageDisplayMode.name,
      'auto_play_tts_on_flip': autoPlayTtsOnFlip ? 1 : 0,
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
      showBackFirst: (map['show_back_first'] as int?) == 1,
      frontFields: _stringToFields(map['front_fields'] as String?, defaultFrontFields),
      backFields: _stringToFields(map['back_fields'] as String?, defaultBackFields),
      imageDisplayMode: ImageDisplayMode.values.firstWhere(
        (m) => m.name == (map['image_display_mode'] as String?),
        orElse: () => ImageDisplayMode.both,
      ),
      autoPlayTtsOnFlip: (map['auto_play_tts_on_flip'] as int?) != 0,
    );
  }

  Map<String, dynamic> toJson(List<Flashcard> cards) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'show_back_first': showBackFirst,
      'front_fields': frontFields.map((f) => f.name).toList(),
      'back_fields': backFields.map((f) => f.name).toList(),
      'image_display_mode': imageDisplayMode.name,
      'auto_play_tts_on_flip': autoPlayTtsOnFlip,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    List<CardFieldType> parseFrontFields() {
      final list = json['front_fields'] as List<dynamic>?;
      if (list == null) return defaultFrontFields;
      try {
        return list.map((s) => CardFieldType.values.firstWhere((f) => f.name == s)).toList();
      } catch (_) {
        return defaultFrontFields;
      }
    }

    List<CardFieldType> parseBackFields() {
      final list = json['back_fields'] as List<dynamic>?;
      if (list == null) return defaultBackFields;
      try {
        return list.map((s) => CardFieldType.values.firstWhere((f) => f.name == s)).toList();
      } catch (_) {
        return defaultBackFields;
      }
    }

    return Deck(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      sourceLanguage: json['source_language'] as String,
      targetLanguage: json['target_language'] as String? ?? 'vi',
      showBackFirst: json['show_back_first'] as bool? ?? false,
      frontFields: parseFrontFields(),
      backFields: parseBackFields(),
      imageDisplayMode: ImageDisplayMode.values.firstWhere(
        (m) => m.name == (json['image_display_mode'] as String?),
        orElse: () => ImageDisplayMode.both,
      ),
      autoPlayTtsOnFlip: json['auto_play_tts_on_flip'] as bool? ?? true,
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
