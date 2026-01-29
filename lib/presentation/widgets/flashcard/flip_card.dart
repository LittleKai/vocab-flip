import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
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

class FlashcardFace extends StatelessWidget {
  final String text;
  final String? phonetic;
  final String? subtitle;
  final String? imageUrl;
  final bool isFront;
  final VoidCallback? onAudioPlay;
  final Color? backgroundColor;

  const FlashcardFace({
    super.key,
    required this.text,
    this.phonetic,
    this.subtitle,
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
            color: Colors.black.withOpacity(0.1),
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
                color: AppColors.primary.withOpacity(0.1),
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
                color: AppColors.secondary.withOpacity(0.1),
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
          if (_hasImage) ...[
            Builder(
              builder: (context) {
                final maxWidth = context.watch<SettingsProvider>().flashcardImageMaxWidth.toDouble();
                return ClipRRect(
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
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (phonetic != null && phonetic!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              phonetic!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Tap to flip',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}
