import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/core/utils/advanced_stroke_matcher.dart';

void main() {
  group('AdvancedStrokeMatcher', () {
    test('findCorners finds corners using ShortStraw logic', () {
      // Create a right-angle stroke (L shape)
      final points = [
        const Offset(100, 100),
        const Offset(100, 200),
        const Offset(100, 300),
        const Offset(100, 400),
        const Offset(100, 500), // Corner
        const Offset(200, 500),
        const Offset(300, 500),
        const Offset(400, 500),
        const Offset(500, 500),
      ];

      final corners = AdvancedStrokeMatcher.findCorners(points);
      
      expect(corners.length, greaterThanOrEqualTo(3), reason: 'Should find start, corner, and end');
      expect(corners.first, points.first);
      expect(corners.last, points.last);
      
      // Should find a corner near (100, 500)
      final cornerDist = corners.map((c) => (c - const Offset(100, 500)).distance).reduce((a, b) => a < b ? a : b);
      expect(cornerDist, lessThan(45.0)); // Should be reasonably close based on resampling
    });

    test('trimHooksAndAlign trims small hook at start and end', () {
      final expected = [
        const Offset(200, 500),
        const Offset(300, 500),
        const Offset(400, 500),
        const Offset(500, 500),
      ];

      // User drew it but started with a hook from (200, 400) and ended with hook to (500, 400)
      final user = [
        const Offset(200, 400), // Hook
        const Offset(200, 450), // Hook
        ...expected,
        const Offset(500, 450), // Hook
        const Offset(500, 400), // Hook
      ];

      final trimmed = AdvancedStrokeMatcher.trimHooksAndAlign(user, expected);

      // The trimmed length should be closer to expected, ignoring hooks
      expect(trimmed.first.dy, greaterThan(450)); // Should have trimmed the start hook (y=400)
      expect(trimmed.last.dy, greaterThan(450));  // Should have trimmed the end hook (y=400)
    });

    test('trimHooksAndAlign does not trim completely reversed strokes (safety check)', () {
      final expected = [
        const Offset(100, 500),
        const Offset(500, 500),
      ];

      final user = [
        const Offset(500, 500),
        const Offset(300, 500),
        const Offset(100, 500),
      ];

      final trimmed = AdvancedStrokeMatcher.trimHooksAndAlign(user, expected);

      // Should return the original stroke (resampled) because trimming would remove > 30% of it
      expect(trimmed.first.dx, closeTo(500, 10.0));
      expect(trimmed.last.dx, closeTo(100, 10.0));
    });
  });
}
