import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/flashcard.dart';

class MultipleChoiceCard extends StatefulWidget {
  final Flashcard card;
  final List<Flashcard> allCards;
  final Function(bool) onAnswerSelected;

  const MultipleChoiceCard({
    super.key,
    required this.card,
    required this.allCards,
    required this.onAnswerSelected,
  });

  @override
  State<MultipleChoiceCard> createState() => _MultipleChoiceCardState();
}

class _MultipleChoiceCardState extends State<MultipleChoiceCard> {
  late List<String> _options;
  int? _selectedIndex;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  @override
  void didUpdateWidget(MultipleChoiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _generateOptions();
      _selectedIndex = null;
      _hasAnswered = false;
    }
  }

  void _generateOptions() {
    final correctBack = widget.card.back;
    final otherCards = widget.allCards.where((c) => c.id != widget.card.id).toList();
    otherCards.shuffle(Random());

    final distractors = otherCards.take(3).map((c) => c.back).toSet().toList();
    
    // Fill up to 3 distractors if there aren't enough cards
    int counter = 1;
    while (distractors.length < 3) {
      distractors.add('Distractor $counter');
      counter++;
    }

    _options = [...distractors.take(3), correctBack];
    _options.shuffle(Random());
  }

  void _handleSelect(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedIndex = index;
      _hasAnswered = true;
    });

    final isCorrect = _options[index] == widget.card.back;
    
    // Slight delay to show the color change before moving on
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        widget.onAnswerSelected(isCorrect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    final double questionFontSize = isDesktop ? 120.0 : 64.0;
    final double optionFontSize = isDesktop ? 22.0 : 16.0;
    final double optionNumberSize = isDesktop ? 20.0 : 14.0;
    final double optionNumberBoxSize = isDesktop ? 40.0 : 32.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.card.front,
                      style: TextStyle(
                        fontSize: questionFontSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                flex: 4, // Gave a bit more flex to options to fit larger text
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final text = entry.value;

                      final baseColors = [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.accent,
                        Colors.purple,
                      ];
                      final optionColor = baseColors[index % baseColors.length];

                      Color backgroundColor = optionColor.withValues(alpha: 0.1);
                      Color textColor = Theme.of(context).colorScheme.onSurface;
                      Color borderColor = optionColor.withValues(alpha: 0.3);

                      if (_hasAnswered) {
                        if (text == widget.card.back) {
                          backgroundColor = AppColors.success.withValues(alpha: 0.2);
                          borderColor = AppColors.success;
                          textColor = AppColors.success;
                        } else if (index == _selectedIndex) {
                          backgroundColor = AppColors.error.withValues(alpha: 0.2);
                          borderColor = AppColors.error;
                          textColor = AppColors.error;
                        } else {
                          backgroundColor = Colors.transparent;
                          borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.5);
                          textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: () => _handleSelect(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: optionNumberBoxSize,
                                    height: optionNumberBoxSize,
                                    decoration: BoxDecoration(
                                      color: _hasAnswered ? Colors.transparent : optionColor.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: _hasAnswered ? null : Border.all(color: optionColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: optionNumberSize,
                                          fontWeight: FontWeight.bold,
                                          color: _hasAnswered ? textColor : optionColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: optionFontSize,
                                        color: textColor,
                                        fontWeight: _hasAnswered && (text == widget.card.back || index == _selectedIndex) 
                                          ? FontWeight.bold 
                                          : FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
