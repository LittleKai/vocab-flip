import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../auth/alpha_auth_session.dart';
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
    if (!kIsWeb) {
      return _syncQueueDao.writeEntities([_queueDeck(deck, 'CREATE')],
          (txn) async {
        await txn.insert(AppConstants.tableDecks, deck.toMap());
      }, ownerUserId: AlphaAuthSession().userId);
    }
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
    if (!kIsWeb) {
      return _syncQueueDao.writeEntities([_queueDeck(deck, 'UPDATE')],
          (txn) async {
        await txn.update(AppConstants.tableDecks, deck.toMap(),
            where: 'id = ?', whereArgs: [deck.id]);
      }, ownerUserId: AlphaAuthSession().userId);
    }
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
    if (!kIsWeb) {
      return _syncQueueDao.writeEntities([
        SyncQueueItem(
            id: const Uuid().v4(),
            entityType: 'deck',
            entityId: id,
            operation: 'DELETE')
      ], (txn) async {
        await txn.delete(AppConstants.tableFlashcards,
            where: 'deck_id = ?', whereArgs: [id]);
        await txn.delete(AppConstants.tableImportedDeckLinks,
            where: 'local_deck_id = ?', whereArgs: [id]);
        await txn
            .delete(AppConstants.tableDecks, where: 'id = ?', whereArgs: [id]);
      }, ownerUserId: AlphaAuthSession().userId);
    }
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

  Future<Deck> importDeck(Map<String, dynamic> json,
      {bool overwrite = false}) async {
    final owner = AlphaAuthSession().userId;
    final deckJson = json['decks'] as List<dynamic>;
    if (deckJson.isEmpty) {
      throw Exception('No deck data found');
    }

    final deckData = deckJson.first as Map<String, dynamic>;
    final deck = Deck.fromJson(deckData);
    final cards = parseImportCards(deckData, deck.id);

    // Check if deck already exists
    if (!overwrite && await _deckDao.exists(deck.id)) {
      throw Exception('Deck already exists');
    }

    await saveImportedDeck(deck, cards,
        overwrite: overwrite, ownerUserId: owner);
    return deck;
  }

  static List<Flashcard> parseImportCards(
      Map<String, dynamic> data, String deckId) {
    final cards = (data['cards'] as List<dynamic>? ?? [])
        .map((c) => Flashcard.fromJson(c as Map<String, dynamic>, deckId))
        .toList();
    if (cards.map((c) => c.id).toSet().length != cards.length) {
      throw const FormatException('Duplicate card IDs');
    }
    // Force conversion before any mutation (including lazy list casts).
    for (final card in cards) {
      card.toMap();
    }
    return cards;
  }

  static SyncQueueItem _queueDeck(Deck deck, String operation) => SyncQueueItem(
      id: const Uuid().v4(),
      entityType: 'deck',
      entityId: deck.id,
      operation: operation,
      payload: jsonEncode(deck.toMap()));

  Future<void> saveImportedDeck(Deck deck, List<Flashcard> cards,
      {bool overwrite = false, required String? ownerUserId}) async {
    if (kIsWeb) {
      // ponytail: backend has no atomic replace endpoint; preserve originals
      // until one exists rather than delete then attempt a multi-request import.
      if (overwrite) {
        throw UnsupportedError('Atomic replacement is unavailable on web');
      }
      await _deckDao.insert(deck);
      if (cards.isNotEmpty) await _flashcardDao.insertBatch(cards);
      return;
    }
    await _syncQueueDao.writeEntities([
      if (overwrite)
        SyncQueueItem(
            id: const Uuid().v4(),
            entityType: 'deck',
            entityId: deck.id,
            operation: 'DELETE'),
      _queueDeck(deck, 'CREATE'),
      for (final card in cards)
        SyncQueueItem(
            id: const Uuid().v4(),
            entityType: 'flashcard',
            entityId: card.id,
            operation: 'CREATE',
            payload: jsonEncode(card.toMap())),
    ], (txn) async {
      if (overwrite) {
        await txn.delete(AppConstants.tableFlashcards,
            where: 'deck_id = ?', whereArgs: [deck.id]);
        await txn.delete(AppConstants.tableImportedDeckLinks,
            where: 'local_deck_id = ?', whereArgs: [deck.id]);
        await txn.delete(AppConstants.tableDecks,
            where: 'id = ?', whereArgs: [deck.id]);
      }
      await txn.insert(AppConstants.tableDecks, deck.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort);
      for (final card in cards) {
        await txn.insert(AppConstants.tableFlashcards, card.toMap(),
            conflictAlgorithm: ConflictAlgorithm.abort);
      }
    }, ownerUserId: ownerUserId);
  }
}
