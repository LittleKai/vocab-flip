import 'dart:ui';

import '../../core/utils/stroke_geometry.dart';
import '../models/stroke_character.dart';

/// Why a user stroke was rejected.
enum StrokeRejection {
  tooShort,
  wrongStart,
  wrongEnd,
  wrongDirection,
  wrongOrder,
  inaccurate,
}

/// Result of validating a single user stroke attempt.
class StrokeValidationResult {
  /// Whether the stroke was accepted.
  final bool accepted;

  /// Rejection reason (null when accepted).
  final StrokeRejection? rejection;

  /// 0.0–1.0 quality score (higher is better). Meaningful only when accepted.
  final double score;

  const StrokeValidationResult.accept(this.score)
      : accepted = true,
        rejection = null;

  const StrokeValidationResult.reject(this.rejection)
      : accepted = false,
        score = 0.0;
}

/// Validates user-drawn strokes against expected stroke data.
///
/// All thresholds operate in a 1024×1024 coordinate space.
class StrokeValidationService {
  /// Minimum polyline length to not be considered a tap.
  static const double minLengthAbsolute = 30.0;

  /// Minimum ratio of user stroke length to expected median length.
  static const double minLengthRatio = 0.35;

  /// Maximum distance from user start/end to expected start/end.
  static const double startEndThreshold = 250.0;

  /// Maximum average distance from user points to expected median.
  static const double avgDistanceThreshold = 350.0;

  /// Minimum average cosine similarity (direction match).
  static const double minCosineSimilarity = 0.0;

  /// Maximum normalized Frechet distance (shape match).
  /// Normalized = frechet / diagonal of 1024 space.
  static const double maxNormalizedFrechet = 0.4;

  /// Number of points to resample to for comparison.
  static const int resampleCount = 16;

  /// How many later strokes to check for wrong-order detection.
  static const int lookaheadCount = 3;

  /// Diagonal of the 1024×1024 space for normalization.
  static const double _diagonal = 1448.15; // sqrt(1024^2 + 1024^2)

  /// Dedupe threshold for user input points.
  static const double _dedupeThreshold = 4.0;

