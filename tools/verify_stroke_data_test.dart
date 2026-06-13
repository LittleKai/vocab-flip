import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vocabflip/data/models/stroke_character.dart';

void main() {
  test('verify stroke_data.db', () async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final dbPath = '${Directory.current.path}/assets/stroke_data.db';
    expect(File(dbPath).existsSync(), isTrue, reason: 'Database file must exist');

    final db = await databaseFactory.openDatabase(dbPath, options: OpenDatabaseOptions(readOnly: true));

    // Check schema
    final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    expect(tables.any((t) => t['name'] == 'stroke_chars'), isTrue, reason: 'stroke_chars table must exist');

    // Load manifest
    final manifestStr = File('tools/stroke_data_manifest.json').readAsStringSync();
    final manifest = jsonDecode(manifestStr) as Map<String, dynamic>;
    final smokeChars = manifest['smoke_characters'] as List<dynamic>;

    for (final sc in smokeChars) {
      final character = sc['character'] as String;
      final locale = sc['locale'] as String;

      final results = await db.query(
        'stroke_chars',
        where: 'character = ? AND locale = ?',
        whereArgs: [character, locale],
      );

      expect(results, isNotEmpty, reason: 'Smoke character $character ($locale) not found in DB');

      // Verify it parses successfully
      final parsed = StrokeCharacter.fromDbRow(results.first);
      expect(parsed.character, character);
      expect(parsed.locale, locale);
      expect(parsed.strokes, isNotEmpty);
      expect(parsed.strokes.length, parsed.strokeCount);
    }

    await db.close();
  });
}
