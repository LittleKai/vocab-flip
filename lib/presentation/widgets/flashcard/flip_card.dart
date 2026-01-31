import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/deck.dart';
import '../../../data/models/flashcard.dart';
import '../../providers/settings_provider.dart';

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final VoidCallback? onFlip;
  final bool isFlipped;
  final FlipCardController? controller;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.onFlip,
    this.isFlipped = false,
    this.controller,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.flipDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _animation.addListener(() {
      if (_animation.value >= 0.5 && _showFront) {
        setState(() => _showFront = false);
      } else if (_animation.value < 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });

    widget.controller?._state = this;

    if (widget.isFlipped) {
      _controller.value = 1.0;
      _showFront = false;
    }
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;

    if (_controller.value == 0) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    widget.onFlip?.call();
  }

  void flipToFront() {
    if (!_showFront) {
      _controller.reverse();
    }
  }

  void flipToBack() {
    if (_showFront) {
      _controller.forward();
    }
  }

  void reset() {
    _controller.reset();
    setState(() => _showFront = true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _showFront
                ? widget.front
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

class FlipCardController {
  _FlipCardState? _state;

  void flip() => _state?._flip();
  void flipToFront() => _state?.flipToFront();
  void flipToBack() => _state?.flipToBack();
  void reset() => _state?.reset();
}

/// A structured flashcard face that displays fields based on deck configuration
class StructuredFlashcardFace extends StatelessWidget {
  final Flashcard card;
  final List<CardFieldType> fields;
  final bool showImage;
  final bool isFront;
  final Color? backgroundColor;

  const StructuredFlashcardFace({
    super.key,
    required this.card,
    required this.fields,
    required this.showImage,
    this.isFront = true,
    this.backgroundColor,
  });

  String? _getFieldValue(CardFieldType field) {
    switch (field) {
      case CardFieldType.word:
        return card.front;
      case CardFieldType.phonetic:
        return card.frontPhonetic;
      case CardFieldType.meaning:
        return card.back;
      case CardFieldType.example:
        return card.example;
      case CardFieldType.notes:
        return card.notes;
    }
  }

  bool _isMainField(CardFieldType field) {
    return field == CardFieldType.word || field == CardFieldType.meaning;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final maxWidth = settings.flashcardImageMaxWidth.toDouble();
    final mainFontSize = settings.flashcardMainFontSize.toDouble();
    final phoneticFontSize = settings.flashcardPhoneticFontSize.toDouble();
    final detailFontSize = settings.flashcardDetailFontSize.toDouble();

    final imageUrl = card.effectiveFrontImageUrl;
    final hasImage = showImage && imageUrl != null && imageUrl.isNotEmpty;
    final isImageUrl = hasImage && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Side indicator badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isFront ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFront ? 'Front' : 'Back',
              style: TextStyle(
                color: isFront ? AppColors.primary : AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),

          // Image (if enabled)
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxWidth * 0.75,
                ),
                child: isImageUrl
                    ? Image.network(
                        imageUrl,
                        width: maxWidth,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: maxWidth,
                            height: 100,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      )
                    : Image.file(
                        File(imageUrl),
                        width: maxWidth,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Fields based on configuration
          ...fields.map((field) {
            final value = _getFieldValue(field);
            if (value == null || value.isEmpty) return const SizedBox.shrink();

            if (_isMainField(field)) {
              // Main text (word or meaning)
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: mainFontSize,
                      ),
                ),
              );
            } else if (field == CardFieldType.phonetic) {
              // Phonetic text
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                        fontSize: phoneticFontSize,
                      ),
                ),
              );
            } else if (field == CardFieldType.example) {
              // Example with labeled box
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LabeledBox(
                  label: 'Example',
                  color: AppColors.primary,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: detailFontSize,
                        ),
                  ),
                ),
              );
            } else if (field == CardFieldType.notes) {
              // Notes with labeled box
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LabeledBox(
                  label: 'Note',
                  color: AppColors.secondary,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: detailFontSize,
                        ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const Spacer(),
        ],
      ),
    );
  }
}

/// Legacy FlashcardFace for backward compatibility
class FlashcardFace extends StatelessWidget {
  final String text;
  final String? phonetic;
  final String? subtitle;
  final String? note;
  final String? imageUrl;
  final bool isFront;
  final VoidCallback? onAudioPlay;
  final Color? backgroundColor;

  const FlashcardFace({
    super.key,
    required this.text,
    this.phonetic,
    this.subtitle,
    this.note,
    this.imageUrl,
    this.isFront = true,
    this.onAudioPlay,
    this.backgroundColor,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get _isImageUrl => _hasImage && (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFront)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Front',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const Spacer(),
          Builder(
            builder: (context) {
              final settings = context.watch<SettingsProvider>();
              final maxWidth = settings.flashcardImageMaxWidth.toDouble();
              final mainFontSize = settings.flashcardMainFontSize.toDouble();
              final phoneticFontSize = settings.flashcardPhoneticFontSize.toDouble();
              final detailFontSize = settings.flashcardDetailFontSize.toDouble();

              return Column(
                children: [
                  if (_hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                          maxHeight: maxWidth * 0.75, // 4:3 aspect ratio max
                        ),
                        child: _isImageUrl
                            ? Image.network(
                                imageUrl!,
                                width: maxWidth,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: maxWidth,
                                    height: 100,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(imageUrl!),
                                width: maxWidth,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: mainFontSize,
                        ),
                  ),
                  if (phonetic != null && phonetic!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      phonetic!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                            fontSize: phoneticFontSize,
                          ),
                    ),
                  ],
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _LabeledBox(
                      label: 'Example',
                      color: AppColors.primary,
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: detailFontSize,
                        ),
                      ),
                    ),
                  ],
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _LabeledBox(
                      label: 'Note',
                      color: AppColors.secondary,
                      child: Text(
                        note!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: detailFontSize,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _LabeledBox extends StatelessWidget {
  final String label;
  final Color color;
  final Widget child;

  const _LabeledBox({
    required this.label,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: child,
        ),
        Positioned(
          top: -8,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Theme.of(context).cardColor,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
