import '../constants/app_constants.dart';
import '../../data/models/card_srs_state.dart';

abstract class SchedulerEngine {
  ReviewResult review(CardSrsState state, ReviewRating rating, DateTime now);
}

/// SM-2 Spaced Repetition Algorithm Implementation
///
/// Quality ratings:
/// 0 - Complete blackout, total failure to recall
/// 1 - Incorrect response, but upon seeing correct answer, remembered
/// 2 - Incorrect response, but correct answer seemed easy to recall
/// 3 - Correct response with serious difficulty
/// 4 - Correct response after some hesitation
/// 5 - Perfect response
class SM2Scheduler implements SchedulerEngine {
  const SM2Scheduler();

  @override
  ReviewResult review(CardSrsState state, ReviewRating rating, DateTime now) {
    return calculate(
      quality: buttonToQuality(rating),
      repetitions: state.repetitions,
      lapses: state.lapses,
      easinessFactor: state.easinessFactor,
      interval: state.interval,
      now: now,
    );
  }

  /// Calculate the next review based on the quality of the response
  /// Returns a [ReviewResult] containing the new interval, repetitions, and easiness factor
  static ReviewResult calculate({
    required int quality,
    required int repetitions,
    required int lapses,
    required double easinessFactor,
    required int interval,
    DateTime? now,
  }) {
    // Clamp quality to valid range
    quality = quality.clamp(0, 5);
    final reviewTime = now ?? DateTime.now();

    double newEF = easinessFactor;
    int newInterval;
    int newRepetitions;
    int newLapses = lapses;

    if (quality < 3) {
      // Failed recall: make it due immediately and lower ease slightly.
      newRepetitions = 0;
      newInterval = 0;
      newLapses += 1;
      newEF = (easinessFactor - 0.2).clamp(
        AppConstants.minEasinessFactor,
        double.infinity,
      );
    } else if (quality == AppConstants.ratingHard) {
      // Hard recall should not multiply mature intervals too aggressively.
      newRepetitions = repetitions + 1;
      if (repetitions == 0) {
        newInterval = AppConstants.initialInterval;
      } else {
        newInterval = (interval * 1.2).ceil();
        // Ensure interval always increases
        if (newInterval <= interval && interval > 0) {
          newInterval = interval + 1;
        }
        newInterval = newInterval.clamp(
          AppConstants.initialInterval,
          36500,
        );
      }
      newEF = (easinessFactor - 0.15).clamp(
        AppConstants.minEasinessFactor,
        double.infinity,
      );
    } else {
      // Successful recall
      newRepetitions = repetitions + 1;

      if (quality == AppConstants.ratingEasy && repetitions == 0) {
        newInterval = AppConstants.secondInterval;
        newRepetitions = 2; // Jump ahead so next review doesn't stall at secondInterval
      } else if (newRepetitions == 1) {
        newInterval = AppConstants.initialInterval;
      } else if (newRepetitions == 2) {
        newInterval = AppConstants.secondInterval;
      } else {
        final easyBonus = quality == AppConstants.ratingEasy ? 1.3 : 1.0;
        newInterval = (interval * easinessFactor * easyBonus).round();
      }

      // Update easiness factor
      newEF = easinessFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

      // Ensure EF doesn't go below minimum
      if (newEF < AppConstants.minEasinessFactor) {
        newEF = AppConstants.minEasinessFactor;
      }
    }

    return ReviewResult(
      interval: newInterval,
      repetitions: newRepetitions,
      lapses: newLapses,
      easinessFactor: newEF,
      nextReviewDate: reviewTime.add(Duration(days: newInterval)),
    );
  }

  /// Convert button rating (Again, Hard, Good, Easy) to SM-2 quality
  static int buttonToQuality(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.again:
        return AppConstants.ratingAgain;
      case ReviewRating.hard:
        return AppConstants.ratingHard;
      case ReviewRating.good:
        return AppConstants.ratingGood;
      case ReviewRating.easy:
        return AppConstants.ratingEasy;
    }
  }

  /// Get preview of next review intervals for each rating option
  static Map<ReviewRating, int> getIntervalPreviews({
    required int repetitions,
    required int lapses,
    required double easinessFactor,
    required int interval,
  }) {
    return {
      for (final rating in ReviewRating.values)
        rating: calculate(
          quality: buttonToQuality(rating),
          repetitions: repetitions,
          lapses: lapses,
          easinessFactor: easinessFactor,
          interval: interval,
        ).interval,
    };
  }
}

/// Rating buttons for study session
enum ReviewRating {
  again,
  hard,
  good,
  easy;

  String get label {
    switch (this) {
      case ReviewRating.again:
        return 'Again';
      case ReviewRating.hard:
        return 'Hard';
      case ReviewRating.good:
        return 'Good';
      case ReviewRating.easy:
        return 'Easy';
    }
  }

  String get labelVi {
    switch (this) {
      case ReviewRating.again:
        return 'Lại';
      case ReviewRating.hard:
        return 'Khó';
      case ReviewRating.good:
        return 'Tốt';
      case ReviewRating.easy:
        return 'Dễ';
    }
  }
}

/// Result of SM-2 calculation
class ReviewResult {
  final int interval;
  final int repetitions;
  final int lapses;
  final double easinessFactor;
  final double? stability;
  final double? difficulty;
  final int? fsrsState;
  final int? fsrsStep;
  final DateTime nextReviewDate;

  const ReviewResult({
    required this.interval,
    required this.repetitions,
    required this.lapses,
    required this.easinessFactor,
    this.stability,
    this.difficulty,
    this.fsrsState,
    this.fsrsStep,
    required this.nextReviewDate,
  });

  @override
  String toString() {
    return 'ReviewResult(interval: $interval days, reps: $repetitions, lapses: $lapses, EF: ${easinessFactor.toStringAsFixed(2)}, stability: $stability, difficulty: $difficulty, fsrsState: $fsrsState, fsrsStep: $fsrsStep, next: $nextReviewDate)';
  }
}
