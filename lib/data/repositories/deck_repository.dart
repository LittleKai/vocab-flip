import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../local/database/deck_dao.dart';
import '../local/database/flashcard_dao.dart';
import '../local/daos/sync_queue_dao.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/sync_queue_item.dart';

class DeckRepository {
  final DeckDao _deckDao;
  final FlashcardDao _flashcardDao;
  final SyncQueueDao _syncQueueDao;

  DeckRepository({
    DeckDao? deckDao,
    FlashcardDao? flashcardDao,
    SyncQueueDao? syncQueueDao,
  })  : _deckDao = deckDao ?? DeckDao(),
        _flashcardDao = flashcardDao ?? FlashcardDao(),
        _syncQueueDao = syncQueueDao ?? SyncQueueDao();

  Future<List<Deck>> getAllDecks() async {
    return await _deckDao.getAll();
  }

  Future<Deck?> getDeckById(String id) async {
    return await _deckDao.getById(id);
  }

  Future<void> createDeck(Deck deck) async {
    await _deckDao.insert(deck);
    await _syncQueueDao.insert(SyncQueueItem(
      id: const Uuid().v4(),
      entityType: 'deck',
      entityId: deck.id,
      operation: 'CREATE',
      payload: jsonEncode(deck.toMap()),
    ));
  }

  Future<void> updateDeck(Deck deck) async {
    await _deckDao.update(deck);
    await _syncQueueDao.insert(SyncQueueItem(
      id: const Uuid().v4(),
      entityType: 'deck',
      entityId: deck.id,
      operation: 'UPDATE',
      payload: jsonEncode(deck.toMap()),
    ));
  }

  Future<void> deleteDeck(String id) async {
    await _flashcardDao.deleteByDeckId(id);
    await _deckDao.delete(id);
    await _syncQueueDao.insert(SyncQueueItem(
      id: const Uuid().v4(),
      entityType: 'deck',
      entityId: id,
      operation: 'DELETE',
    ));
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
