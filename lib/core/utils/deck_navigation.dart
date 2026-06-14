import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../presentation/providers/deck_provider.dart';
import '../../presentation/providers/flashcard_provider.dart';
import '../../presentation/screens/deck/deck_detail_screen.dart';
import '../../presentation/screens/flashcard/flashcard_viewer_screen.dart';

/// Helper class for deck navigation
class DeckNavigation {
  /// Navigate based on user preference (detail or browse)
  static Future<void> navigateBasedOnPreference(BuildContext context, String deckId) async {
    final action = AppPreferences().deckClickAction;
    if (action == 'browse') {
      await navigateToBrowse(context, deckId);
    } else {
      navigateToDeckDetail(context, deckId);
    }
  }

  /// Navigate to browse flashcards if deck has cards, otherwise go to deck detail
  static Future<void> navigateToBrowse(BuildContext context, String deckId) async {
    // Capture providers and navigator before async gap
    final flashcardProvider = context.read<FlashcardProvider>();
    final deckProvider = context.read<DeckProvider>();
    final navigator = Navigator.of(context);

    // Load flashcards first
    await flashcardProvider.loadFlashcards(deckId);
    await deckProvider.selectDeck(deckId);

    final flashcards = flashcardProvider.flashcards;
    if (flashcards.isEmpty) {
      // No cards, go to deck detail to add cards
      navigator.push(
        MaterialPageRoute(
          builder: (_) => DeckDetailScreen(deckId: deckId),
        ),
      );
    } else {
      // Has cards, go to browse
      navigator.push(
        MaterialPageRoute(
          builder: (_) => FlashcardViewerScreen(deckId: deckId),
        ),
      );
    }
  }

  /// Navigate directly to deck detail screen
  static void navigateToDeckDetail(BuildContext context, String deckId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeckDetailScreen(deckId: deckId),
      ),
    );
  }

  /// Navigate to study mode
  static void navigateToStudy(BuildContext context, String deckId) {
    Navigator.of(context).pushNamed('/study', arguments: deckId);
  }
}
