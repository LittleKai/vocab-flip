import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    if (provider.state == StrokePracticeState.loading ||
        provider.state == StrokePracticeState.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state == StrokePracticeState.error ||
        provider.currentCharacter == null) {
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
    final isCharDone = provider.completedStrokeCount >= char.strokes.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.card.front,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (widget.card.frontPhonetic != null &&
                        widget.card.frontPhonetic!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '[${widget.card.frontPhonetic}]',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
                if (provider.supportedCharacterCount > 1 ||
                    provider.unsupportedCharacterCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.characterProgress(provider.activeCharacterIndex + 1,
                        provider.supportedCharacterCount),
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500),
                  ),
                  if (provider.unsupportedCharacterCount > 0)
                    Text(
                      l10n.skippedUnsupported(
                          provider.unsupportedCharacterCount),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                            key: ValueKey(
                                'replay_${provider.activeCharacterIndex}_${provider.replayKey}'),
                            character: char,
                            strokeDuration: const Duration(milliseconds: 300),
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
                            onStrokeComplete: isCharDone
                                ? (_) {}
                                : (points) async {
                                    final currentProvider =
                                        context.read<StrokePracticeProvider>();
                                    final res = await currentProvider
                                        .submitStroke(points);
                                    if (mounted && !res.accepted) {
                                      HapticFeedback.heavyImpact()
                                          .catchError((_) {});
                                      _canvasKey.currentState?.clear();
                                    } else if (mounted && res.accepted) {
                                      HapticFeedback.lightImpact()
                                          .catchError((_) {});
                                      // Accepted strokes are now reflected by the guide; clear only transient user ink.
                                      _canvasKey.currentState?.clear();
                                    }

                                    if (mounted &&
                                        currentProvider.isWordComplete) {
                                      Future.delayed(
                                          const Duration(milliseconds: 500),
                                          () {
                                        if (mounted) {
                                          widget.onComplete(currentProvider
                                              .ratingForCompletion());
                                        }
                                      });
                                    }
                                  },
                          ),
                        if (_showHint && !_isReplaying && !isCharDone)
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: StrokeOrderPainter(
                                character: char,
                                completedStrokeCount:
                                    provider.completedStrokeCount + 1,
                                activeProgress: 1.0,
                                inkColor: Colors.blue.withValues(alpha: 0.3),
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
                  onPressed: isCharDone
                      ? null
                      : () {
                          setState(() {
                            _showHint = true;
                          });
                        },
                  icon: const Icon(Icons.lightbulb_outline),
                  tooltip: l10n.showHint,
                ),
                PopupMenuButton<StrokeValidationProfile>(
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.validationProfile,
                  onSelected: (profile) =>
                      provider.setValidationProfile(profile),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: StrokeValidationProfile.gentle,
                      child: Row(
                        children: [
                          if (provider.validationProfile ==
                              StrokeValidationProfile.gentle)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          const Icon(Icons.sentiment_satisfied_alt,
                              size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(l10n.gentle,
                              style:
                                  const TextStyle(color: AppColors.success)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: StrokeValidationProfile.standard,
                      child: Row(
                        children: [
                          if (provider.validationProfile ==
                              StrokeValidationProfile.standard)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          const Icon(Icons.sentiment_neutral,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(l10n.standardPractice,
                              style:
                                  const TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: StrokeValidationProfile.strict,
                      child: Row(
                        children: [
                          if (provider.validationProfile ==
                              StrokeValidationProfile.strict)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          const Icon(Icons.sentiment_very_dissatisfied,
                              size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(l10n.strict,
                              style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
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
        style: const TextStyle(
            color: AppColors.success, fontWeight: FontWeight.bold),
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
        msg = l10n.wrongStart;
        break;
      case StrokeRejection.wrongEnd:
        msg = l10n.wrongEnd;
        break;
      case StrokeRejection.inaccurate:
        msg = l10n.inaccurateStroke;
        break;
      case StrokeRejection.tooShort:
        msg = l10n.strokeTooShort;
        break;
      case null:
        msg = l10n.tryAgain;
        break;
    }

    return Text(
      msg,
      style:
          const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
    );
  }
}
