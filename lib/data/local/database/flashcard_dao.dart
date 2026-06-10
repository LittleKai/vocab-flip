import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/flashcard.dart';
import 'app_database.dart';
import '../../remote/mongo/mongo_private_flashcard_service.dart';
import '../../remote/mongo/mongo_private_deck_service.dart';

class FlashcardDao {
  final AppDatabase _appDatabase;
  final MongoPrivateFlashcardService _mongoService;
  final MongoPrivateDeckService _deckService;

  FlashcardDao({
    AppDatabase? appDatabase,
    MongoPrivateFlashcardService? mongoService,
    MongoPrivateDeckService? deckService,
  })  : _appDatabase = appDatabase ?? AppDatabase(),
        _mongoService = mongoService ?? MongoPrivateFlashcardService(),
        _deckService = deckService ?? MongoPrivateDeckService();

  Future<Database> get _db => _appDatabase.database;

  Future<int> insert(Flashcard flashcard) async {
    if (kIsWeb) {
      final result = await _mongoService.createFlashcard(flashcard);
      return result != null ? 1 : 0;
    }

    final db = await _db;
    return await db.insert(
      AppConstants.tableFlashcards,
      flashcard.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(Flashcard flashcard) async {
    if (kIsWeb) {
      final result = await _mongoService.updateFlashcard(flashcard);
      return result != null ? 1 : 0;
    }

    final db = await _db;
    return await db.update(
      AppConstants.tableFlashcards,
      flashcard.toMap(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
  }

  Future<int> delete(String id) async {
    if (kIsWeb) {
      final card = await getById(id);
      if (card != null) {
        await _mongoService.deleteFlashcard(card.deckId, card.id);
        return 1;
      }
      return 0;
    }

    final db = await _db;
    return await db.delete(
      AppConstants.tableFlashcards,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByDeckId(String deckId) async {
    if (kIsWeb) {
      // Backend automatically deletes cards when deleting the deck.
      return 1;
    }

    final db = await _db;
    return await db.delete(
      AppConstants.tableFlashcards,
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );
  }

  Future<Flashcard?> getById(String id) async {
    if (kIsWeb) {
      return await _mongoService.getFlashcardById(id);
    }

    final db = await _db;
    final maps = await db.query(
      AppConstants.tableFlashcards,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Flashcard.fromMap(maps.first);
  }

  Future<List<Flashcard>> getByDeckId(String deckId) async {
    if (kIsWeb) {
      return await _mongoService.getFlashcards(deckId);
    }

    final db = await _db;
    final maps = await db.query(
      AppConstants.tableFlashcards,
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getDueCards(String deckId, {int? limit}) async {
    if (kIsWeb) {
      final cards = await _mongoService.getDueFlashcards(deckId);
      if (limit != null && cards.length > limit) {
        return cards.sublist(0, limit);
      }
      return cards;
    }

    final db = await _db;
    final now = DateTime.now().toIso8601String();

    final maps = await db.query(
      AppConstants.tableFlashcards,
      where: 'deck_id = ? AND (next_review_date IS NULL OR next_review_date <= ?)',
      whereArgs: [deckId, now],
      orderBy: 'CASE WHEN repetitions = 0 THEN 0 ELSE 1 END, next_review_date ASC',
      limit: limit,
    );

    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getNewCards(String deckId, {int? limit}) async {
    if (kIsWeb) {
      final newCards = await _mongoService.getNewFlashcards(deckId);
      if (limit != null && newCards.length > limit) {
        return newCards.sublist(0, limit);
      }
      return newCards;
    }

    final db = await _db;
    final maps = await db.query(
      AppConstants.tableFlashcards,
      where: 'deck_id = ? AND repetitions = 0',
      whereArgs: [deckId],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> search(String query, {String? deckId}) async {
    if (kIsWeb) {
      final cards = await _mongoService.searchFlashcards(query);
      if (deckId != null) {
        return cards.where((c) => c.deckId == deckId).toList();
      }
      return cards;
    }

    final db = await _db;
    final searchPattern = '%$query%';

    String where = '(front LIKE ? OR back LIKE ? OR front_phonetic LIKE ? OR tags LIKE ?)';
    List<dynamic> whereArgs = [searchPattern, searchPattern, searchPattern, searchPattern];

    if (deckId != null) {
      where = 'deck_id = ? AND $where';
      whereArgs = [deckId, ...whereArgs];
    }

    final maps = await db.query(
      AppConstants.tableFlashcards,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<int> getCountByDeckId(String deckId) async {
    if (kIsWeb) {
      return await _mongoService.getFlashcardsCount(deckId);
    }

    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableFlashcards}
      WHERE deck_id = ?
    ''', [deckId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getDueCountByDeckId(String deckId) async {
    if (kIsWeb) {
      final cards = await getDueCards(deckId);
      return cards.length;
    }

    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableFlashcards}
      WHERE deck_id = ? AND (next_review_date IS NULL OR next_review_date <= ?)
    ''', [deckId, now]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> insertBatch(List<Flashcard> flashcards) async {
    if (kIsWeb) {
      if (flashcards.isEmpty) return;
      final deckId = flashcards.first.deckId;
      await _mongoService.syncFlashcardsBatch(deckId, flashcards);
      return;
    }

    final db = await _db;
    final batch = db.batch();
    for (final flashcard in flashcards) {
      batch.insert(
        AppConstants.tableFlashcards,
        flashcard.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Flashcard>> getAll() async {
    if (kIsWeb) {
      final decks = await _deckService.getAllDecks();
      final results = await Future.wait(
        decks.map((deck) => getByDeckId(deck.id)),
      );
      return results.expand((cards) => cards).toList();
    }

    final db = await _db;
    final maps = await db.query(AppConstants.tableFlashcards);
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<Map<String, int>> getDeckBreakdown() async {
    if (kIsWeb) return {'new': 0, 'learning': 0, 'mature': 0};

    final db = await _db;
    final results = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN repetitions = 0 THEN 1 ELSE 0 END) as new_cards,
        SUM(CASE WHEN repetitions > 0 AND interval < 21 THEN 1 ELSE 0 END) as learning_cards,
        SUM(CASE WHEN interval >= 21 THEN 1 ELSE 0 END) as mature_cards
      FROM ${AppConstants.tableFlashcards}
    ''');

    if (results.isEmpty) return {'new': 0, 'learning': 0, 'mature': 0};

    final row = results.first;
    return {
      'new': (row['new_cards'] as num?)?.toInt() ?? 0,
      'learning': (row['learning_cards'] as num?)?.toInt() ?? 0,
      'mature': (row['mature_cards'] as num?)?.toInt() ?? 0,
    };
  }
}
