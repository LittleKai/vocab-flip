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
      if (kIsWeb) {
        debugPrint('[ChineseDictDao] Web platform detected; local Chinese dictionary is disabled.');
        _isInitialized = true;
        return;
      }

      debugPrint('[ChineseDictDao] init() starting on ${Platform.operatingSystem}');
      debugPrint('[ChineseDictDao] kIsWeb=$kIsWeb, isWindows=${Platform.isWindows}, isAndroid=${Platform.isAndroid}');

      // Initialize FFI for desktop platforms
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        debugPrint('[ChineseDictDao] FFI database factory set');
      } else {
        debugPrint('[ChineseDictDao] Using default database factory (platform: ${Platform.operatingSystem})');
        debugPrint('[ChineseDictDao] Current databaseFactory type: ${databaseFactory.runtimeType}');
      }

      // Get the path to store the database
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDir.path, 'vocabflip', 'chinese_dict.db');
      debugPrint('[ChineseDictDao] DB path: $dbPath');

      // Also log the default sqflite databases path for comparison
      try {
        final defaultDbPath = await getDatabasesPath();
        debugPrint('[ChineseDictDao] Default sqflite databases path: $defaultDbPath');
      } catch (e) {
        debugPrint('[ChineseDictDao] Could not get default DB path: $e');
      }

      // Check if database already exists
      final dbFile = File(dbPath);
      final dbExists = dbFile.existsSync();
      debugPrint('[ChineseDictDao] DB file exists: $dbExists');
      if (dbExists) {
        final size = await dbFile.length();
        debugPrint('[ChineseDictDao] DB file size: $size bytes');
      }

      const forceUpdate = false;
      if (!dbExists || forceUpdate) {
        // Copy from assets
        debugPrint('[ChineseDictDao] Copying database from assets...');

        // Create directory if it doesn't exist
        await Directory(dirname(dbPath)).create(recursive: true);

        // Load from assets and write to file
        final data = await rootBundle.load('assets/chinese_dict.db');
        final bytes = data.buffer.asUint8List();
        debugPrint('[ChineseDictDao] Asset loaded: ${bytes.length} bytes');
        await dbFile.writeAsBytes(bytes, flush: true);

        debugPrint('[ChineseDictDao] Database copied to: $dbPath');
      }

      // Open database (read-only)
      debugPrint('[ChineseDictDao] Opening database...');
      _database = await openDatabase(dbPath, readOnly: true);
      _isInitialized = true;

      debugPrint('[ChineseDictDao] Database opened successfully');

      // Verify database is usable
      try {
        final countResult = await _database!.rawQuery('SELECT COUNT(*) FROM words');
        final count = countResult.first.values.first;
        debugPrint('[ChineseDictDao] Verification: words table has $count rows');
      } catch (verifyError) {
        debugPrint('[ChineseDictDao] Verification FAILED: $verifyError');
      }
    } catch (e, stackTrace) {
      debugPrint('[ChineseDictDao] Error initializing: $e');
      debugPrint('[ChineseDictDao] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Search for Chinese words (exact match first, then partial)
  Future<List<ChineseDictEntry>> search(String query, {int limit = 20}) async {
    if (kIsWeb) return [];
    debugPrint('[ChineseDictDao] search("$query") - initialized=$_isInitialized, db=${_database != null}');
    if (!_isInitialized || _database == null) {
      debugPrint('[ChineseDictDao] search: not initialized, calling init()...');
      await init();
    }
    if (_database == null) return [];

    try {
      debugPrint('[ChineseDictDao] search: trying exact match for "$query"...');
      // First try exact match
      var results = await _database!.query(
        'words',
        where: 'word = ?',
        whereArgs: [query],
        limit: limit,
      );
      debugPrint('[ChineseDictDao] search: exact match returned ${results.length} rows');

      // If no exact match, try prefix match
      if (results.isEmpty) {
        debugPrint('[ChineseDictDao] search: trying prefix match "$query%"...');
        results = await _database!.query(
          'words',
          where: 'word LIKE ?',
          whereArgs: ['$query%'],
          limit: limit,
        );
        debugPrint('[ChineseDictDao] search: prefix match returned ${results.length} rows');
      }

      // If still no results, try contains
      if (results.isEmpty) {
        debugPrint('[ChineseDictDao] search: trying contains match "%$query%"...');
        results = await _database!.query(
          'words',
          where: 'word LIKE ?',
          whereArgs: ['%$query%'],
          limit: limit,
        );
        debugPrint('[ChineseDictDao] search: contains match returned ${results.length} rows');
      }

      debugPrint('[ChineseDictDao] search("$query") DONE - found ${results.length} results');
      if (results.isNotEmpty) {
        debugPrint('[ChineseDictDao] search: first result keys=${results.first.keys.toList()}');
      }
      return results.map((row) => ChineseDictEntry.fromMap(row)).toList();
    } catch (e, stackTrace) {
      debugPrint('[ChineseDictDao] Error searching "$query": $e');
      debugPrint('[ChineseDictDao] Search stack trace: $stackTrace');
      return [];
    }
  }

  /// Lookup a single word (exact match)
  Future<ChineseDictEntry?> lookup(String word) async {
    if (kIsWeb) return null;
    if (!_isInitialized || _database == null) {
      await init();
    }
    if (_database == null) return null;

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
    if (kIsWeb) return [];
    if (!_isInitialized || _database == null) {
      await init();
    }
    if (_database == null) return [];

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
