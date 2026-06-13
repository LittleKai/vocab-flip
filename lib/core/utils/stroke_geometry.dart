import 'dart:math' as math;
import 'dart:ui';

/// Pure geometry functions for stroke validation.
/// All operate on [Offset] lists in a 1024×1024 coordinate space.
class StrokeGeometry {
  StrokeGeometry._();

  /// Remove consecutive points closer than [threshold].
  static List<Offset> dedupe(List<Offset> points, {double threshold = 4.0}) {
    if (points.isEmpty) return const [];
    final result = [points.first];
    for (var i = 1; i < points.length; i++) {
      if ((points[i] - result.last).distance >= threshold) {
        result.add(points[i]);
      }
    }
    return result;
  }

  /// Total polyline length.
  static double polylineLength(List<Offset> points) {
    var len = 0.0;
    for (var i = 1; i < points.length; i++) {
      len += (points[i] - points[i - 1]).distance;
    }
    return len;
  }

  /// Resample [points] into [count] evenly-spaced points along the polyline.
  static List<Offset> resample(List<Offset> points, int count) {
    if (points.length < 2 || count < 2) return List.of(points);
    final total = polylineLength(points);
    if (total == 0) return List.filled(count, points.first);

    final step = total / (count - 1);
    final result = <Offset>[points.first];
    var distCovered = 0.0;

    for (var j = 1; j < points.length && result.length < count - 1; j++) {
      final segLen = (points[j] - points[j - 1]).distance;
      var segStart = 0.0; // how far into this segment we've consumed

      while (result.length < count - 1) {
        final nextTarget = step * result.length;
        final needed = nextTarget - distCovered;
        final remaining = segLen - segStart;

        if (remaining < needed) break; // move to next segment

        final t = segLen > 0 ? (segStart + needed) / segLen : 0.0;
        result.add(Offset.lerp(points[j - 1], points[j], t)!);
        segStart += needed;
        distCovered = nextTarget;
      }

      distCovered += segLen - segStart;
    }

    // Always end with the last point.
    while (result.length < count) {
      result.add(points.last);
    }
    return result;
  }

  /// Shortest distance from [p] to the line segment [a]-[b].
  static double distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return (p - a).distance;
    final t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lenSq;
    final clamped = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + clamped * ab.dx, a.dy + clamped * ab.dy);
    return (p - proj).distance;
  }

  /// Average distance from each point in [points] to the nearest segment
  /// of [polyline].
  static double avgDistToPolyline(List<Offset> points, List<Offset> polyline) {
    if (points.isEmpty || polyline.length < 2) return double.infinity;
    var total = 0.0;
    for (final p in points) {
      var minD = double.infinity;
      for (var i = 1; i < polyline.length; i++) {
        final d = distToSegment(p, polyline[i - 1], polyline[i]);
        if (d < minD) minD = d;
      }
      total += minD;
    }
    return total / points.length;
  }

  /// Average cosine similarity between consecutive-segment direction vectors
  /// of [a] and [b]. Returns -1..1 (1 = same direction, -1 = opposite).
  /// Both lists should have the same length (resample first).
  static double avgCosineSimilarity(List<Offset> a, List<Offset> b) {
    if (a.length < 2 || b.length < 2) return 0.0;
    final n = math.min(a.length, b.length);
    var sum = 0.0;
    var count = 0;
    for (var i = 1; i < n; i++) {
      final da = a[i] - a[i - 1];
      final db = b[i] - b[i - 1];
      final magA = da.distance;
      final magB = db.distance;
      if (magA > 0 && magB > 0) {
        sum += (da.dx * db.dx + da.dy * db.dy) / (magA * magB);
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  /// Discrete Frechet distance between two polylines.
  static double frechetDistance(List<Offset> p, List<Offset> q) {
    final n = p.length;
    final m = q.length;
    if (n == 0 || m == 0) return double.infinity;

    // dp[i][j] = Frechet coupling distance
    final dp = List.generate(n, (_) => List.filled(m, -1.0));

    double rec(int i, int j) {
      if (dp[i][j] >= 0) return dp[i][j];
      final d = (p[i] - q[j]).distance;
      double val;
      if (i == 0 && j == 0) {
        val = d;
      } else if (i == 0) {
        val = math.max(rec(0, j - 1), d);
      } else if (j == 0) {
        val = math.max(rec(i - 1, 0), d);
      } else {
        val = math.max(
          math.min(math.min(rec(i - 1, j), rec(i, j - 1)), rec(i - 1, j - 1)),
          d,
        );
      }
      dp[i][j] = val;
      return val;
    }

    return rec(n - 1, m - 1);
  }
}
