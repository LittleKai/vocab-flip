import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/spaced_repetition.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/services/stroke_validation_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/stroke_practice_provider.dart';
import '../stroke/handwriting_canvas.dart';
import '../stroke/stroke_order_animation.dart';
import '../stroke/stroke_order_painter.dart';

class WritingPracticeCard extends StatefulWidget {
  final Flashcard card;
  final ValueChanged<ReviewRating> onComplete;

  const WritingPracticeCard({
    super.key,
    required this.card,
    required this.onComplete,
  });

  @override
  State<WritingPracticeCard> createState() => _WritingPracticeCardState();
}

class _WritingPracticeCardState extends State<WritingPracticeCard> {
  bool _isReplaying = false;
  bool _showHint = false;
  final GlobalKey<HandwritingCanvasState> _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<StrokePracticeProvider>();

    if (provider.state == StrokePracticeState.loading || provider.state == StrokePracticeState.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state == StrokePracticeState.error || provider.currentCharacter == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(l10n.strokeDataUnavailable, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.onComplete(ReviewRating.again),
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    final char = provider.currentCharacter!;
    final isDone = provider.completedStrokeCount >= char.strokes.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.card.front,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (widget.card.frontPhonetic != null && widget.card.frontPhonetic!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '[${widget.card.frontPhonetic}]',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          
          // Feedback Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 24,
              child: _buildFeedback(context, provider.lastValidationResult),
            ),
          ),

          // Canvas
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        if (_isReplaying)
                          StrokeOrderAnimation(
                            key: ValueKey('replay_${provider.replayKey}'),
                            character: char,
                            onCompleted: () {
                              if (mounted) {
                                setState(() {
                                  _isReplaying = false;
                                });
                              }
                            },
                          )
                        else
                          HandwritingCanvas(
                            key: _canvasKey,
                            character: char,
                            completedStrokeCount: provider.completedStrokeCount,
                            onStrokeComplete: isDone ? (_) {} : (points) async {
                              final currentProvider = context.read<StrokePracticeProvider>();
                              final res = await currentProvider.submitStroke(points);
                              if (mounted && !res.accepted) {
                                _canvasKey.currentState?.clear();
                              }
                              
                              if (mounted && currentProvider.completedStrokeCount >= char.strokes.length) {
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  if (mounted) {
                                    widget.onComplete(currentProvider.ratingForCompletion());
                                  }
                                });
                              }
                            },
                          ),
                          
                        // Hint overlay: just show the current stroke faintly by passing completed + 1 and progress 0, wait, progress 1.
                        if (_showHint && !_isReplaying && !isDone)
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: StrokeOrderPainter(
                                character: char,
                                completedStrokeCount: provider.completedStrokeCount + 1,
                                activeProgress: 1.0,
                                inkColor: Colors.blue.withValues(alpha: 0.3), // Hint color
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    provider.resetPractice();
                    _canvasKey.currentState?.clear();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.resetStroke,
                ),
                IconButton(
                  onPressed: () {
                    provider.replayCurrentStroke();
                    setState(() {
                      _isReplaying = true;
                      _showHint = false;
                    });
                  },
                  icon: const Icon(Icons.play_arrow),
                  tooltip: l10n.replayStroke,
                ),
                IconButton(
                  onPressed: isDone ? null : () {
                    setState(() {
                      _showHint = true;
                    });
                  },
                  icon: const Icon(Icons.lightbulb_outline),
                  tooltip: l10n.showHint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, StrokeValidationResult? result) {
    if (result == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    if (result.accepted) {
      return Text(
        l10n.correctStroke,
        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
      );
    }

    String msg = l10n.tryAgain;
    switch (result.rejection) {
      case StrokeRejection.wrongDirection:
        msg = l10n.wrongDirection;
        break;
      case StrokeRejection.wrongOrder:
        msg = l10n.wrongOrder;
        break;
      case StrokeRejection.wrongStart:
      case StrokeRejection.wrongEnd:
      case StrokeRejection.inaccurate:
      case StrokeRejection.tooShort:
      case null:
        msg = l10n.tryAgain;
        break;
    }

    return Text(
      msg,
      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
    );
  }
}
