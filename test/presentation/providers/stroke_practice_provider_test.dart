import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/core/utils/spaced_repetition.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/data/repositories/stroke_data_repository.dart';
import 'package:vocabflip/data/services/stroke_validation_service.dart';
import 'package:vocabflip/presentation/providers/stroke_practice_provider.dart';

class MockStrokeDataRepository implements StrokeDataRepository {
  final Map<String, StrokeCharacter> fixtures;

  MockStrokeDataRepository(this.fixtures);

  @override
  Future<StrokeCharacter?> lookupCharacter(
      String character, String sourceLanguage) async {
    return fixtures[character];
  }

  @override
  Future<bool> hasStrokeData(String character, String sourceLanguage) async {
    return fixtures.containsKey(character);
  }
}

class MockValidationService implements StrokeValidationService {
  StrokeValidationResult? nextResult;
  StrokeValidationProfile? lastProfile;

  @override
  StrokeValidationResult validateStroke({
    required List<Offset> userPoints,
    required int expectedIndex,
    required StrokeCharacter character,
    StrokeValidationProfile profile = StrokeValidationProfile.standard,
  }) {
    lastProfile = profile;
    return nextResult ??
        const StrokeValidationResult.reject(StrokeRejection.tooShort);
  }
}

void main() {
  group('StrokePracticeProvider', () {
    late MockStrokeDataRepository repository;
    late MockValidationService validationService;
    late StrokePracticeProvider provider;
    late StrokeCharacter char1;
    late StrokeCharacter char2;

    setUp(() {
      char1 = const StrokeCharacter(
        character: '日',
        locale: 'ja',
        source: 'test',
        viewBox: [0, 0, 1024, 1024],
        strokes: [
          StrokeData(
              index: 0, path: 'M0,0 L100,100', median: [StrokePoint(100, 100)]),
        ],
      );
      char2 = const StrokeCharacter(
        character: '本',
        locale: 'ja',
        source: 'test',
        viewBox: [0, 0, 1024, 1024],
        strokes: [
          StrokeData(
              index: 0, path: 'M0,0 L100,100', median: [StrokePoint(100, 100)]),
        ],
      );
      repository = MockStrokeDataRepository({'日': char1, '本': char2});
      validationService = MockValidationService();
      provider = StrokePracticeProvider(
        repository: repository,
        validationService: validationService,
      );
    });

    test('loadForCard(text: 日本) loads two targets', () async {
      await provider.loadForCard(text: '日本', sourceLanguage: 'ja');

      expect(provider.state, StrokePracticeState.ready);
      expect(provider.currentCharacter, char1);
      expect(provider.supportedCharacterCount, 2);
      expect(provider.unsupportedCharacterCount, 0);
    });

    test(
        'completing all strokes for the first target advances activeCharacterIndex',
        () async {
      await provider.loadForCard(text: '日本', sourceLanguage: 'ja');
      validationService.nextResult = const StrokeValidationResult.accept(0.9);

      await provider.submitStroke([const Offset(0, 0)]);

      // It should advance
      expect(provider.activeCharacterIndex, 1);
      expect(provider.currentCharacter, char2);
      expect(provider.isWordComplete, false);
      expect(provider.ratingForCompletion(), ReviewRating.again);
    });

    test('completing the final target sets isWordComplete == true', () async {
      await provider.loadForCard(text: '日本', sourceLanguage: 'ja');
      validationService.nextResult = const StrokeValidationResult.accept(0.9);

      await provider.submitStroke([const Offset(0, 0)]); // finishes char1
      expect(provider.isWordComplete, false);

      await provider.submitStroke([const Offset(0, 0)]); // finishes char2
      expect(provider.isWordComplete, true);
      expect(provider.ratingForCompletion(), ReviewRating.easy);
    });

    test('reset during character advance prevents stale delayed mutation',
        () async {
      await provider.loadForCard(text: '日本', sourceLanguage: 'ja');
      validationService.nextResult = const StrokeValidationResult.accept(0.9);

      final submitFuture = provider.submitStroke([const Offset(0, 0)]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      provider.resetPractice();
      await submitFuture;

      expect(provider.activeCharacterIndex, 0);
      expect(provider.currentCharacter, char1);
      expect(provider.completedStrokeCount, 0);
      expect(provider.isWordComplete, false);
    });

    test('ratingForCompletion uses total mistakes across all targets',
        () async {
      await provider.loadForCard(text: '日本', sourceLanguage: 'ja');

      validationService.nextResult =
          const StrokeValidationResult.reject(StrokeRejection.wrongDirection);
      await provider.submitStroke([const Offset(0, 0)]);

      validationService.nextResult = const StrokeValidationResult.accept(0.9);
      await provider.submitStroke([const Offset(0, 0)]);

      validationService.nextResult =
          const StrokeValidationResult.reject(StrokeRejection.wrongDirection);
      await provider.submitStroke([const Offset(0, 0)]);

      validationService.nextResult = const StrokeValidationResult.accept(0.9);
      await provider.submitStroke([const Offset(0, 0)]);

      expect(provider.isWordComplete, true);
      expect(provider.ratingForCompletion(), ReviewRating.good);
    });

    test('mixed text skips unsupported characters and reports count', () async {
      await provider.loadForCard(text: '日本!A', sourceLanguage: 'ja');

      expect(provider.state, StrokePracticeState.ready);
      expect(provider.supportedCharacterCount, 2);
      expect(provider.unsupportedCharacterCount, 2); // '!' and 'A'
    });

    test('text with no supported characters enters error state', () async {
      await provider.loadForCard(text: 'Hello', sourceLanguage: 'ja');

      expect(provider.state, StrokePracticeState.error);
      expect(provider.supportedCharacterCount, 0);
    });

    test('changes validation profile and passes it to service', () async {
      await provider.loadForCard(text: '日', sourceLanguage: 'ja');

      provider.setValidationProfile(StrokeValidationProfile.gentle);
      expect(provider.validationProfile, StrokeValidationProfile.gentle);

      validationService.nextResult = const StrokeValidationResult.accept(0.9);
      await provider.submitStroke([const Offset(0, 0)]);

      expect(validationService.lastProfile, StrokeValidationProfile.gentle);
    });

    test('resetPractice does not reset validation profile', () async {
      await provider.loadForCard(text: '日', sourceLanguage: 'ja');
      provider.setValidationProfile(StrokeValidationProfile.strict);

      provider.resetPractice();
      expect(provider.validationProfile, StrokeValidationProfile.strict);
    });
  });
}
