import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/flashcard.dart';
import 'app_database.dart';

class FlashcardDao {
  final AppDatabase _appDatabase;

  FlashcardDao({AppDatabase? appDatabase}) : _appDatabase = appDatabase ?? AppDatabase();

  Future<Database> get _db => _appDatabase.database;

  Future<int> insert(Flashcard flashcard) async {
    final db = await _db;
    return await db.insert(
      AppConstants.tableFlashcards,
      flashcard.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(Flashcard flashcard) async {
    final db = await _db;
    return await db.update(
      AppConstants.tableFlashcards,
      flashcard.toMap(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _db;
    return await db.delete(
      AppConstants.tableFlashcards,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByDeckId(String deckId) async {
    final db = await _db;
    return await db.delete(
      AppConstants.tableFlashcards,
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );
  }

  Future<Flashcard?> getById(String id) async {
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
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableFlashcards,
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getDueCards(String deckId, {int? limit}) async {
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
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableFlashcards}
      WHERE deck_id = ?
    ''', [deckId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getDueCountByDeckId(String deckId) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableFlashcards}
      WHERE deck_id = ? AND (next_review_date IS NULL OR next_review_date <= ?)
    ''', [deckId, now]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> insertBatch(List<Flashcard> flashcards) async {
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
    final db = await _db;
    final maps = await db.query(AppConstants.tableFlashcards);
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }
}
