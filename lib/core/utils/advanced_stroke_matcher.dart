import 'dart:math' as math;
import 'dart:ui';
import 'stroke_geometry.dart';

/// Implements advanced stroke matching algorithms, including ShortStraw corner
/// detection and dynamic programming segment alignment.
class AdvancedStrokeMatcher {
  AdvancedStrokeMatcher._();

  /// Constant spacing for ShortStraw resampling (normalized to 1024x1024 space).
  static const double _shortStrawSpacing = 40.0;
  static const int _shortStrawWindow = 3;

  /// Resamples points by a fixed distance spacing.
  static List<Offset> _resampleBySpacing(List<Offset> points, double spacing) {
    if (points.length < 2) return List.of(points);
    final result = <Offset>[points.first];
    var distCovered = 0.0;

    for (var j = 1; j < points.length; j++) {
      final segLen = (points[j] - points[j - 1]).distance;
      var segStart = 0.0;

      while (segLen - segStart >= spacing - distCovered) {
        final needed = spacing - distCovered;
        final t = (segStart + needed) / segLen;
        result.add(Offset(
          points[j - 1].dx + (points[j].dx - points[j - 1].dx) * t,
          points[j - 1].dy + (points[j].dy - points[j - 1].dy) * t,
        ));
        segStart += needed;
        distCovered = 0.0;
      }
      distCovered += segLen - segStart;
    }

    if (result.isEmpty || (result.last - points.last).distance > spacing * 0.5) {
      result.add(points.last);
    }
    return result;
  }

  /// Detects corners in a stroke using the ShortStraw algorithm.
  /// Returns the indices of the corners in the original [points] list (mapped back).
  /// For simplicity, it returns the points themselves or resampled corners.
  static List<Offset> findCorners(List<Offset> points) {
    if (points.length < 3) return List.of(points);

    final resampled = _resampleBySpacing(points, _shortStrawSpacing);
    if (resampled.length <= _shortStrawWindow * 2) {
      return [resampled.first, resampled.last];
    }

    final straws = List<double>.filled(resampled.length, 0.0);
    for (var i = _shortStrawWindow; i < resampled.length - _shortStrawWindow; i++) {
      straws[i] = (resampled[i - _shortStrawWindow] - resampled[i + _shortStrawWindow]).distance;
    }

    final validStraws = straws.sublist(_shortStrawWindow, resampled.length - _shortStrawWindow);
    validStraws.sort();
    final median = validStraws.isNotEmpty ? validStraws[validStraws.length ~/ 2] : 0.0;
    final threshold = median * 0.95;

    final corners = <Offset>[resampled.first];

    for (var i = _shortStrawWindow; i < resampled.length - _shortStrawWindow; i++) {
      if (straws[i] < threshold) {
        bool isLocalMin = true;
        final start = math.max(_shortStrawWindow, i - _shortStrawWindow);
        final end = math.min(resampled.length - _shortStrawWindow - 1, i + _shortStrawWindow);
        for (var j = start; j <= end; j++) {
          if (straws[j] < straws[i]) {
            isLocalMin = false;
            break;
          }
        }
        if (isLocalMin) {
          corners.add(resampled[i]);
        }
      }
    }

    corners.add(resampled.last);
    return corners;
  }

  /// Trims hooks and over-extended segments from the [user] stroke based on the [expected] stroke.
  /// Uses a Subsequence Dynamic Time Warping (DTW) approach to find the best matching
  /// contiguous sub-segment of [user] that aligns with the entirety of [expected].
  static List<Offset> trimHooksAndAlign(List<Offset> user, List<Offset> expected) {
    if (user.length < 2 || expected.length < 2) return user;

    // Resample to have uniform points for DTW
    final uResampled = StrokeGeometry.resample(user, 30);
    final eResampled = StrokeGeometry.resample(expected, 30);

    final n = uResampled.length;
    final m = eResampled.length;

    // dp[i][j] stores the min cost to match uResampled[0..i] to eResampled[0..j]
    // where uResampled[i] is matched to eResampled[j].
    final dp = List.generate(n, (_) => List.filled(m, double.infinity));
    final parentI = List.generate(n, (_) => List.filled(m, 0));

    // Initialization: expected[0] can match with ANY user[i] (this allows trimming the start hook)
    for (var i = 0; i < n; i++) {
      dp[i][0] = (uResampled[i] - eResampled[0]).distance;
      parentI[i][0] = i; 
    }

    // DP computation
    for (var j = 1; j < m; j++) {
      for (var i = 1; i < n; i++) {
        final cost = (uResampled[i] - eResampled[j]).distance;
        
        // Find min cost among matching options:
        // 1. Advance both: u[i-1] matches e[j-1]
        // 2. Advance user only: u[i-1] matches e[j] (user has extra points/slower)
        // 3. Advance expected only: u[i] matches e[j-1] (user skipped points/faster)
        
        double minPrev = dp[i - 1][j - 1];
        int bestI = i - 1;

        if (dp[i - 1][j] < minPrev) {
          minPrev = dp[i - 1][j];
          bestI = i - 1;
        }
        
        if (dp[i][j - 1] < minPrev) {
          minPrev = dp[i][j - 1];
          bestI = i;
        }

        dp[i][j] = minPrev + cost;
        parentI[i][j] = bestI;
      }
    }

    // Find the best ending point in user for expected[m-1] (allows trimming the end hook)
    var bestEndI = 0;
    var minEndCost = double.infinity;
    for (var i = 0; i < n; i++) {
      if (dp[i][m - 1] < minEndCost) {
        minEndCost = dp[i][m - 1];
        bestEndI = i;
      }
    }

    // Backtrack to find the start point
    var currI = bestEndI;
    var currJ = m - 1;
    while (currJ > 0) {
      currI = parentI[currI][currJ];
      if (parentI[currI][currJ] != currI) {
        currJ--;
      } else {
        // if bestI was i, then j decremented
        currJ--;
      }
    }
    final bestStartI = currI;

    // If the matched portion is too small (e.g. we trimmed away > 50% of the stroke), 
    // it's likely a completely wrong stroke (e.g. reversed) rather than just having hooks.
    if ((bestEndI - bestStartI) < n * 0.5) {
      return user;
    }

    // Return the trimmed original stroke (we map the resampled indices back)
    // To keep it simple, we just return the sliced resampled user stroke.
    return uResampled.sublist(bestStartI, bestEndI + 1);
  }
}
