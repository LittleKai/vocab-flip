import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  widget.card.front,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final text = entry.value;

                  Color backgroundColor = Colors.transparent;
                  Color textColor = Theme.of(context).colorScheme.onSurface;
                  Color borderColor = Theme.of(context).dividerColor;

                  if (_hasAnswered) {
                    if (text == widget.card.back) {
                      backgroundColor = AppColors.success.withOpacity(0.2);
                      borderColor = AppColors.success;
                      textColor = AppColors.success;
                    } else if (index == _selectedIndex) {
                      backgroundColor = AppColors.error.withOpacity(0.2);
                      borderColor = AppColors.error;
                      textColor = AppColors.error;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: () => _handleSelect(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 18,
                              color: textColor,
                              fontWeight: _hasAnswered && (text == widget.card.back || index == _selectedIndex) 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
