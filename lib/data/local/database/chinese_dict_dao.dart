import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DAO for Chinese-Vietnamese dictionary (local database)
class ChineseDictDao {
  static ChineseDictDao? _instance;
  Database? _database;
  bool _isInitialized = false;

  ChineseDictDao._();

  static ChineseDictDao get instance {
    _instance ??= ChineseDictDao._();
    return _instance!;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize FFI for desktop platforms
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // Get the path to store the database
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDir.path, 'vocabflip', 'chinese_dict.db');

      // Check if database already exists
      // TODO: Add version check to update database when needed
      final dbFile = File(dbPath);
      const forceUpdate = true; // Set to false after development
      if (!dbFile.existsSync() || forceUpdate) {
        // Copy from assets
        debugPrint('[ChineseDictDao] Copying database from assets...');

        // Create directory if it doesn't exist
        await Directory(dirname(dbPath)).create(recursive: true);

        // Load from assets and write to file
        final data = await rootBundle.load('assets/chinese_dict.db');
        final bytes = data.buffer.asUint8List();
        await dbFile.writeAsBytes(bytes, flush: true);

        debugPrint('[ChineseDictDao] Database copied to: $dbPath');
      }

      // Open database (read-only)
      _database = await openDatabase(dbPath, readOnly: true);
      _isInitialized = true;

      debugPrint('[ChineseDictDao] Database opened successfully');
    } catch (e) {
      debugPrint('[ChineseDictDao] Error initializing: $e');
      rethrow;
    }
  }

  /// Search for Chinese words (exact match first, then partial)
  Future<List<ChineseDictEntry>> search(String query, {int limit = 20}) async {
    if (!_isInitialized || _database == null) {
      await init();
    }

    try {
      // First try exact match
      var results = await _database!.query(
        'words',
        where: 'word = ?',
        whereArgs: [query],
        limit: limit,
      );

      // If no exact match, try prefix match
      if (results.isEmpty) {
        results = await _database!.query(
          'words',
          where: 'word LIKE ?',
          whereArgs: ['$query%'],
          limit: limit,
        );
      }

      // If still no results, try contains
      if (results.isEmpty) {
        results = await _database!.query(
          'words',
          where: 'word LIKE ?',
          whereArgs: ['%$query%'],
          limit: limit,
        );
      }

      return results.map((row) => ChineseDictEntry.fromMap(row)).toList();
    } catch (e) {
      debugPrint('[ChineseDictDao] Error searching: $e');
      return [];
    }
  }

  /// Lookup a single word (exact match)
  Future<ChineseDictEntry?> lookup(String word) async {
    if (!_isInitialized || _database == null) {
      await init();
    }

    try {
      final results = await _database!.query(
        'words',
        where: 'word = ?',
        whereArgs: [word],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return ChineseDictEntry.fromMap(results.first);
    } catch (e) {
      debugPrint('[ChineseDictDao] Error looking up: $e');
      return null;
    }
  }

  /// Search by pinyin
  Future<List<ChineseDictEntry>> searchByPinyin(String pinyin, {int limit = 20}) async {
    if (!_isInitialized || _database == null) {
      await init();
    }

    try {
      final results = await _database!.query(
        'words',
        where: 'pinyin LIKE ?',
        whereArgs: ['%$pinyin%'],
        limit: limit,
      );

      return results.map((row) => ChineseDictEntry.fromMap(row)).toList();
    } catch (e) {
      debugPrint('[ChineseDictDao] Error searching by pinyin: $e');
      return [];
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
  }
}

/// Entry from Chinese-Vietnamese dictionary
class ChineseDictEntry {
  final int id;
  final String word;
  final String? pinyin;
  final String? hanViet;
  final String definition;

  ChineseDictEntry({
    required this.id,
    required this.word,
    this.pinyin,
    this.hanViet,
    required this.definition,
  });

  factory ChineseDictEntry.fromMap(Map<String, dynamic> map) {
    return ChineseDictEntry(
      id: map['id'] as int,
      word: map['word'] as String,
      pinyin: map['pinyin'] as String?,
      hanViet: map['han_viet'] as String?,
      definition: map['definition'] as String,
    );
  }

  @override
  String toString() {
    return 'ChineseDictEntry(word: $word, pinyin: $pinyin, definition: ${definition.substring(0, definition.length.clamp(0, 50))}...)';
  }
}
