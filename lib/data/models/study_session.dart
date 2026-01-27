import 'package:uuid/uuid.dart';

class StudySession {
  final String id;
  final String deckId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int cardsStudied;
  final int cardsCorrect;
  final int cardsIncorrect;
  final int totalTimeSeconds;

  StudySession({
    String? id,
    required this.deckId,
    DateTime? startedAt,
    this.endedAt,
    this.cardsStudied = 0,
    this.cardsCorrect = 0,
    this.cardsIncorrect = 0,
    this.totalTimeSeconds = 0,
  })  : id = id ?? const Uuid().v4(),
        startedAt = startedAt ?? DateTime.now();

  /// Calculate accuracy percentage
  double get accuracy {
    if (cardsStudied == 0) return 0;
    return (cardsCorrect / cardsStudied) * 100;
  }

  /// Check if session is complete
  bool get isComplete => endedAt != null;

  /// Get session duration
  Duration get duration {
    if (endedAt != null) {
      return endedAt!.difference(startedAt);
    }
    return DateTime.now().difference(startedAt);
  }

  StudySession copyWith({
    String? id,
    String? deckId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? cardsStudied,
    int? cardsCorrect,
    int? cardsIncorrect,
    int? totalTimeSeconds,
  }) {
    return StudySession(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      cardsCorrect: cardsCorrect ?? this.cardsCorrect,
      cardsIncorrect: cardsIncorrect ?? this.cardsIncorrect,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'cards_studied': cardsStudied,
      'cards_correct': cardsCorrect,
      'cards_incorrect': cardsIncorrect,
      'total_time_seconds': totalTimeSeconds,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      cardsStudied: map['cards_studied'] as int? ?? 0,
      cardsCorrect: map['cards_correct'] as int? ?? 0,
      cardsIncorrect: map['cards_incorrect'] as int? ?? 0,
      totalTimeSeconds: map['total_time_seconds'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'StudySession(id: $id, deck: $deckId, cards: $cardsStudied, accuracy: ${accuracy.toStringAsFixed(1)}%)';
  }
}
