import '../local/database/deck_dao.dart';
import '../local/database/flashcard_dao.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

class DeckRepository {
  final DeckDao _deckDao;
  final FlashcardDao _flashcardDao;

  DeckRepository({
    DeckDao? deckDao,
    FlashcardDao? flashcardDao,
  })  : _deckDao = deckDao ?? DeckDao(),
        _flashcardDao = flashcardDao ?? FlashcardDao();

  Future<List<Deck>> getAllDecks() async {
    return await _deckDao.getAll();
  }

  Future<Deck?> getDeckById(String id) async {
    return await _deckDao.getById(id);
  }

  Future<void> createDeck(Deck deck) async {
    await _deckDao.insert(deck);
  }

  Future<void> updateDeck(Deck deck) async {
    await _deckDao.update(deck);
  }

  Future<void> deleteDeck(String id) async {
    await _flashcardDao.deleteByDeckId(id);
    await _deckDao.delete(id);
  }

  Future<int> getDeckCount() async {
    return await _deckDao.getCount();
  }

  Future<bool> deckExists(String id) async {
    return await _deckDao.exists(id);
  }

  Future<Map<String, dynamic>> exportDeck(String id) async {
    final deck = await _deckDao.getById(id);
    if (deck == null) {
      throw Exception('Deck not found');
    }

    final cards = await _flashcardDao.getByDeckId(id);

    return {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'decks': [deck.toJson(cards)],
    };
  }

  Future<Deck> importDeck(Map<String, dynamic> json, {bool overwrite = false}) async {
    final deckJson = json['decks'] as List<dynamic>;
    if (deckJson.isEmpty) {
      throw Exception('No deck data found');
    }

    final deckData = deckJson.first as Map<String, dynamic>;
    final deck = Deck.fromJson(deckData);

    // Check if deck already exists
    if (!overwrite && await _deckDao.exists(deck.id)) {
      throw Exception('Deck already exists');
    }

    await _deckDao.insert(deck);

    // Import flashcards
    final cardsJson = deckData['cards'] as List<dynamic>? ?? [];
    final cards = cardsJson
        .map((c) => Flashcard.fromJson(c as Map<String, dynamic>, deck.id))
        .toList();

    if (cards.isNotEmpty) {
      await _flashcardDao.insertBatch(cards);
    }

    return deck;
  }
}
