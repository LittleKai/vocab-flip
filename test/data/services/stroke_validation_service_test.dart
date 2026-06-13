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
    test('accepts perfect stroke', () {
      final result = service.validateStroke(
        userPoints: const [
          Offset(100, 512),
          Offset(500, 512),
          Offset(924, 512)
        ],
        character: _oneStroke(),
        expectedIndex: 0,
      );
      expect(result.accepted, isTrue);
      expect(result.score, greaterThan(0.9));
    });

    test('rejects reversed stroke as wrongDirection', () {
      final result = service.validateStroke(
        userPoints: const [
          Offset(924, 512),
          Offset(500, 512),
          Offset(100, 512)
        ],
        character: _oneStroke(),
        expectedIndex: 0,
      );
      expect(result.accepted, isFalse);
      expect(result.rejection, StrokeRejection.wrongDirection);
    });

    test('rejects far-away stroke as wrongStart', () {
      final result = service.validateStroke(
        userPoints: const [Offset(100, 100), Offset(924, 100)],
        character: _oneStroke(),
        expectedIndex: 0,
      );
      expect(result.accepted, isFalse);
      expect(result.rejection, StrokeRejection.wrongStart);
    });

    test('rejects drawing stroke 2 when expecting stroke 1 as wrongOrder', () {
      final result = service.validateStroke(
        // Draw the vertical stroke (stroke index 1)
        userPoints: const [Offset(512, 100), Offset(512, 924)],
        character: _twoStrokes(),
        expectedIndex: 0, // But we expect the horizontal one
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

    test('rejects partial stroke as tooShort based on ratio', () {
      final result = service.validateStroke(
        // Draw from 100 to 200, but median is 824 long
        userPoints: const [Offset(100, 512), Offset(200, 512)],
        character: _oneStroke(),
        expectedIndex: 0,
      );
      expect(result.accepted, isFalse);
      expect(result.rejection, StrokeRejection.tooShort);
    });

    test('rejects invalid index with inaccurate', () {
      final result = service.validateStroke(
        userPoints: const [Offset(100, 512), Offset(924, 512)],
        character: _oneStroke(),
        expectedIndex: 99,
      );
      expect(result.accepted, isFalse);
      expect(result.rejection, StrokeRejection.inaccurate);
    });
  });
}
