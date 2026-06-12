import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class OfflineDictEntry {
  final int id;
  final String word;
  final String definition;

  OfflineDictEntry({
    required this.id,
    required this.word,
    required this.definition,
  });

  factory OfflineDictEntry.fromMap(Map<String, dynamic> map) {
    return OfflineDictEntry(
      id: map['id'] as int,
      word: map['word'] as String,
      definition: map['definition'] as String,
    );
  }
}

class OfflineDictDao {
  final String assetName;
  final String dbName;
  Database? _database;
  bool _isInitialized = false;

  OfflineDictDao({required this.assetName, required this.dbName});

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        debugPrint('[$dbName] Web platform detected; local dictionary disabled.');
        _isInitialized = true;
        return;
      }

      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDir.path, 'vocabflip', dbName);
      
      final dbFile = File(dbPath);
      final dbExists = dbFile.existsSync();

      // Check if db exists and size matches approximately, otherwise copy
      if (!dbExists) {
        debugPrint('[$dbName] Copying database from assets...');
        await Directory(dirname(dbPath)).create(recursive: true);
        final data = await rootBundle.load(assetName);
        final bytes = data.buffer.asUint8List();
        await dbFile.writeAsBytes(bytes, flush: true);
        debugPrint('[$dbName] Copied to: $dbPath');
      }

      _database = await openDatabase(dbPath, readOnly: true);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[$dbName] Error initializing: $e');
      rethrow;
    }
  }

  Future<List<OfflineDictEntry>> search(String query, {int limit = 20}) async {
    if (kIsWeb) return [];
    if (!_isInitialized || _database == null) await init();
    if (_database == null) return [];

    try {
      var results = await _database!.query('words', where: 'word = ?', whereArgs: [query], limit: limit);
      if (results.isEmpty) {
        results = await _database!.query('words', where: 'word LIKE ?', whereArgs: ['$query%'], limit: limit);
      }
      if (results.isEmpty) {
        results = await _database!.query('words', where: 'word LIKE ?', whereArgs: ['%$query%'], limit: limit);
      }
      return results.map((row) => OfflineDictEntry.fromMap(row)).toList();
    } catch (e) {
      debugPrint('[$dbName] Error searching "$query": $e');
      return [];
    }
  }

  Future<OfflineDictEntry?> lookup(String word) async {
    if (kIsWeb) return null;
    if (!_isInitialized || _database == null) await init();
    if (_database == null) return null;

    try {
      final results = await _database!.query('words', where: 'word = ?', whereArgs: [word], limit: 1);
      if (results.isEmpty) return null;
      return OfflineDictEntry.fromMap(results.first);
    } catch (e) {
      debugPrint('[$dbName] Error looking up: $e');
      return null;
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
  }
}
