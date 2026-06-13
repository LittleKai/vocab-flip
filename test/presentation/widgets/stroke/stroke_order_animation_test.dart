import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/presentation/widgets/stroke/stroke_order_animation.dart';

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

void main() {
  group('StrokeOrderAnimation', () {
    testWidgets('renders and starts animation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StrokeOrderAnimation(character: _oneStroke()),
          ),
        ),
      ));
      expect(find.byType(StrokeOrderAnimation), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('activeProgress advances over time',
        (WidgetTester tester) async {
      final key = GlobalKey<StrokeOrderAnimationState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StrokeOrderAnimation(
              key: key,
              character: _oneStroke(),
              strokeDuration: const Duration(milliseconds: 600),
            ),
          ),
        ),
      ));

      final state = key.currentState!;
      expect(state.activeProgress, 0.0);

      // Advance halfway through the stroke duration.
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.activeProgress, closeTo(0.5, 0.05));

      // Advance to the end.
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.activeProgress, 1.0);
    });

    testWidgets('completes single-stroke character and calls onCompleted',
        (WidgetTester tester) async {
      var completed = false;
      final key = GlobalKey<StrokeOrderAnimationState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StrokeOrderAnimation(
              key: key,
              character: _oneStroke(),
              strokeDuration: const Duration(milliseconds: 600),
              onCompleted: () => completed = true,
            ),
          ),
        ),
      ));

      // Run animation to completion.
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(key.currentState!.completedStrokeCount, 1);
    });

    testWidgets('advances through multi-stroke character',
        (WidgetTester tester) async {
      var completed = false;
      final key = GlobalKey<StrokeOrderAnimationState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StrokeOrderAnimation(
              key: key,
              character: _twoStrokes(),
              strokeDuration: const Duration(milliseconds: 400),
              pauseBetweenStrokes: const Duration(milliseconds: 100),
              onCompleted: () => completed = true,
            ),
          ),
        ),
      ));

      final state = key.currentState!;
      expect(state.completedStrokeCount, 0);

      // Let first stroke animation complete and settle.
      await tester.pumpAndSettle();
      expect(state.completedStrokeCount, 1);

      // Advance past the pause between strokes (Future.delayed).
      await tester.pump(const Duration(milliseconds: 100));

      // Let second stroke animation complete and settle.
      await tester.pumpAndSettle();
      expect(state.completedStrokeCount, 2);
      expect(completed, isTrue);
    });

    testWidgets('replay resets and re-animates',
        (WidgetTester tester) async {
      final key = GlobalKey<StrokeOrderAnimationState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StrokeOrderAnimation(
              key: key,
              character: _oneStroke(),
              strokeDuration: const Duration(milliseconds: 600),
            ),
          ),
        ),
      ));

      // Complete the animation.
      await tester.pumpAndSettle();
      expect(key.currentState!.completedStrokeCount, 1);

      // Replay.
      key.currentState!.replay();
      await tester.pump();
      expect(key.currentState!.completedStrokeCount, 0);
      expect(key.currentState!.activeProgress, 0.0);

      // Verify it animates again.
      await tester.pump(const Duration(milliseconds: 300));
      expect(key.currentState!.activeProgress, closeTo(0.5, 0.05));

      // Complete again.
      await tester.pumpAndSettle();
      expect(key.currentState!.completedStrokeCount, 1);
    });

    testWidgets('disposes controller without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StrokeOrderAnimation(character: _oneStroke()),
          ),
        ),
      ));

      // Replace widget tree to trigger dispose.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('updates when character changes',
        (WidgetTester tester) async {
      final key = GlobalKey<StrokeOrderAnimationState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StrokeOrderAnimation(
              key: key,
              character: _oneStroke(),
              strokeDuration: const Duration(milliseconds: 600),
            ),
          ),
        ),
      ));

      // Complete animation for first character.
      await tester.pumpAndSettle();
      expect(key.currentState!.completedStrokeCount, 1);

      // Switch to a different character.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: StrokeOrderAnimation(
              key: key,
              character: _twoStrokes(),
              strokeDuration: const Duration(milliseconds: 600),
            ),
          ),
        ),
      ));

      // Should have reset.
      expect(key.currentState!.completedStrokeCount, 0);
    });
  });
}