  /// Validate a user stroke against the expected stroke at [expectedIndex].
  StrokeValidationResult validateStroke({
    required List<Offset> userPoints,
    required StrokeCharacter character,
    required int expectedIndex,
  }) {
    if (expectedIndex < 0 || expectedIndex >= character.strokeCount) {
      return const StrokeValidationResult.reject(StrokeRejection.inaccurate);
    }

    // Dedupe user input.
    final deduped = StrokeGeometry.dedupe(userPoints, threshold: _dedupeThreshold);
    if (deduped.length < 2) {
      return const StrokeValidationResult.reject(StrokeRejection.tooShort);
    }

    // Check absolute length.
    final userLen = StrokeGeometry.polylineLength(deduped);
    if (userLen < minLengthAbsolute) {
      return const StrokeValidationResult.reject(StrokeRejection.tooShort);
    }

    final expected = character.strokes[expectedIndex];
    final expectedMedian = _medianToOffsets(expected.median);
    final expectedLen = StrokeGeometry.polylineLength(expectedMedian);

    // Check length ratio.
    if (expectedLen > 0 && userLen / expectedLen < minLengthRatio) {
      return const StrokeValidationResult.reject(StrokeRejection.tooShort);
    }

    // Resample both for shape/direction comparison.
    final userResampled = StrokeGeometry.resample(deduped, resampleCount);
    final expectedResampled = StrokeGeometry.resample(expectedMedian, resampleCount);

    // Check if it's drawn in reverse.
    final reversedCosine = StrokeGeometry.avgCosineSimilarity(
      userResampled.reversed.toList(), expectedResampled,
    );
    final cosine = StrokeGeometry.avgCosineSimilarity(
      userResampled, expectedResampled,
    );

    if (reversedCosine > minCosineSimilarity && reversedCosine > cosine) {
       // Check if the reversed shape is a decent match to the expected median
       final revAvgDist = StrokeGeometry.avgDistToPolyline(deduped.reversed.toList(), expectedMedian);
       if (revAvgDist <= avgDistanceThreshold) {
         return const StrokeValidationResult.reject(StrokeRejection.wrongDirection);
       }
    }

    // Check start distance.
    final startDist = (deduped.first - expectedMedian.first).distance;
    if (startDist > startEndThreshold) {
      // Could be wrong order — check lookahead.
      final wrongOrderResult = _checkWrongOrder(
        deduped, character, expectedIndex,
      );
      if (wrongOrderResult != null) return wrongOrderResult;
      return const StrokeValidationResult.reject(StrokeRejection.wrongStart);
    }

    // Check end distance.
    final endDist = (deduped.last - expectedMedian.last).distance;
    if (endDist > startEndThreshold) {
      return const StrokeValidationResult.reject(StrokeRejection.wrongEnd);
    }

    if (cosine < minCosineSimilarity) {
      return const StrokeValidationResult.reject(StrokeRejection.wrongDirection);
    }

    // Check average distance to median.
    final avgDist = StrokeGeometry.avgDistToPolyline(deduped, expectedMedian);
    if (avgDist > avgDistanceThreshold) {
      return const StrokeValidationResult.reject(StrokeRejection.inaccurate);
    }

    // Check normalized Frechet distance.
    final frechet = StrokeGeometry.frechetDistance(
      userResampled, expectedResampled,
    );
    final normalizedFrechet = frechet / _diagonal;
    if (normalizedFrechet > maxNormalizedFrechet) {
      return const StrokeValidationResult.reject(StrokeRejection.inaccurate);
    }

    // Compute quality score from the metrics.
    final score = _computeScore(
      startDist: startDist,
      endDist: endDist,
      avgDist: avgDist,
      cosine: cosine,
      normalizedFrechet: normalizedFrechet,
    );

    return StrokeValidationResult.accept(score);
  }

  /// Check if the user drew a later stroke (wrong order).
  StrokeValidationResult? _checkWrongOrder(
    List<Offset> userPoints,
    StrokeCharacter character,
    int expectedIndex,
  ) {
    final limit = (expectedIndex + 1 + lookaheadCount)
        .clamp(0, character.strokeCount);
    for (var i = expectedIndex + 1; i < limit; i++) {
      final median = _medianToOffsets(character.strokes[i].median);
      final startDist = (userPoints.first - median.first).distance;
      final endDist = (userPoints.last - median.last).distance;
      if (startDist < startEndThreshold && endDist < startEndThreshold) {
        return const StrokeValidationResult.reject(StrokeRejection.wrongOrder);
      }
    }
    return null;
  }

  /// Convert model median points to Offsets.
  static List<Offset> _medianToOffsets(List<StrokePoint> median) {
    return median.map((p) => Offset(p.x, p.y)).toList(growable: false);
  }

  /// Compute a 0–1 quality score from validation metrics.
  double _computeScore({
    required double startDist,
    required double endDist,
    required double avgDist,
    required double cosine,
    required double normalizedFrechet,
  }) {
    // Each component normalized to 0–1 (1 = perfect).
    final startScore = (1.0 - startDist / startEndThreshold).clamp(0.0, 1.0);
    final endScore = (1.0 - endDist / startEndThreshold).clamp(0.0, 1.0);
    final distScore = (1.0 - avgDist / avgDistanceThreshold).clamp(0.0, 1.0);
    final cosineScore = ((cosine + 1.0) / 2.0).clamp(0.0, 1.0);
    final frechetScore =
        (1.0 - normalizedFrechet / maxNormalizedFrechet).clamp(0.0, 1.0);

    // Weighted average.
    return (startScore * 0.15 +
            endScore * 0.15 +
            distScore * 0.3 +
            cosineScore * 0.2 +
            frechetScore * 0.2)
        .clamp(0.0, 1.0);
  }
}
