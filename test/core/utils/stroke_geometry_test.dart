import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/core/utils/stroke_geometry.dart';

void main() {
  group('dedupe', () {
    test('removes consecutive near-duplicate points', () {
      final pts = [
        const Offset(0, 0),
        const Offset(1, 1), // dist ~1.4, below default 4
        const Offset(2, 2), // dist ~1.4 from previous
        const Offset(10, 10), // dist ~11.3 from (2,2)
      ];
      final result = StrokeGeometry.dedupe(pts);
      expect(result, [const Offset(0, 0), const Offset(10, 10)]);
    });

    test('keeps all points when spaced above threshold', () {
      final pts = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(200, 0),
      ];
      expect(StrokeGeometry.dedupe(pts), pts);
    });

    test('returns empty for empty input', () {
      expect(StrokeGeometry.dedupe([]), isEmpty);
    });

    test('returns single point for single input', () {
      expect(StrokeGeometry.dedupe([const Offset(5, 5)]), [const Offset(5, 5)]);
    });
  });

  group('polylineLength', () {
    test('horizontal line', () {
      final pts = [const Offset(0, 0), const Offset(100, 0)];
      expect(StrokeGeometry.polylineLength(pts), 100.0);
    });

    test('vertical line', () {
      final pts = [const Offset(0, 0), const Offset(0, 200)];
      expect(StrokeGeometry.polylineLength(pts), 200.0);
    });

    test('multi-segment path', () {
      final pts = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(100, 100),
      ];
      expect(StrokeGeometry.polylineLength(pts), 200.0);
    });

    test('empty/single returns 0', () {
      expect(StrokeGeometry.polylineLength([]), 0.0);
      expect(StrokeGeometry.polylineLength([const Offset(5, 5)]), 0.0);
    });
  });

  group('resample', () {
    test('resamples horizontal line to N points', () {
      final pts = [const Offset(0, 0), const Offset(100, 0)];
      final result = StrokeGeometry.resample(pts, 5);
      expect(result.length, 5);
      expect(result.first, const Offset(0, 0));
      expect(result.last, const Offset(100, 0));
      // Middle point should be at 50
      expect(result[2].dx, closeTo(50, 1));
    });

    test('returns copy when count < 2', () {
      final pts = [const Offset(0, 0), const Offset(100, 0)];
      expect(StrokeGeometry.resample(pts, 1), pts);
    });

    test('handles single-point input', () {
      final result = StrokeGeometry.resample([const Offset(5, 5)], 3);
      expect(result.length, 1);
    });
  });

  group('distToSegment', () {
    test('point on segment returns 0', () {
      expect(
        StrokeGeometry.distToSegment(
            const Offset(50, 0), const Offset(0, 0), const Offset(100, 0)),
        closeTo(0, 0.001),
      );
    });

    test('point perpendicular to segment', () {
      expect(
        StrokeGeometry.distToSegment(
            const Offset(50, 30), const Offset(0, 0), const Offset(100, 0)),
        closeTo(30, 0.001),
      );
    });

    test('point nearest to endpoint', () {
      // Past the end of the segment
      expect(
        StrokeGeometry.distToSegment(
            const Offset(150, 0), const Offset(0, 0), const Offset(100, 0)),
        closeTo(50, 0.001),
      );
    });

    test('degenerate segment (zero length)', () {
      expect(
        StrokeGeometry.distToSegment(
            const Offset(10, 0), const Offset(5, 0), const Offset(5, 0)),
        closeTo(5, 0.001),
      );
    });
  });

  group('avgDistToPolyline', () {
    test('points on polyline have ~0 average distance', () {
      final poly = [const Offset(0, 0), const Offset(100, 0)];
      final pts = [
        const Offset(0, 0),
        const Offset(50, 0),
        const Offset(100, 0)
      ];
      expect(StrokeGeometry.avgDistToPolyline(pts, poly), closeTo(0, 0.001));
    });

    test('parallel offset polyline', () {
      final poly = [const Offset(0, 0), const Offset(100, 0)];
      final pts = [
        const Offset(0, 20),
        const Offset(50, 20),
        const Offset(100, 20)
      ];
      expect(StrokeGeometry.avgDistToPolyline(pts, poly), closeTo(20, 0.001));
    });

    test('far-away points produce large distance', () {
      final poly = [const Offset(0, 0), const Offset(100, 0)];
      final pts = [const Offset(0, 500), const Offset(100, 500)];
      expect(StrokeGeometry.avgDistToPolyline(pts, poly), closeTo(500, 0.001));
    });

    test('empty points returns infinity', () {
      expect(
        StrokeGeometry.avgDistToPolyline(
            [], [const Offset(0, 0), const Offset(100, 0)]),
        double.infinity,
      );
    });
  });

  group('avgCosineSimilarity', () {
    test('same direction returns ~1', () {
      final a = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(200, 0)
      ];
      final b = [const Offset(0, 0), const Offset(50, 0), const Offset(100, 0)];
      expect(StrokeGeometry.avgCosineSimilarity(a, b), closeTo(1.0, 0.001));
    });

    test('opposite direction returns ~-1', () {
      final a = [const Offset(0, 0), const Offset(100, 0)];
      final b = [const Offset(100, 0), const Offset(0, 0)];
      expect(StrokeGeometry.avgCosineSimilarity(a, b), closeTo(-1.0, 0.001));
    });

    test('perpendicular returns ~0', () {
      final a = [const Offset(0, 0), const Offset(100, 0)];
      final b = [const Offset(0, 0), const Offset(0, 100)];
      expect(StrokeGeometry.avgCosineSimilarity(a, b), closeTo(0.0, 0.001));
    });

    test('diagonal same direction', () {
      final a = [const Offset(0, 0), const Offset(100, 100)];
      final b = [const Offset(0, 0), const Offset(50, 50)];
      expect(StrokeGeometry.avgCosineSimilarity(a, b), closeTo(1.0, 0.001));
    });

    test('too few points returns 0', () {
      expect(
          StrokeGeometry.avgCosineSimilarity(
              [const Offset(0, 0)], [const Offset(0, 0)]),
          0.0);
    });
  });

  group('frechetDistance', () {
    test('identical polylines return 0', () {
      final pts = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(200, 0)
      ];
      expect(StrokeGeometry.frechetDistance(pts, pts), closeTo(0, 0.001));
    });

    test('parallel offset returns offset distance', () {
      final a = [const Offset(0, 0), const Offset(100, 0)];
      final b = [const Offset(0, 30), const Offset(100, 30)];
      expect(StrokeGeometry.frechetDistance(a, b), closeTo(30, 0.001));
    });

    test('reversed polyline has non-zero Frechet distance', () {
      final a = [const Offset(0, 0), const Offset(100, 0)];
      final b = [const Offset(100, 0), const Offset(0, 0)];
      // Frechet for reversed = max coupling distance = 100
      expect(StrokeGeometry.frechetDistance(a, b), closeTo(100, 0.001));
    });

    test('far-away polylines produce large distance', () {
      final a = [const Offset(0, 0), const Offset(100, 0)];
      final b = [const Offset(0, 500), const Offset(100, 500)];
      expect(StrokeGeometry.frechetDistance(a, b), closeTo(500, 0.001));
    });

    test('empty input returns infinity', () {
      expect(StrokeGeometry.frechetDistance([], [const Offset(0, 0)]),
          double.infinity);
      expect(StrokeGeometry.frechetDistance([const Offset(0, 0)], []),
          double.infinity);
    });
  });
}
