// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('build stroke_data.db', () async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final dbPath = '${Directory.current.path}/assets/stroke_data.db';
    final file = File(dbPath);
    if (file.existsSync()) {
      print('Deleting existing DB...');
      file.deleteSync();
    }

    print('Opening DB at $dbPath');
    final db = await databaseFactory.openDatabase(dbPath);

    await db.execute('''
    CREATE TABLE stroke_chars (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      character TEXT NOT NULL,
      locale TEXT NOT NULL,
      data_json BLOB NOT NULL
    )
  ''');
    await db.execute(
        'CREATE INDEX idx_char_locale ON stroke_chars(character, locale)');

    final sources = {
      'ja': 'D:/Dev/2.reference_pj/language-ref/animCJK/graphicsJa.txt',
      'ja-kana':
          'D:/Dev/2.reference_pj/language-ref/animCJK/graphicsJaKana.txt',
      'zh-Hans':
          'D:/Dev/2.reference_pj/language-ref/animCJK/graphicsZhHans.txt',
      'zh-Hant':
          'D:/Dev/2.reference_pj/language-ref/animCJK/graphicsZhHant.txt',
    };

    int totalRecords = 0;
    int totalInserted = 0;
    int totalSkipped = 0;
    int totalErrors = 0;

    for (final entry in sources.entries) {
      final locale = entry.key;
      final path = entry.value;

      print('\nProcessing $locale from $path...');
      final srcFile = File(path);
      if (!srcFile.existsSync()) {
        print('Warning: File not found: $path');
        continue;
      }

      int recordsRead = 0;
      int recordsInserted = 0;
      int recordsSkipped = 0;
      int errors = 0;

      final batch = db.batch();
      int batchCount = 0;

      final lines = await srcFile.readAsLines();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        recordsRead++;

        try {
          final parsed = jsonDecode(line) as Map<String, dynamic>;
          final char = parsed['character'] as String?;
          final strokes = parsed['strokes'] as List<dynamic>?;
          final medians = parsed['medians'] as List<dynamic>?;

          if (char == null || char.isEmpty) {
            recordsSkipped++;
            continue;
          }

          if (strokes == null ||
              medians == null ||
              strokes.length != medians.length) {
            recordsSkipped++;
            continue;
          }

          bool valid = true;
          final formattedStrokes = [];

          for (int i = 0; i < strokes.length; i++) {
            final pathStr = strokes[i] as String;
            if (pathStr.isEmpty) {
              valid = false;
              break;
            }

            final medianArr = medians[i] as List<dynamic>;
            if (medianArr.length < 2) {
              valid = false;
              break;
            }

            final formattedMedians = [];
            for (final point in medianArr) {
              final p = point as List<dynamic>;
              formattedMedians.add([p[0].toInt(), p[1].toInt()]);
            }

            formattedStrokes.add([
              pathStr,
              formattedMedians,
            ]);
          }

          if (!valid) {
            recordsSkipped++;
            continue;
          }

          final jsonBytes = utf8.encode(jsonEncode(formattedStrokes));
          final compressedBytes = zlib.encode(jsonBytes);

          batch.insert('stroke_chars', {
            'character': char,
            'locale': locale,
            'data_json': compressedBytes,
          });

          batchCount++;
          recordsInserted++;

          if (batchCount >= 5000) {
            await batch.commit(noResult: true);
            batchCount = 0;
          }
        } catch (e) {
          errors++;
        }
      }

      if (batchCount > 0) {
        await batch.commit(noResult: true);
      }

      print('  Read: $recordsRead');
      print('  Inserted: $recordsInserted');
      print('  Skipped: $recordsSkipped');
      print('  Errors: $errors');

      totalRecords += recordsRead;
      totalInserted += recordsInserted;
      totalSkipped += recordsSkipped;
      totalErrors += errors;
    }

    print('\nSummary:');
    print('  Total Read: $totalRecords');
    print('  Total Inserted: $totalInserted');
    print('  Total Skipped: $totalSkipped');
    print('  Total Errors: $totalErrors');

    await db.execute('VACUUM');
    await db.close();

    // Verify size
    final outSize = file.lengthSync();
    print('Final DB size: ${(outSize / 1024 / 1024).toStringAsFixed(2)} MB');
  });
}
