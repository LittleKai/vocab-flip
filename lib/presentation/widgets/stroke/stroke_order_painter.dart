import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../data/models/stroke_character.dart';

/// Paints character strokes with outline, filled, and median-reveal states.
///
/// Takes normalized stroke data (viewBox coordinate space) and scales to
/// fit the available canvas, maintaining aspect ratio.
class StrokeOrderPainter extends CustomPainter {
  final StrokeCharacter character;
  final int completedStrokeCount;
  final double activeProgress;
  final List<Offset>? userStrokePoints;
  final Color inkColor;
  final Color outlineColor;
  final Color guidelineColor;
  final Color userStrokeColor;
  final List<Path> _parsedPaths;

  StrokeOrderPainter({
    required this.character,
    required this.completedStrokeCount,
    required this.activeProgress,
    this.userStrokePoints,
    this.inkColor = const Color(0xFF333333),
    this.outlineColor = const Color(0xFFCCCCCC),
    this.guidelineColor = const Color(0xFFE0E0E0),
    this.userStrokeColor = const Color(0xFF1565C0),
    List<Path>? parsedPaths,
  }) : _parsedPaths = parsedPaths ??
            character.strokes
                .map((s) => _tryParsePath(s.path))
                .toList(growable: false);

  /// Parse SVG path data, returning an empty [Path] on invalid input.
  static Path _tryParsePath(String svgPath) {
    try {
      return parseSvgPathData(svgPath);
    } on StateError {
      return Path();
    } on FormatException {
      return Path();
    }
  }

  /// Pre-parsed paths, exposed for caching by the animation widget.
  List<Path> get parsedPaths => _parsedPaths;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final vbW = character.viewBox[2].toDouble();
    final vbH = character.viewBox[3].toDouble();
    final scale = math.min(size.width / vbW, size.height / vbH);
    final dx = (size.width - vbW * scale) / 2;
    final dy = (size.height - vbH * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    
    // MakeMeAHanzi / AnimCJK có trục Y hướng lên
    if (character.isYUp) {
      canvas.scale(scale, -scale);
      canvas.translate(0, -vbH);
    } else {
      canvas.scale(scale, scale);
    }

    _drawGuidelines(canvas, vbW, vbH);

    for (var i = 0; i < character.strokes.length; i++) {
      if (i < completedStrokeCount) {
        _drawFilled(canvas, i, inkColor);
      } else if (i == completedStrokeCount && activeProgress > 0.0) {
        _drawOutline(canvas, i);
        _drawActiveReveal(canvas, i);
      } else {
        _drawOutline(canvas, i);
      }
    }

    if (userStrokePoints != null && userStrokePoints!.length >= 2) {
      _drawUserStroke(canvas);
    }

    canvas.restore();
  }

  void _drawGuidelines(Canvas canvas, double w, double h) {
    final borderPaint = Paint()
      ..color = guidelineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), borderPaint);

    final innerPaint = Paint()
      ..color = guidelineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    // Center cross
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), innerPaint);
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), innerPaint);
    // Diagonals
    canvas.drawLine(Offset.zero, Offset(w, h), innerPaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), innerPaint);
  }

  void _drawFilled(Canvas canvas, int index, Color color) {
    canvas.drawPath(_parsedPaths[index], Paint()..color = color);
  }

  void _drawOutline(Canvas canvas, int index) {
    canvas.drawPath(_parsedPaths[index], Paint()..color = outlineColor);
  }

  void _drawActiveReveal(Canvas canvas, int index) {
    final median = character.strokes[index].median;
    if (median.length < 2) return;

    canvas.save();
    canvas.clipPath(_parsedPaths[index]);

    canvas.drawPath(
      _partialMedianPath(median, activeProgress),
      Paint()
        ..color = inkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 150.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  /// Builds a polyline along [points] up to the fraction [progress].
  Path _partialMedianPath(List<StrokePoint> points, double progress) {
    final path = Path()..moveTo(points[0].x, points[0].y);

    var totalLen = 0.0;
    for (var i = 1; i < points.length; i++) {
      totalLen += _dist(points[i - 1], points[i]);
    }

    final target = totalLen * progress.clamp(0.0, 1.0);
    var acc = 0.0;

    for (var i = 1; i < points.length; i++) {
      final seg = _dist(points[i - 1], points[i]);
      if (acc + seg >= target) {
        final t = seg > 0 ? (target - acc) / seg : 0.0;
        path.lineTo(
          points[i - 1].x + (points[i].x - points[i - 1].x) * t,
          points[i - 1].y + (points[i].y - points[i - 1].y) * t,
        );
        return path;
      }
      path.lineTo(points[i].x, points[i].y);
      acc += seg;
    }

    return path;
  }

  static double _dist(StrokePoint a, StrokePoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// User stroke points are in viewBox (1024) coordinate space.
  void _drawUserStroke(Canvas canvas) {
    final pts = userStrokePoints!;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = userStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(StrokeOrderPainter oldDelegate) =>
      character != oldDelegate.character ||
      completedStrokeCount != oldDelegate.completedStrokeCount ||
      activeProgress != oldDelegate.activeProgress ||
      userStrokePoints != oldDelegate.userStrokePoints ||
      inkColor != oldDelegate.inkColor ||
      outlineColor != oldDelegate.outlineColor ||
      guidelineColor != oldDelegate.guidelineColor ||
      userStrokeColor != oldDelegate.userStrokeColor;
}
