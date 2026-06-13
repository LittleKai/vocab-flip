import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/presentation/widgets/stroke/stroke_order_painter.dart';

/// Single-stroke fixture (一).
StrokeCharacter _oneStroke() => StrokeCharacter.fromJson(const {
      'character': '一',
      'locale': 'ja',
      'source': 'fixture',
      'viewBox': [0, 0, 1024, 1024],
      'strokes': [
        {
          'index': 0,
          'path': 'M 100 512 L 924 512 L 924 552 L 100 552 Z',
          'median': [
            [100, 532],
            [924, 532],
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
          'path': 'M 100 480 L 924 480 L 924 544 L 100 544 Z',
          'median': [
            [100, 512],
            [924, 512],
          ],
        },
        {
          'index': 1,
          'path': 'M 480 100 L 544 100 L 544 924 L 480 924 Z',
          'median': [
            [512, 100],
            [512, 924],
          ],
        },
      ],
    });

Widget _wrapPainter(StrokeOrderPainter painter) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 300,
        height: 300,
        child: CustomPaint(painter: painter),
      ),
    ),
  );
}

void main() {
  group('StrokeOrderPainter', () {
    test('parses valid SVG paths from fixture character', () {
      final painter = StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 0,
        activeProgress: 0.0,
      );
      expect(painter.parsedPaths.length, 1);
      // A parsed path should have non-zero bounds.
      expect(painter.parsedPaths[0].getBounds().isEmpty, isFalse);
    });

    test('parses multi-stroke paths correctly', () {
      final painter = StrokeOrderPainter(
        character: _twoStrokes(),
        completedStrokeCount: 0,
        activeProgress: 0.0,
      );
      expect(painter.parsedPaths.length, 2);
      for (final path in painter.parsedPaths) {
        expect(path.getBounds().isEmpty, isFalse);
      }
    });

    testWidgets('renders without exception at progress 0.0',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapPainter(StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 0,
        activeProgress: 0.0,
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception at progress 0.5',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapPainter(StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 0,
        activeProgress: 0.5,
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception at progress 1.0',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapPainter(StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 0,
        activeProgress: 1.0,
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders completed strokes with ink color',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapPainter(StrokeOrderPainter(
        character: _twoStrokes(),
        completedStrokeCount: 1,
        activeProgress: 0.5,
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all strokes completed', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapPainter(StrokeOrderPainter(
        character: _twoStrokes(),
        completedStrokeCount: 2,
        activeProgress: 0.0,
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders user stroke overlay', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapPainter(StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 0,
        activeProgress: 0.0,
        userStrokePoints: const [Offset(100, 532), Offset(500, 532)],
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles invalid SVG path gracefully',
        (WidgetTester tester) async {
      // _tryParsePath returns an empty Path for unrecognized input.
      final charWithBadPath = StrokeCharacter.fromJson(const {
        'character': 'X',
        'locale': 'ja',
        'source': 'fixture',
        'viewBox': [0, 0, 1024, 1024],
        'strokes': [
          {
            'index': 0,
            'path': 'INVALID PATH DATA',
            'median': [
              [100, 100],
              [900, 900],
            ],
          }
        ],
      });
      await tester.pumpWidget(_wrapPainter(StrokeOrderPainter(
        character: charWithBadPath,
        completedStrokeCount: 0,
        activeProgress: 0.5,
      )));
      // Should render without throwing.
      expect(tester.takeException(), isNull);
    });

    test('shouldRepaint returns true when completedStrokeCount changes', () {
      final a = StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 0,
        activeProgress: 0.0,
      );
      final b = StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 1,
        activeProgress: 0.0,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when activeProgress changes', () {
      final a = StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 0,
        activeProgress: 0.0,
      );
      final b = StrokeOrderPainter(
        character: _oneStroke(),
        completedStrokeCount: 0,
        activeProgress: 0.5,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when overlay colors change', () {
      final char = _oneStroke();
      final a = StrokeOrderPainter(
        character: char,
        completedStrokeCount: 0,
        activeProgress: 0.0,
        guidelineColor: Colors.grey,
        userStrokeColor: Colors.blue,
      );
      final b = StrokeOrderPainter(
        character: char,
        completedStrokeCount: 0,
        activeProgress: 0.0,
        guidelineColor: Colors.red,
        userStrokeColor: Colors.green,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final char = _oneStroke();
      final a = StrokeOrderPainter(
        character: char,
        completedStrokeCount: 0,
        activeProgress: 0.0,
      );
      final b = StrokeOrderPainter(
        character: char,
        completedStrokeCount: 0,
        activeProgress: 0.0,
      );
      expect(a.shouldRepaint(b), isFalse);
    });

    testWidgets('renders in zero-size container without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 0,
            height: 0,
            child: CustomPaint(
              painter: StrokeOrderPainter(
                character: _oneStroke(),
                completedStrokeCount: 0,
                activeProgress: 0.5,
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
