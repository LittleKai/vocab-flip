import 'package:flutter/material.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/flashcard.dart';

class TypeAnswerCard extends StatefulWidget {
  final Flashcard card;
  final Function(bool) onAnswerSelected;

  const TypeAnswerCard({
    super.key,
    required this.card,
    required this.onAnswerSelected,
  });

  @override
  State<TypeAnswerCard> createState() => _TypeAnswerCardState();
}

class _TypeAnswerCardState extends State<TypeAnswerCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasAnswered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(TypeAnswerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _controller.clear();
      _hasAnswered = false;
      _isCorrect = false;
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_hasAnswered) return;
    
    final input = _controller.text.trim().toLowerCase();
    final target = widget.card.back.trim().toLowerCase();
    
    setState(() {
      _isCorrect = input == target;
      _hasAnswered = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        widget.onAnswerSelected(_isCorrect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    Color inputColor = Theme.of(context).colorScheme.onSurface;
    if (_hasAnswered) {
      inputColor = _isCorrect ? AppColors.success : AppColors.error;
    }

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
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !_hasAnswered,
                    onSubmitted: (_) => _checkAnswer(),
                    style: TextStyle(color: inputColor, fontSize: 20),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: l10n.typeYourAnswer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _hasAnswered 
                            ? (_isCorrect ? AppColors.success : AppColors.error)
                            : Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _hasAnswered 
                            ? (_isCorrect ? AppColors.success : AppColors.error)
                            : Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_hasAnswered && !_isCorrect)
                    Text(
                      widget.card.back,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (!_hasAnswered)
                    ElevatedButton(
                      onPressed: _checkAnswer,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: Text(l10n.check),
                    ),
                  if (_hasAnswered)
                    Text(
                      _isCorrect ? l10n.correct : l10n.incorrect,
                      style: TextStyle(
                        color: _isCorrect ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
