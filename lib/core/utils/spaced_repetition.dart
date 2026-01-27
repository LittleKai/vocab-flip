import '../constants/app_constants.dart';

/// SM-2 Spaced Repetition Algorithm Implementation
///
/// Quality ratings:
/// 0 - Complete blackout, total failure to recall
/// 1 - Incorrect response, but upon seeing correct answer, remembered
/// 2 - Incorrect response, but correct answer seemed easy to recall
/// 3 - Correct response with serious difficulty
/// 4 - Correct response after some hesitation
/// 5 - Perfect response
class SM2Algorithm {
  SM2Algorithm._();

  /// Calculate the next review based on the quality of the response
  /// Returns a [ReviewResult] containing the new interval, repetitions, and easiness factor
  static ReviewResult calculate({
    required int quality,
    required int repetitions,
    required double easinessFactor,
    required int interval,
  }) {
    // Clamp quality to valid range
    quality = quality.clamp(0, 5);

    double newEF = easinessFactor;
    int newInterval;
    int newRepetitions;

    if (quality < 3) {
      // Failed recall - reset to beginning
      newRepetitions = 0;
      newInterval = AppConstants.initialInterval;
    } else {
      // Successful recall
      newRepetitions = repetitions + 1;

      if (newRepetitions == 1) {
        newInterval = AppConstants.initialInterval;
      } else if (newRepetitions == 2) {
        newInterval = AppConstants.secondInterval;
      } else {
        newInterval = (interval * easinessFactor).round();
      }

      // Update easiness factor
      newEF = easinessFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

      // Ensure EF doesn't go below minimum
      if (newEF < AppConstants.minEasinessFactor) {
        newEF = AppConstants.minEasinessFactor;
      }
    }

    return ReviewResult(
      interval: newInterval,
      repetitions: newRepetitions,
      easinessFactor: newEF,
      nextReviewDate: DateTime.now().add(Duration(days: newInterval)),
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
    required double easinessFactor,
    required int interval,
  }) {
    return {
      for (final rating in ReviewRating.values)
        rating: calculate(
          quality: buttonToQuality(rating),
          repetitions: repetitions,
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
  final double easinessFactor;
  final DateTime nextReviewDate;

  const ReviewResult({
    required this.interval,
    required this.repetitions,
    required this.easinessFactor,
    required this.nextReviewDate,
  });

  @override
  String toString() {
    return 'ReviewResult(interval: $interval days, reps: $repetitions, EF: ${easinessFactor.toStringAsFixed(2)}, next: $nextReviewDate)';
  }
}
