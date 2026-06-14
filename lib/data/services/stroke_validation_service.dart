import 'dart:ui';

import '../../core/utils/advanced_stroke_matcher.dart';
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

/// Validation leniency profiles.
enum StrokeValidationProfile {
  gentle,
  standard,
  strict,
}

/// Holds threshold values for stroke validation.
class StrokeValidationOptions {
  final double minLengthAbsolute;
  final double minLengthRatio;
  final double startEndThreshold;
  final double avgDistanceThreshold;
  final double minCosineSimilarity;
  final double maxNormalizedFrechet;

  const StrokeValidationOptions({
    required this.minLengthAbsolute,
    required this.minLengthRatio,
    required this.startEndThreshold,
    required this.avgDistanceThreshold,
    required this.minCosineSimilarity,
    required this.maxNormalizedFrechet,
  });

  static const StrokeValidationOptions gentle = StrokeValidationOptions(
    minLengthAbsolute: 20.0,
    minLengthRatio: 0.20,
    startEndThreshold: 400.0,
    avgDistanceThreshold: 500.0,
    minCosineSimilarity: -0.2,
    maxNormalizedFrechet: 0.6,
  );

  static const StrokeValidationOptions standard = StrokeValidationOptions(
    minLengthAbsolute: 30.0,
    minLengthRatio: 0.35,
    startEndThreshold: 250.0,
    avgDistanceThreshold: 350.0,
    minCosineSimilarity: 0.0,
    maxNormalizedFrechet: 0.4,
  );

  static const StrokeValidationOptions strict = StrokeValidationOptions(
    minLengthAbsolute: 40.0,
    minLengthRatio: 0.50,
    startEndThreshold: 150.0,
    avgDistanceThreshold: 200.0,
    minCosineSimilarity: 0.3,
    maxNormalizedFrechet: 0.25,
  );
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
    StrokeValidationProfile profile = StrokeValidationProfile.standard,
  }) {
    if (expectedIndex < 0 || expectedIndex >= character.strokeCount) {
      return const StrokeValidationResult.reject(StrokeRejection.inaccurate);
    }

    final StrokeValidationOptions options;
    switch (profile) {
      case StrokeValidationProfile.gentle:
        options = StrokeValidationOptions.gentle;
        break;
      case StrokeValidationProfile.standard:
        options = StrokeValidationOptions.standard;
        break;
      case StrokeValidationProfile.strict:
        options = StrokeValidationOptions.strict;
        break;
    }

    // Dedupe user input.
    final deduped =
        StrokeGeometry.dedupe(userPoints, threshold: _dedupeThreshold);
    if (deduped.length < 2) {
      return const StrokeValidationResult.reject(StrokeRejection.tooShort);
    }

    // Check absolute length.
    final userLen = StrokeGeometry.polylineLength(deduped);
    if (userLen < options.minLengthAbsolute) {
      return const StrokeValidationResult.reject(StrokeRejection.tooShort);
    }

    final expected = character.strokes[expectedIndex];
    final expectedMedian = _medianToOffsets(expected.median);
    final expectedLen = StrokeGeometry.polylineLength(expectedMedian);

    // Check length ratio.
    if (expectedLen > 0 && userLen / expectedLen < options.minLengthRatio) {
      return const StrokeValidationResult.reject(StrokeRejection.tooShort);
    }

    // Resample both for shape/direction comparison.
    final expectedResampled =
        StrokeGeometry.resample(expectedMedian, resampleCount);

    // Apply advanced trimming to ignore hooks and over-extensions before strict checks.
    final trimmedUser = profile == StrokeValidationProfile.strict 
        ? deduped 
        : AdvancedStrokeMatcher.trimHooksAndAlign(deduped, expectedMedian);

    final userResampled = StrokeGeometry.resample(trimmedUser, resampleCount);

    // Check if it's drawn in reverse.
    final reversedCosine = StrokeGeometry.avgCosineSimilarity(
      userResampled.reversed.toList(),
      expectedResampled,
    );
    final cosine = StrokeGeometry.avgCosineSimilarity(
      userResampled,
      expectedResampled,
    );

    if (reversedCosine > options.minCosineSimilarity &&
        reversedCosine > cosine) {
      // Check if the reversed shape is a decent match to the expected median
      final revAvgDist = StrokeGeometry.avgDistToPolyline(
          deduped.reversed.toList(), expectedMedian);
      if (revAvgDist <= options.avgDistanceThreshold) {
        return const StrokeValidationResult.reject(
            StrokeRejection.wrongDirection);
      }
    }

    // Check start distance.
    final startDist = (trimmedUser.first - expectedMedian.first).distance;
    if (startDist > options.startEndThreshold) {
      // Could be wrong order — check lookahead.
      final wrongOrderResult = _checkWrongOrder(
        trimmedUser,
        character,
        expectedIndex,
        options.startEndThreshold,
      );
      if (wrongOrderResult != null) return wrongOrderResult;
      return const StrokeValidationResult.reject(StrokeRejection.wrongStart);
    }

    // Check end distance.
    final endDist = (trimmedUser.last - expectedMedian.last).distance;
    if (endDist > options.startEndThreshold) {
      return const StrokeValidationResult.reject(StrokeRejection.wrongEnd);
    }

    if (cosine < options.minCosineSimilarity) {
      return const StrokeValidationResult.reject(
          StrokeRejection.wrongDirection);
    }

    // Check average distance to median.
    final avgDist = StrokeGeometry.avgDistToPolyline(trimmedUser, expectedMedian);
    if (avgDist > options.avgDistanceThreshold) {
      return const StrokeValidationResult.reject(StrokeRejection.inaccurate);
    }

    // Check normalized Frechet distance.
    final frechet = StrokeGeometry.frechetDistance(
      userResampled,
      expectedResampled,
    );
    final normalizedFrechet = frechet / _diagonal;
    if (normalizedFrechet > options.maxNormalizedFrechet) {
      return const StrokeValidationResult.reject(StrokeRejection.inaccurate);
    }

    // Compute quality score from the metrics.
    final score = _computeScore(
      startDist: startDist,
      endDist: endDist,
      avgDist: avgDist,
      cosine: cosine,
      normalizedFrechet: normalizedFrechet,
      options: options,
    );

    return StrokeValidationResult.accept(score);
  }

  /// Check if the user drew a later stroke (wrong order).
  StrokeValidationResult? _checkWrongOrder(
    List<Offset> userPoints,
    StrokeCharacter character,
    int expectedIndex,
    double startEndThreshold,
  ) {
    final limit =
        (expectedIndex + 1 + lookaheadCount).clamp(0, character.strokeCount);
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
    required StrokeValidationOptions options,
  }) {
    // Each component normalized to 0–1 (1 = perfect).
    final startScore =
        (1.0 - startDist / options.startEndThreshold).clamp(0.0, 1.0);
    final endScore =
        (1.0 - endDist / options.startEndThreshold).clamp(0.0, 1.0);
    final distScore =
        (1.0 - avgDist / options.avgDistanceThreshold).clamp(0.0, 1.0);
    final cosineScore = ((cosine + 1.0) / 2.0).clamp(0.0, 1.0);
    final frechetScore =
        (1.0 - normalizedFrechet / options.maxNormalizedFrechet)
            .clamp(0.0, 1.0);

    // Weighted average.
    return (startScore * 0.15 +
            endScore * 0.15 +
            distScore * 0.3 +
            cosineScore * 0.2 +
            frechetScore * 0.2)
        .clamp(0.0, 1.0);
  }
}
