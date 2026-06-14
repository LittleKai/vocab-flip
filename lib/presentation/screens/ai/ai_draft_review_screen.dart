import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/flashcard.dart';
import '../../providers/ai_provider.dart';
import '../../providers/flashcard_provider.dart';

/// Screen to review AI-generated cards with checkboxes for bulk selection.
/// User can select/deselect individual cards and add selected ones to the deck.
class AiDraftReviewScreen extends StatefulWidget {
  final String deckId;

  const AiDraftReviewScreen({super.key, required this.deckId});

  @override
  State<AiDraftReviewScreen> createState() => _AiDraftReviewScreenState();
}

class _AiDraftReviewScreenState extends State<AiDraftReviewScreen> {
  final Set<int> _selectedIndices = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Select all by default
    final cards = context.read<AiProvider>().draftCards;
    _selectedIndices.addAll(List.generate(cards.length, (i) => i));
  }

  bool get _allSelected {
    final total = context.read<AiProvider>().draftCards.length;
    return _selectedIndices.length == total && total > 0;
  }

  void _toggleSelectAll() {
    final total = context.read<AiProvider>().draftCards.length;
    setState(() {
      if (_allSelected) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(List.generate(total, (i) => i));
      }
    });
  }

  void _toggleCard(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _addSelectedCards() async {
    if (_selectedIndices.isEmpty) return;

    setState(() => _isSaving = true);

    final aiProvider = context.read<AiProvider>();
    final flashcardProvider = context.read<FlashcardProvider>();
    final cards = aiProvider.draftCards;
    final l10n = AppLocalizations.of(context)!;

    int added = 0;
    // Sort indices to add in order
    final sortedIndices = _selectedIndices.toList()..sort();

    for (final index in sortedIndices) {
      if (index < cards.length) {
        final card = cards[index].copyWith(deckId: widget.deckId);
        await flashcardProvider.createFlashcard(card);
        added++;
      }
    }

    if (!mounted) return;

    // Reset AI provider
    aiProvider.reset();

    // Reload flashcards for the deck
    await flashcardProvider.loadFlashcards(widget.deckId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.cardsAddedSuccess(added)),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aiProvider = context.watch<AiProvider>();
    final cards = aiProvider.draftCards;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiGeneratedCards),
        actions: [
          TextButton.icon(
            onPressed: _toggleSelectAll,
            icon: Icon(
              _allSelected ? Icons.deselect : Icons.select_all,
              size: 20,
            ),
            label: Text(_allSelected ? l10n.deselectAll : l10n.selectAll),
          ),
        ],
      ),
      body: cards.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noCardsGenerated,
                    style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Info bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.primary.withOpacity(0.06),
                  child: Text(
                    l10n.selectCardsToAdd,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                ),

                // Cards list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isSelected = _selectedIndices.contains(index);
                      return _DraftCardItem(
                        flashcard: card,
                        index: index,
                        isSelected: isSelected,
                        onToggle: () => _toggleCard(index),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cards.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _selectedIndices.isEmpty || _isSaving
                        ? null
                        : _addSelectedCards,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(
                      l10n.addSelectedCards(_selectedIndices.length),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _DraftCardItem extends StatelessWidget {
  final Flashcard flashcard;
  final int index;
  final bool isSelected;
  final VoidCallback onToggle;

  const _DraftCardItem({
    required this.flashcard,
    required this.index,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary.withOpacity(0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Card content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Word
                    Text(
                      flashcard.front,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    // Phonetic
                    if (flashcard.frontPhonetic != null && flashcard.frontPhonetic!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        flashcard.frontPhonetic!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Meaning
                    Text(
                      flashcard.back,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                    // Example
                    if (flashcard.example != null && flashcard.example!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote, size: 14, color: AppColors.info.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              flashcard.example!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.info,
                                    fontSize: 12,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Notes
                    if (flashcard.notes != null && flashcard.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.sticky_note_2_outlined, size: 14, color: AppColors.secondary.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              flashcard.notes!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Index badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
