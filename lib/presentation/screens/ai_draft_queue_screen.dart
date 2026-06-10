import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import '../providers/ai_provider.dart';
import '../providers/deck_provider.dart';
import '../../../data/repositories/flashcard_repository.dart';

class AiDraftQueueScreen extends StatelessWidget {
  const AiDraftQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AiProvider>();
    final draftCards = provider.draftCards;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewDraftCards)),
      body: draftCards.isEmpty
          ? Center(child: Text(l10n.allCardsReviewed))
          : ListView.builder(
              itemCount: draftCards.length,
              itemBuilder: (context, index) {
                final card = draftCards[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(card.front),
                    subtitle: Text('${card.frontPhonetic ?? ''}\n${card.back}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => provider.rejectCard(card),
                          tooltip: l10n.reject,
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            final deckId = context.read<DeckProvider>().selectedDeck?.id;
                            if (deckId != null) {
                              final newCard = card.copyWith(deckId: deckId);
                              await FlashcardRepository().createFlashcard(newCard);
                              provider.approveCard(card);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.selectDeckForCards)),
                              );
                            }
                          },
                          tooltip: l10n.approve,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
