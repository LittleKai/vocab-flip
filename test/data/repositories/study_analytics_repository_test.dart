import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/repositories/study_analytics_repository.dart';

void main() {
  group('DailyStudyActivity', () {
    test('calculates accuracy from studied and correct cards', () {
      final activity = DailyStudyActivity(
        day: DateTime(2026, 5, 29),
        cardsStudied: 10,
        cardsCorrect: 7,
        cardsIncorrect: 3,
        totalTimeSeconds: 120,
      );

      expect(activity.accuracy, 70);
    });

    test('returns zero accuracy when no cards were studied', () {
      final activity = DailyStudyActivity(
        day: DateTime(2026, 5, 29),
        cardsStudied: 0,
        cardsCorrect: 0,
        cardsIncorrect: 0,
        totalTimeSeconds: 0,
      );

      expect(activity.accuracy, 0);
    });
  });
}
