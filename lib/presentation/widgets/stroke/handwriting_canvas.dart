import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/stroke_character.dart';
import 'stroke_order_painter.dart';

/// Captures user handwriting over a [StrokeCharacter] guide.
///
/// Normalizes local touch coordinates into the 1024x1024 viewBox space
/// before emitting them via [onStrokeComplete].
class HandwritingCanvas extends StatefulWidget {
  final StrokeCharacter character;
  final int completedStrokeCount;
  final ValueChanged<List<Offset>> onStrokeComplete;
  final Color inkColor;
  final Color outlineColor;
  final Color guidelineColor;
  final Color userStrokeColor;

  const HandwritingCanvas({
    super.key,
    required this.character,
    required this.completedStrokeCount,
    required this.onStrokeComplete,
    this.inkColor = const Color(0xFF333333),
    this.outlineColor = const Color(0xFFCCCCCC),
    this.guidelineColor = const Color(0xFFE0E0E0),
    this.userStrokeColor = const Color(0xFF1565C0),
  });

  @override
  State<HandwritingCanvas> createState() => HandwritingCanvasState();
}

class HandwritingCanvasState extends State<HandwritingCanvas> {
  final List<Offset> _currentStroke = [];
  Size _lastSize = Size.zero;

  /// Clear the currently drawn stroke from the screen.
  void clear() {
    setState(() {
      _currentStroke.clear();
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke.clear();
      _currentStroke.add(_normalize(details.localPosition));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastSize.isEmpty) return;
    setState(() {
      _currentStroke.add(_normalize(details.localPosition));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke.length >= 2) {
      widget.onStrokeComplete(List.of(_currentStroke));
    } else {
      clear();
    }
  }

  /// Converts local widget coordinates to 1024x1024 viewBox space.
  Offset _normalize(Offset local) {
    if (_lastSize.isEmpty) return local;

    final vbW = widget.character.viewBox[2].toDouble();
    final vbH = widget.character.viewBox[3].toDouble();
    final scale = math.min(_lastSize.width / vbW, _lastSize.height / vbH);
    final dx = (_lastSize.width - vbW * scale) / 2;
    final dy = (_lastSize.height - vbH * scale) / 2;

    return Offset(
      (local.dx - dx) / scale,
      (local.dy - dy) / scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          // Prevent gesture from being canceled by scroll views.
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            size: Size.infinite,
            painter: StrokeOrderPainter(
              character: widget.character,
              completedStrokeCount: widget.completedStrokeCount,
              activeProgress: 0.0,
              userStrokePoints: _currentStroke.isEmpty ? null : _currentStroke,
              inkColor: widget.inkColor,
              outlineColor: widget.outlineColor,
              guidelineColor: widget.guidelineColor,
              userStrokeColor: widget.userStrokeColor,
            ),
          ),
        );
      },
    );
  }
}
