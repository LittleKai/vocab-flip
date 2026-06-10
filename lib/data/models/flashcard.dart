import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import 'card_srs_state.dart';

class Flashcard {
  final String id;
  final String deckId;
  final String front;
  final String? frontPhonetic;
  final String back;
  final String? example;
  final String? notes;
  final String? imageUrl; // Legacy field - maps to frontImageUrl
  final String? frontImageUrl; // URL or local file path for front image
  final String? backImageUrl; // URL or local file path for back image
  final bool shareImage; // If true, show frontImageUrl on both sides
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Review data (SM-2)
  final CardSrsState srsState;

  // Getters for backwards compatibility
  double get easinessFactor => srsState.easinessFactor;
  int get interval => srsState.interval;
  int get repetitions => srsState.repetitions;
  DateTime? get nextReviewDate => srsState.nextReviewDate;
  DateTime? get lastReviewDate => srsState.lastReviewDate;
  int get lapses => srsState.lapses;
  double? get stability => srsState.stability;
  double? get difficulty => srsState.difficulty;
  int? get fsrsState => srsState.fsrsState;
  int? get fsrsStep => srsState.fsrsStep;

  Flashcard({
    String? id,
    required this.deckId,
    required this.front,
    this.frontPhonetic,
    required this.back,
    this.example,
    this.notes,
    this.imageUrl,
    this.frontImageUrl,
    this.backImageUrl,
    this.shareImage = true, // Default: share image on both sides
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    CardSrsState? srsState,
    double? easinessFactor,
    int? interval,
    int? repetitions,
    int? lapses,
    double? stability,
    double? difficulty,
    int? fsrsState,
    int? fsrsStep,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        srsState = srsState ??
            CardSrsState(
              easinessFactor: easinessFactor ?? AppConstants.defaultEasinessFactor,
              interval: interval ?? 0,
              repetitions: repetitions ?? 0,
              lapses: lapses ?? 0,
              stability: stability,
              difficulty: difficulty,
              fsrsState: fsrsState,
              fsrsStep: fsrsStep,
              nextReviewDate: nextReviewDate,
              lastReviewDate: lastReviewDate,
            );

  /// Check if legacy image is a URL (http/https)
  bool get isImageUrl => imageUrl != null &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  /// Check if legacy image is a local file
  bool get isLocalImage => imageUrl != null && !isImageUrl;

  /// Check if this card has a legacy image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Get the effective front image URL (frontImageUrl or legacy imageUrl)
  String? get effectiveFrontImageUrl => frontImageUrl ?? imageUrl;

  /// Get the effective back image URL (backImageUrl, or frontImageUrl if shareImage is true)
  String? get effectiveBackImageUrl =>
      backImageUrl ?? (shareImage ? effectiveFrontImageUrl : null);

  /// Check if front has an image
  bool get hasFrontImage => effectiveFrontImageUrl != null && effectiveFrontImageUrl!.isNotEmpty;

  /// Check if back has an image
  bool get hasBackImage => effectiveBackImageUrl != null && effectiveBackImageUrl!.isNotEmpty;

  /// Check if front image is a URL
  bool get isFrontImageUrl => hasFrontImage &&
      (effectiveFrontImageUrl!.startsWith('http://') || effectiveFrontImageUrl!.startsWith('https://'));

  /// Check if back image is a URL
  bool get isBackImageUrl => hasBackImage &&
      (effectiveBackImageUrl!.startsWith('http://') || effectiveBackImageUrl!.startsWith('https://'));

  /// Check if this card is due for review
  bool get isDue {
    if (nextReviewDate == null) return true;
    return DateTime.now().isAfter(nextReviewDate!);
  }

  /// Check if this card is new (never reviewed)
  bool get isNew => repetitions == 0;

  /// Check if this card is learning (reviewed but not yet graduated)
  bool get isLearning => repetitions > 0 && repetitions < 3;

  /// Check if this card has graduated (successfully reviewed multiple times)
  bool get isGraduated => repetitions >= 3;

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? frontPhonetic,
    String? back,
    String? example,
    String? notes,
    String? imageUrl,
    String? frontImageUrl,
    String? backImageUrl,
    bool? shareImage,
    bool clearImage = false,
    bool clearFrontImage = false,
    bool clearBackImage = false,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    CardSrsState? srsState,
    double? easinessFactor,
    int? interval,
    int? repetitions,
    int? lapses,
    double? stability,
    double? difficulty,
    int? fsrsState,
    int? fsrsStep,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
  }) {
    final mergedSrsState = srsState ?? this.srsState.copyWith(
      easinessFactor: easinessFactor,
      interval: interval,
      repetitions: repetitions,
      lapses: lapses,
      stability: stability,
      difficulty: difficulty,
      nextReviewDate: nextReviewDate,
      lastReviewDate: lastReviewDate,
    );

    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      frontPhonetic: frontPhonetic ?? this.frontPhonetic,
      back: back ?? this.back,
      example: example ?? this.example,
      notes: notes ?? this.notes,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      frontImageUrl: clearFrontImage ? null : (frontImageUrl ?? this.frontImageUrl),
      backImageUrl: clearBackImage ? null : (backImageUrl ?? this.backImageUrl),
      shareImage: shareImage ?? this.shareImage,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      srsState: mergedSrsState,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'front': front,
      'front_phonetic': frontPhonetic,
      'back': back,
      'example': example,
      'notes': notes,
      'image_url': imageUrl,
      'front_image_url': frontImageUrl,
      'back_image_url': backImageUrl,
      'share_image': shareImage ? 1 : 0,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'easiness_factor': easinessFactor,
      'interval': interval,
      'repetitions': repetitions,
      'lapses': lapses,
      'stability': srsState.stability,
      'difficulty': srsState.difficulty,
      'fsrs_state': srsState.fsrsState,
      'fsrs_step': srsState.fsrsStep,
      'next_review_date': nextReviewDate?.toIso8601String(),
      'last_review_date': lastReviewDate?.toIso8601String(),
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      front: map['front'] as String,
      frontPhonetic: map['front_phonetic'] as String?,
      back: map['back'] as String,
      example: map['example'] as String?,
      notes: map['notes'] as String?,
      imageUrl: map['image_url'] as String?,
      frontImageUrl: map['front_image_url'] as String?,
      backImageUrl: map['back_image_url'] as String?,
      shareImage: map['share_image'] == null ? true : (map['share_image'] as int) == 1,
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      easinessFactor: (map['easiness_factor'] as num?)?.toDouble() ?? AppConstants.defaultEasinessFactor,
      interval: map['interval'] as int? ?? 0,
      repetitions: map['repetitions'] as int? ?? 0,
      srsState: CardSrsState(
        easinessFactor: (map['easiness_factor'] as num?)?.toDouble() ?? AppConstants.defaultEasinessFactor,
        interval: map['interval'] as int? ?? 0,
        repetitions: map['repetitions'] as int? ?? 0,
        lapses: map['lapses'] as int? ?? 0,
        stability: (map['stability'] as num?)?.toDouble(),
        difficulty: (map['difficulty'] as num?)?.toDouble(),
        fsrsState: map['fsrs_state'] as int?,
        fsrsStep: map['fsrs_step'] as int?,
        nextReviewDate: map['next_review_date'] != null
            ? DateTime.parse(map['next_review_date'] as String)
            : null,
        lastReviewDate: map['last_review_date'] != null
            ? DateTime.parse(map['last_review_date'] as String)
            : null,
      ),
      nextReviewDate: map['next_review_date'] != null
          ? DateTime.parse(map['next_review_date'] as String)
          : null,
      lastReviewDate: map['last_review_date'] != null
          ? DateTime.parse(map['last_review_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'front_phonetic': frontPhonetic,
      'back': back,
      'examples': example != null ? [example] : [],
      'image_url': imageUrl,
      'front_image_url': frontImageUrl,
      'back_image_url': backImageUrl,
      'share_image': shareImage,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'review_data': {
        'easiness_factor': easinessFactor,
        'interval': interval,
        'repetitions': repetitions,
        'lapses': lapses,
        'stability': stability,
        'difficulty': difficulty,
        'fsrs_state': fsrsState,
        'fsrs_step': fsrsStep,
        'next_review': nextReviewDate?.toIso8601String(),
      },
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json, String deckId) {
    final reviewData = json['review_data'] as Map<String, dynamic>? ?? {};
    final examples = json['examples'] as List<dynamic>? ?? [];

    return Flashcard(
      id: json['id'] as String?,
      deckId: deckId,
      front: json['front'] as String,
      frontPhonetic: json['front_phonetic'] as String?,
      back: json['back'] as String,
      example: examples.isNotEmpty ? examples.first as String : null,
      notes: json['notes'] as String?,
      imageUrl: json['image_url'] as String?,
      frontImageUrl: json['front_image_url'] as String?,
      backImageUrl: json['back_image_url'] as String?,
      shareImage: json['share_image'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      easinessFactor: (reviewData['easiness_factor'] as num?)?.toDouble() ??
          AppConstants.defaultEasinessFactor,
      interval: reviewData['interval'] as int? ?? 0,
      repetitions: reviewData['repetitions'] as int? ?? 0,
      srsState: CardSrsState(
        easinessFactor: (reviewData['easiness_factor'] as num?)?.toDouble() ?? AppConstants.defaultEasinessFactor,
        interval: reviewData['interval'] as int? ?? 0,
        repetitions: reviewData['repetitions'] as int? ?? 0,
        lapses: reviewData['lapses'] as int? ?? 0,
        stability: (reviewData['stability'] as num?)?.toDouble(),
        difficulty: (reviewData['difficulty'] as num?)?.toDouble(),
        fsrsState: reviewData['fsrs_state'] as int?,
        fsrsStep: reviewData['fsrs_step'] as int?,
        nextReviewDate: reviewData['next_review'] != null
            ? DateTime.parse(reviewData['next_review'] as String)
            : null,
        lastReviewDate: null, // Depending on if it's stored
      ),
      nextReviewDate: reviewData['next_review'] != null
          ? DateTime.parse(reviewData['next_review'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Flashcard(id: $id, front: $front, back: $back)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Flashcard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
