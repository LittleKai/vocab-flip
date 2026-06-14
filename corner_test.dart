import 'dart:math' as math;

class Offset {
  final double dx;
  final double dy;
  const Offset(this.dx, this.dy);
  double get distance => math.sqrt(dx * dx + dy * dy);
  Offset operator -(Offset other) => Offset(dx - other.dx, dy - other.dy);
  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);
  Offset operator *(double operand) => Offset(dx * operand, dy * operand);
  @override
  String toString() => 'Offset(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})';
}

List<Offset> resample(List<Offset> points, double spacing) {
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
  
  if ((result.last - points.last).distance > spacing * 0.5) {
     result.add(points.last);
  }
  return result;
}

List<int> getCorners(List<Offset> points) {
  // 1. Resample to standard spacing
  // Usually the diagonal of bounding box / 40
  // Here we assume input is normalized to 1024x1024, so diagonal ~ 1448
  // Let's use a fixed spacing like 40 for resampling.
  final S = 40.0; 
  final resampled = resample(points, S);
  if (resampled.length < 6) return [0, resampled.length - 1];

  final int W = 3;
  final straws = List<double>.filled(resampled.length, 0.0);

  for (var i = W; i < resampled.length - W; i++) {
    straws[i] = (resampled[i - W] - resampled[i + W]).distance;
  }

  final candidates = <int>[];
  var totalStraws = <double>[];
  for (var i = W; i < resampled.length - W; i++) {
    totalStraws.add(straws[i]);
  }
  totalStraws.sort();
  final median = totalStraws.length > 0 ? totalStraws[totalStraws.length ~/ 2] : 0.0;
  final threshold = median * 0.95;

  for (var i = W; i < resampled.length - W; i++) {
    if (straws[i] < threshold) {
      // Check if it's a local minimum in a neighborhood
      bool isLocalMin = true;
      for (var j = math.max(W, i - W); j <= math.min(resampled.length - W - 1, i + W); j++) {
        if (straws[j] < straws[i]) {
          isLocalMin = false;
          break;
        }
      }
      if (isLocalMin) {
        candidates.add(i);
      }
    }
  }

  // Corners includes first and last
  final corners = <int>[0, ...candidates, resampled.length - 1];
  return corners;
}

void main() {
  // A right angle shape (L)
  final points = [
    Offset(100, 100),
    Offset(100, 200),
    Offset(100, 300),
    Offset(100, 400),
    Offset(100, 500), // Corner here
    Offset(200, 500),
    Offset(300, 500),
    Offset(400, 500),
    Offset(500, 500),
  ];
  
  final resampled = resample(points, 40.0);
  print('Resampled length: ${resampled.length}');
  final corners = getCorners(points);
  print('Corners indices: $corners');
  for (var c in corners) {
    if (c < resampled.length) print(resampled[c]);
  }
}
