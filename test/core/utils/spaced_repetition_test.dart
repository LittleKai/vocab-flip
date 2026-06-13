import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/core/constants/app_constants.dart';
import 'package:vocabflip/core/utils/spaced_repetition.dart';

void main() {
  group('SM2Scheduler', () {
    final now = DateTime(2026, 5, 29, 9);

    test('again makes the card due immediately and reduces ease', () {
      final result = SM2Scheduler.calculate(
        quality: SM2Scheduler.buttonToQuality(ReviewRating.again),
        repetitions: 4,
        lapses: 0,
        easinessFactor: 2.5,
        interval: 20,
        now: now,
      );

      expect(result.interval, 0);
      expect(result.repetitions, 0);
      expect(result.lapses, 1);
      expect(result.easinessFactor, closeTo(2.3, 0.001));
      expect(result.nextReviewDate, now);
    });

    test('hard review grows a mature interval conservatively', () {
      final result = SM2Scheduler.calculate(
        quality: SM2Scheduler.buttonToQuality(ReviewRating.hard),
        repetitions: 5,
        lapses: 1,
        easinessFactor: 2.5,
        interval: 30,
        now: now,
      );

      expect(result.interval, 36);
      expect(result.repetitions, 6);
      expect(result.lapses, 1);
      expect(result.easinessFactor, closeTo(2.35, 0.001));
      expect(result.nextReviewDate, now.add(const Duration(days: 36)));
    });

    test('easy graduates a new card faster than good', () {
      final good = SM2Scheduler.calculate(
        quality: SM2Scheduler.buttonToQuality(ReviewRating.good),
        repetitions: 0,
        lapses: 0,
        easinessFactor: AppConstants.defaultEasinessFactor,
        interval: 0,
        now: now,
      );
      final easy = SM2Scheduler.calculate(
        quality: SM2Scheduler.buttonToQuality(ReviewRating.easy),
        repetitions: 0,
        lapses: 0,
        easinessFactor: AppConstants.defaultEasinessFactor,
        interval: 0,
        now: now,
      );

      expect(good.interval, AppConstants.initialInterval);
      expect(easy.interval, AppConstants.secondInterval);
      expect(easy.easinessFactor, greaterThan(good.easinessFactor));
    });
  });
}
