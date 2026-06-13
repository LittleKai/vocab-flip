import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/core/utils/spaced_repetition.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/data/repositories/stroke_data_repository.dart';
import 'package:vocabflip/data/services/stroke_validation_service.dart';
import 'package:vocabflip/presentation/providers/stroke_practice_provider.dart';

class MockStrokeDataRepository implements StrokeDataRepository {
  final StrokeCharacter? fixture;

  MockStrokeDataRepository(this.fixture);

  @override
  Future<StrokeCharacter?> lookupCharacter(
      String character, String sourceLanguage) async {
    return fixture;
  }

  @override
  Future<bool> hasStrokeData(String character, String sourceLanguage) async {
    return fixture != null;
  }
}

class MockValidationService implements StrokeValidationService {
  StrokeValidationResult? nextResult;

  @override
  StrokeValidationResult validateStroke({
    required List<Offset> userPoints,
    required int expectedIndex,
    required StrokeCharacter character,
  }) {
    return nextResult ??
        const StrokeValidationResult.reject(StrokeRejection.tooShort);
  }
}

void main() {
  group('StrokePracticeProvider', () {
    late MockStrokeDataRepository repository;
    late MockValidationService validationService;
    late StrokePracticeProvider provider;
    late StrokeCharacter testCharacter;

    setUp(() {
      testCharacter = const StrokeCharacter(
        character: '一',
        locale: 'zh',
        source: 'test',
        viewBox: [0, 0, 1024, 1024],
        strokes: [
          StrokeData(
            index: 0,
            path: 'M0,0 L100,100',
            median: [StrokePoint(100, 100), StrokePoint(200, 200)],
          )
        ],
      );
      repository = MockStrokeDataRepository(testCharacter);
      validationService = MockValidationService();
      provider = StrokePracticeProvider(
        repository: repository,
        validationService: validationService,
      );
    });

    test('loadForCard updates state correctly on success', () async {
      await provider.loadForCard(text: '一', sourceLanguage: 'zh');

      expect(provider.state, StrokePracticeState.ready);
      expect(provider.currentCharacter, testCharacter);
      expect(provider.activeStrokeIndex, 0);
      expect(provider.mistakeCount, 0);
      expect(provider.completedStrokeCount, 0);
    });

    test('loadForCard updates state correctly on failure', () async {
      repository = MockStrokeDataRepository(null);
      provider = StrokePracticeProvider(
          repository: repository, validationService: validationService);

      await provider.loadForCard(text: 'x', sourceLanguage: 'zh');

      expect(provider.state, StrokePracticeState.error);
      expect(provider.currentCharacter, isNull);
    });

    test('submitStroke accepts correct strokes and increments count', () async {
      await provider.loadForCard(text: '一', sourceLanguage: 'zh');
      validationService.nextResult = const StrokeValidationResult.accept(0.9);

      final result = await provider.submitStroke([const Offset(0, 0)]);

      expect(result.accepted, isTrue);
      expect(provider.activeStrokeIndex, 1);
      expect(provider.completedStrokeCount, 1);
      expect(provider.mistakeCount, 0);
    });

    test('submitStroke rejects incorrect strokes and increments mistakes',
        () async {
      await provider.loadForCard(text: '一', sourceLanguage: 'zh');
      validationService.nextResult =
          const StrokeValidationResult.reject(StrokeRejection.wrongDirection);

      final result = await provider.submitStroke([const Offset(0, 0)]);

      expect(result.accepted, isFalse);
      expect(provider.activeStrokeIndex, 0);
      expect(provider.completedStrokeCount, 0);
      expect(provider.mistakeCount, 1);
    });

    test('ratingForCompletion maps mistakes to ReviewRating', () async {
      await provider.loadForCard(text: '一', sourceLanguage: 'zh');

      // Complete the stroke (the character has 1 stroke)
      validationService.nextResult = const StrokeValidationResult.accept(0.9);
      await provider.submitStroke([const Offset(0, 0)]);

      // 0 mistakes -> easy
      expect(provider.ratingForCompletion(), ReviewRating.easy);

      // Reset and try again with 1 mistake
      provider.resetPractice();
      validationService.nextResult =
          const StrokeValidationResult.reject(StrokeRejection.wrongDirection);
      await provider.submitStroke([const Offset(0, 0)]); // mistake
      validationService.nextResult = const StrokeValidationResult.accept(0.9);
      await provider.submitStroke([const Offset(0, 0)]); // accept
      expect(
          provider.ratingForCompletion(), ReviewRating.good); // <= 2 mistakes

      // Try with 3 mistakes
      provider.resetPractice();
      validationService.nextResult =
          const StrokeValidationResult.reject(StrokeRejection.wrongDirection);
      await provider.submitStroke([const Offset(0, 0)]); // 1
      await provider.submitStroke([const Offset(0, 0)]); // 2
      await provider.submitStroke([const Offset(0, 0)]); // 3
      validationService.nextResult = const StrokeValidationResult.accept(0.9);
      await provider.submitStroke([const Offset(0, 0)]); // accept
      expect(
          provider.ratingForCompletion(), ReviewRating.hard); // <= 5 mistakes

      // Try with 6 mistakes
      provider.resetPractice();
      validationService.nextResult =
          const StrokeValidationResult.reject(StrokeRejection.wrongDirection);
      for (int i = 0; i < 6; i++) {
        await provider.submitStroke([const Offset(0, 0)]);
      }
      validationService.nextResult = const StrokeValidationResult.accept(0.9);
      await provider.submitStroke([const Offset(0, 0)]); // accept
      expect(
          provider.ratingForCompletion(), ReviewRating.again); // > 5 mistakes
    });

    test('ratingForCompletion returns again if incomplete', () async {
      await provider.loadForCard(text: '一', sourceLanguage: 'zh');
      // No strokes submitted
      expect(provider.ratingForCompletion(), ReviewRating.again);
    });
  });
}
