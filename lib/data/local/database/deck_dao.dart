import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/deck.dart';
import 'app_database.dart';
import '../../remote/mongo/mongo_private_deck_service.dart';

class DeckDao {
  final AppDatabase _appDatabase;
  final MongoPrivateDeckService _mongoService;

  DeckDao({AppDatabase? appDatabase, MongoPrivateDeckService? mongoService})
      : _appDatabase = appDatabase ?? AppDatabase(),
        _mongoService = mongoService ?? MongoPrivateDeckService();

  Future<Database> get _db => _appDatabase.database;

  Future<int> insert(Deck deck) async {
    if (kIsWeb) {
      debugPrint('DeckDao.insert [WEB]: calling MongoService.createDeck for ${deck.name} (id=${deck.id})');
      final result = await _mongoService.createDeck(deck);
      debugPrint('DeckDao.insert [WEB]: MongoService returned ${result != null ? result.name : "null"}');
      return result != null ? 1 : 0;
    }

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
    if (kIsWeb) {
      final result = await _mongoService.updateDeck(deck);
      return result != null ? 1 : 0;
    }

    final db = await _db;
    return await db.update(
      AppConstants.tableDecks,
      deck.toMap(),
      where: 'id = ?',
      whereArgs: [deck.id],
    );
  }

  /// Update only specific fields of a deck (safe partial update)
  Future<int> updateFields(String deckId, Map<String, dynamic> fields) async {
    if (kIsWeb) {
      final deck = await getById(deckId);
      if (deck == null) return 0;
      final updated = deck.copyWith(
        name: fields['name'] as String?,
        description: fields['description'] as String?,
        sourceLanguage: fields['source_language'] as String?,
        targetLanguage: fields['target_language'] as String?,
        linkedPublicDeckId: fields.containsKey('linked_public_deck_id') ? fields['linked_public_deck_id'] as String? : deck.linkedPublicDeckId,
        linkedVersion: fields.containsKey('linked_version') ? fields['linked_version'] as int? : deck.linkedVersion,
        isPublished: fields.containsKey('is_published') ? (fields['is_published'] == 1 || fields['is_published'] == true) : deck.isPublished,
        publishedDeckId: fields.containsKey('published_deck_id') ? fields['published_deck_id'] as String? : deck.publishedDeckId,
        wasImported: fields.containsKey('was_imported') ? (fields['was_imported'] == 1 || fields['was_imported'] == true) : deck.wasImported,
        showBackFirst: fields.containsKey('show_back_first') ? (fields['show_back_first'] == 1 || fields['show_back_first'] == true) : deck.showBackFirst,
        category: fields.containsKey('category') ? fields['category'] as String? : deck.category,
        imagePath: fields.containsKey('image_path') ? fields['image_path'] as String? : deck.imagePath,
      );
      await _mongoService.updateDeck(updated);
      return 1;
    }

    final db = await _db;
    return await db.update(
      AppConstants.tableDecks,
      fields,
      where: 'id = ?',
      whereArgs: [deckId],
    );
  }

  Future<int> delete(String id) async {
    if (kIsWeb) {
      await _mongoService.deleteDeck(id);
      return 1;
    }

    final db = await _db;
    // Also remove import link if exists
    await db.delete(
      AppConstants.tableImportedDeckLinks,
      where: 'local_deck_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      AppConstants.tableDecks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Deck?> getById(String id) async {
    if (kIsWeb) {
      return await _mongoService.getDeckById(id);
    }

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
    if (kIsWeb) {
      debugPrint('DeckDao.getAll [WEB]: calling MongoService.getAllDecks');
      final decks = await _mongoService.getAllDecks();
      debugPrint('DeckDao.getAll [WEB]: MongoService returned ${decks.length} decks');
      return decks;
    }

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
    if (kIsWeb) {
      final decks = await _mongoService.getAllDecks();
      return decks.length;
    }

    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableDecks}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> exists(String id) async {
    if (kIsWeb) {
      final deck = await _mongoService.getDeckById(id);
      return deck != null;
    }

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
