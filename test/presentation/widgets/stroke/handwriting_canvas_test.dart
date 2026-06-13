import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/presentation/widgets/stroke/handwriting_canvas.dart';

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

void main() {
  group('HandwritingCanvas', () {
    testWidgets('renders CustomPaint', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: HandwritingCanvas(
              character: _oneStroke(),
              completedStrokeCount: 0,
              onStrokeComplete: (_) {},
            ),
          ),
        ),
      ));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('captures gesture and normalizes points', (tester) async {
      List<Offset>? captured;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1024,
              height: 1024, // 1:1 scale to viewBox for easy testing
              child: HandwritingCanvas(
                character: _oneStroke(),
                completedStrokeCount: 0,
                onStrokeComplete: (pts) => captured = pts,
              ),
            ),
          ),
        ),
      ));

      final canvasCenter = tester.getCenter(find.byType(HandwritingCanvas));
      
      // Simulate drawing a line.
      final gesture = await tester.startGesture(canvasCenter - const Offset(100, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0)); // back to center
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.length, 3);
      // We moved right by 50 logical pixels twice.
      // The canvas is constrained to 800x600 test screen, so scale = 600/1024 = 0.5859375.
      // 50 / 0.5859375 = 85.33333333333333
      expect(captured![1].dx - captured![0].dx, closeTo(85.3, 1));
      expect(captured![2].dx - captured![1].dx, closeTo(85.3, 1));
    });

    testWidgets('clear removes current stroke', (tester) async {
      final key = GlobalKey<HandwritingCanvasState>();
      List<Offset>? captured;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: HandwritingCanvas(
              key: key,
              character: _oneStroke(),
              completedStrokeCount: 0,
              onStrokeComplete: (pts) => captured = pts,
            ),
          ),
        ),
      ));

      // Start a gesture.
      final canvasCenter = tester.getCenter(find.byType(HandwritingCanvas));
      final gesture = await tester.startGesture(canvasCenter);
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // Clear the stroke while dragging.
      key.currentState!.clear();
      await tester.pump();

      // End the drag. It should emit the remaining points (just the end point).
      await gesture.up();
      await tester.pump();

      // Should be ignored because clear() emptied it and we only added one more point.
      expect(captured, isNull);
    });

    testWidgets('ignores single-point tap', (tester) async {
      List<Offset>? captured;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: HandwritingCanvas(
              character: _oneStroke(),
              completedStrokeCount: 0,
              onStrokeComplete: (pts) => captured = pts,
            ),
          ),
        ),
      ));

      final canvasCenter = tester.getCenter(find.byType(HandwritingCanvas));
      
      // Tap without moving.
      final gesture = await tester.startGesture(canvasCenter);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Should not call onStrokeComplete.
      expect(captured, isNull);
    });
  });
}
