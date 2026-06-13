import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/stroke_character.dart';

class StrokeDataDao {
  static const String _assetName = 'assets/stroke_data.db';
  static const String _dbName = 'stroke_data.db';

  Database? _database;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        debugPrint(
            '[stroke_data] Web platform detected; stroke data disabled.');
        _isInitialized = true;
        return;
      }

      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDir.path, 'vocabflip', _dbName);

      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        debugPrint('[$_dbName] Copying database from assets...');
        await Directory(dirname(dbPath)).create(recursive: true);
        final data = await rootBundle.load(_assetName);
        final bytes = data.buffer.asUint8List();
        await dbFile.writeAsBytes(bytes, flush: true);
        debugPrint('[$_dbName] Copied to: $dbPath');
      }

      _database = await openDatabase(dbPath, readOnly: true);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[$_dbName] Error initializing: $e');
      rethrow;
    }
  }

  Future<StrokeCharacter?> lookup({
    required String character,
    required String locale,
  }) async {
    if (kIsWeb) return null;
    if (!_isInitialized || _database == null) await init();
    if (_database == null) return null;

    try {
      final results = await _database!.query(
        'stroke_chars',
        columns: ['character', 'locale', 'data_json'],
        where: 'character = ? AND locale = ?',
        whereArgs: [character, locale],
        limit: 1,
      );
      if (results.isEmpty) return null;

      return StrokeCharacter.fromDbRow(results.first);
    } catch (e) {
      debugPrint('[$_dbName] Error looking up "$character" ($locale): $e');
      return null;
    }
  }

  Future<bool> exists({
    required String character,
    required String locale,
  }) async {
    if (kIsWeb) return false;
    if (!_isInitialized || _database == null) await init();
    if (_database == null) return false;

    try {
      final results = await _database!.query(
        'stroke_chars',
        columns: ['id'],
        where: 'character = ? AND locale = ?',
        whereArgs: [character, locale],
        limit: 1,
      );
      return results.isNotEmpty;
    } catch (e) {
      debugPrint('[$_dbName] Error checking "$character" ($locale): $e');
      return false;
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
  }
}
