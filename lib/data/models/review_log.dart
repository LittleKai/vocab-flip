import 'package:uuid/uuid.dart';

class ReviewLog {
  final String id;
  final String flashcardId;
  final String sessionId;
  final DateTime reviewedAt;
  final int quality;
  final int responseTimeMs;
  final double easinessFactorBefore;
  final double easinessFactorAfter;
  final int intervalBefore;
  final int intervalAfter;

  ReviewLog({
    String? id,
    required this.flashcardId,
    required this.sessionId,
    DateTime? reviewedAt,
    required this.quality,
    this.responseTimeMs = 0,
    required this.easinessFactorBefore,
    required this.easinessFactorAfter,
    required this.intervalBefore,
    required this.intervalAfter,
  })  : id = id ?? const Uuid().v4(),
        reviewedAt = reviewedAt ?? DateTime.now();

  /// Check if the review was successful (quality >= 3)
  bool get isCorrect => quality >= 3;

  /// Get the interval change
  int get intervalChange => intervalAfter - intervalBefore;

  ReviewLog copyWith({
    String? id,
    String? flashcardId,
    String? sessionId,
    DateTime? reviewedAt,
    int? quality,
    int? responseTimeMs,
    double? easinessFactorBefore,
    double? easinessFactorAfter,
    int? intervalBefore,
    int? intervalAfter,
  }) {
    return ReviewLog(
      id: id ?? this.id,
      flashcardId: flashcardId ?? this.flashcardId,
      sessionId: sessionId ?? this.sessionId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      quality: quality ?? this.quality,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      easinessFactorBefore: easinessFactorBefore ?? this.easinessFactorBefore,
      easinessFactorAfter: easinessFactorAfter ?? this.easinessFactorAfter,
      intervalBefore: intervalBefore ?? this.intervalBefore,
      intervalAfter: intervalAfter ?? this.intervalAfter,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flashcard_id': flashcardId,
      'session_id': sessionId,
      'reviewed_at': reviewedAt.toIso8601String(),
      'quality': quality,
      'response_time_ms': responseTimeMs,
      'easiness_factor_before': easinessFactorBefore,
      'easiness_factor_after': easinessFactorAfter,
      'interval_before': intervalBefore,
      'interval_after': intervalAfter,
    };
  }

  factory ReviewLog.fromMap(Map<String, dynamic> map) {
    return ReviewLog(
      id: map['id'] as String,
      flashcardId: map['flashcard_id'] as String,
      sessionId: map['session_id'] as String,
      reviewedAt: DateTime.parse(map['reviewed_at'] as String),
      quality: map['quality'] as int,
      responseTimeMs: map['response_time_ms'] as int? ?? 0,
      easinessFactorBefore: (map['easiness_factor_before'] as num).toDouble(),
      easinessFactorAfter: (map['easiness_factor_after'] as num).toDouble(),
      intervalBefore: map['interval_before'] as int,
      intervalAfter: map['interval_after'] as int,
    );
  }

  @override
  String toString() {
    return 'ReviewLog(id: $id, card: $flashcardId, quality: $quality)';
  }
}
