import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../data/models/stroke_character.dart';
import 'stroke_order_painter.dart';

/// Animates stroke-by-stroke reveal of a [StrokeCharacter].
///
/// Each stroke is revealed by animating a thick median line clipped to the
/// stroke outline. After the active stroke completes, [completedStrokeCount]
/// increments and the next stroke begins.
class StrokeOrderAnimation extends StatefulWidget {
  final StrokeCharacter character;
  final Duration strokeDuration;
  final Duration pauseBetweenStrokes;
  final Color inkColor;
  final Color outlineColor;
  final Color guidelineColor;
  final VoidCallback? onCompleted;

  const StrokeOrderAnimation({
    super.key,
    required this.character,
    this.strokeDuration = const Duration(milliseconds: 600),
    this.pauseBetweenStrokes = const Duration(milliseconds: 200),
    this.inkColor = const Color(0xFF333333),
    this.outlineColor = const Color(0xFFCCCCCC),
    this.guidelineColor = const Color(0xFFE0E0E0),
    this.onCompleted,
  });

  @override
  State<StrokeOrderAnimation> createState() => StrokeOrderAnimationState();
}

/// Public state so callers can invoke [replay].
class StrokeOrderAnimationState extends State<StrokeOrderAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Path> _parsedPaths;
  int _completedStrokeCount = 0;

  /// Current animation progress exposed for testing.
  double get activeProgress => _controller.value;

  /// Number of strokes fully revealed.
  int get completedStrokeCount => _completedStrokeCount;

  @override
  void initState() {
    super.initState();
    _parsedPaths = widget.character.strokes
        .map((s) => parseSvgPathData(s.path))
        .toList(growable: false);
    _controller = AnimationController(
      vsync: this,
      duration: widget.strokeDuration,
    )..addStatusListener(_onStatus);
    _controller.forward();
  }

  @override
  void didUpdateWidget(StrokeOrderAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      _parsedPaths = widget.character.strokes
          .map((s) => parseSvgPathData(s.path))
          .toList(growable: false);
      replay();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    final nextCompleted = _completedStrokeCount + 1;
    if (nextCompleted >= widget.character.strokeCount) {
      // All strokes done.
      setState(() => _completedStrokeCount = nextCompleted);
      widget.onCompleted?.call();
      return;
    }

    setState(() => _completedStrokeCount = nextCompleted);
    Future.delayed(widget.pauseBetweenStrokes, () {
      if (!mounted) return;
      _controller
        ..reset()
        ..forward();
    });
  }

  /// Reset animation to the beginning and replay all strokes.
  void replay() {
    setState(() => _completedStrokeCount = 0);
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: StrokeOrderPainter(
              character: widget.character,
              completedStrokeCount: _completedStrokeCount,
              activeProgress: _controller.value,
              inkColor: widget.inkColor,
              outlineColor: widget.outlineColor,
              guidelineColor: widget.guidelineColor,
              parsedPaths: _parsedPaths,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
