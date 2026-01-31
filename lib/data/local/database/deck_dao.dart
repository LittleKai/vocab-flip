import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/deck.dart';
import 'app_database.dart';

class DeckDao {
  final AppDatabase _appDatabase;

  DeckDao({AppDatabase? appDatabase}) : _appDatabase = appDatabase ?? AppDatabase();

  Future<Database> get _db => _appDatabase.database;

  Future<int> insert(Deck deck) async {
    debugPrint('DeckDao: Inserting deck: ${deck.name}, id: ${deck.id}');
    debugPrint('DeckDao: Deck data: ${deck.toMap()}');
    try {
      final db = await _db;
      debugPrint('DeckDao: Got database instance');
      final result = await db.insert(
        AppConstants.tableDecks,
        deck.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('DeckDao: Insert result: $result');
      return result;
    } catch (e, stackTrace) {
      debugPrint('DeckDao: Error inserting deck: $e');
      debugPrint('DeckDao: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> update(Deck deck) async {
    final db = await _db;
    return await db.update(
      AppConstants.tableDecks,
      deck.toMap(),
      where: 'id = ?',
      whereArgs: [deck.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _db;
    return await db.delete(
      AppConstants.tableDecks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Deck?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableDecks,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final counts = await _getCardCounts(db, id);
    return Deck.fromMap(
      maps.first,
      cardCount: counts['total'] ?? 0,
      newCount: counts['new'] ?? 0,
      learningCount: counts['learning'] ?? 0,
      reviewCount: counts['review'] ?? 0,
    );
  }

  Future<List<Deck>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableDecks,
      orderBy: 'created_at ASC',
    );

    final decks = <Deck>[];
    for (final map in maps) {
      final counts = await _getCardCounts(db, map['id'] as String);
      decks.add(Deck.fromMap(
        map,
        cardCount: counts['total'] ?? 0,
        newCount: counts['new'] ?? 0,
        learningCount: counts['learning'] ?? 0,
        reviewCount: counts['review'] ?? 0,
      ));
    }

    return decks;
  }

  Future<Map<String, int>> _getCardCounts(Database db, String deckId) async {
    final now = DateTime.now().toIso8601String();

    // Total cards
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableFlashcards}
      WHERE deck_id = ?
    ''', [deckId]);
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    // New cards (never reviewed)
    final newResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableFlashcards}
      WHERE deck_id = ? AND repetitions = 0
    ''', [deckId]);
    final newCount = Sqflite.firstIntValue(newResult) ?? 0;

    // Learning cards (reviewed but not graduated)
    final learningResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableFlashcards}
      WHERE deck_id = ? AND repetitions > 0 AND repetitions < 3
    ''', [deckId]);
    final learning = Sqflite.firstIntValue(learningResult) ?? 0;

    // Due for review (graduated and due)
    final reviewResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableFlashcards}
      WHERE deck_id = ? AND repetitions >= 3 AND
        (next_review_date IS NULL OR next_review_date <= ?)
    ''', [deckId, now]);
    final review = Sqflite.firstIntValue(reviewResult) ?? 0;

    return {
      'total': total,
      'new': newCount,
      'learning': learning,
      'review': review,
    };
  }

  Future<int> getCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableDecks}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> exists(String id) async {
    final db = await _db;
    final result = await db.query(
      AppConstants.tableDecks,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }
}
