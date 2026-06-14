import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/data/services/stroke_validation_service.dart';

/// Single-stroke fixture (一).
StrokeCharacter _oneStroke() => StrokeCharacter.fromJson(const {
      'character': '一',
      'locale': 'ja',
      'source': 'fixture',
      'viewBox': [0, 0, 1024, 1024],
      'strokes': [
        {
          'index': 0,
          'path': 'M 100 512 L 924 512 Z',
          'median': [
            [100, 512],
            [924, 512],
          ],
        }
      ],
    });

/// Two-stroke fixture (十).
StrokeCharacter _twoStrokes() => StrokeCharacter.fromJson(const {
      'character': '十',
      'locale': 'ja',
      'source': 'fixture',
      'viewBox': [0, 0, 1024, 1024],
      'strokes': [
        {
          'index': 0,
          'path': 'M 100 512 L 924 512 Z',
          'median': [
            [100, 512],
            [924, 512],
          ],
        },
        {
          'index': 1,
          'path': 'M 512 100 L 512 924 Z',
          'median': [
            [512, 100],
            [512, 924],
          ],
        },
      ],
    });

void main() {
  late StrokeValidationService service;

  setUp(() {
    service = StrokeValidationService();
  });

  group('StrokeValidationService', () {
    test('accepts perfect stroke under standard profile', () {
      final result = service.validateStroke(
        userPoints: const [
          Offset(100, 512),
          Offset(500, 512),
          Offset(924, 512)
        ],
        character: _oneStroke(),
        expectedIndex: 0,
        profile: StrokeValidationProfile.standard,
      );
      expect(result.accepted, isTrue);
      expect(result.score, greaterThan(0.9));
    });

    test('rejects reversed stroke as wrongDirection even in gentle mode', () {
      final result = service.validateStroke(
        userPoints: const [
          Offset(924, 512),
          Offset(500, 512),
          Offset(100, 512)
        ],
        character: _oneStroke(),
        expectedIndex: 0,
        profile: StrokeValidationProfile.gentle,
      );
      expect(result.accepted, isFalse);
      expect(result.rejection, StrokeRejection.wrongDirection);
    });

    test('borderline stroke behavior changes based on profile', () {
      // Create a stroke that starts 300px away.
      // Standard threshold is 250 (rejects).
      // Gentle threshold is 400 (accepts).
      // Strict threshold is 150 (rejects).
      const borderlinePoints = [
        Offset(400, 512), // Expected start is 100 (dist = 300)
        Offset(924, 512)
      ];

      final standardResult = service.validateStroke(
        userPoints: borderlinePoints,
        character: _oneStroke(),
        expectedIndex: 0,
        profile: StrokeValidationProfile.standard,
      );
      expect(standardResult.accepted, isFalse);
      expect(standardResult.rejection, StrokeRejection.wrongStart);

      final strictResult = service.validateStroke(
        userPoints: borderlinePoints,
        character: _oneStroke(),
        expectedIndex: 0,
        profile: StrokeValidationProfile.strict,
      );
      expect(strictResult.accepted, isFalse);
      expect(strictResult.rejection, StrokeRejection.wrongStart);

      final gentleResult = service.validateStroke(
        userPoints: borderlinePoints,
        character: _oneStroke(),
        expectedIndex: 0,
        profile: StrokeValidationProfile.gentle,
      );
      expect(gentleResult.accepted, isTrue);
    });

    test(
        'rejects drawing stroke 2 when expecting stroke 1 as wrongOrder in gentle mode',
        () {
      final result = service.validateStroke(
        userPoints: const [Offset(512, 100), Offset(512, 924)],
        character: _twoStrokes(),
        expectedIndex: 0,
        profile: StrokeValidationProfile.gentle,
      );
      expect(result.accepted, isFalse);
      expect(result.rejection, StrokeRejection.wrongOrder);
    });

    test('rejects short tap as tooShort', () {
      final result = service.validateStroke(
        userPoints: const [Offset(100, 512), Offset(105, 512)],
        character: _oneStroke(),
        expectedIndex: 0,
      );
      expect(result.accepted, isFalse);
      expect(result.rejection, StrokeRejection.tooShort);
    });
  });
}
