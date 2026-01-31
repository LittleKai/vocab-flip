// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

/// Tool to build Chinese-Vietnamese dictionary database from LacViet.txt
///
/// Usage:
///   dart run tools/build_chinese_dict.dart <path_to_lacviet.txt>
///
/// Example:
///   dart run tools/build_chinese_dict.dart "D:\Downloads\Quick Translator 2016\Quick Translator 2016\Data\LacViet.txt"

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tools/build_chinese_dict.dart <path_to_lacviet.txt>');
    print('Example: dart run tools/build_chinese_dict.dart "D:\\Downloads\\LacViet.txt"');
    exit(1);
  }

  final inputPath = args[0];
  final inputFile = File(inputPath);

  if (!inputFile.existsSync()) {
    print('Error: File not found: $inputPath');
    exit(1);
  }

  print('Reading LacViet.txt...');

  // Output database path
  final outputPath = 'assets/chinese_dict.db';
  final outputDir = Directory('assets');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Delete existing database
  final dbFile = File(outputPath);
  if (dbFile.existsSync()) {
    dbFile.deleteSync();
    print('Deleted existing database');
  }

  // Create database
  final db = sqlite3.open(outputPath);

  // Create tables
  db.execute('''
    CREATE TABLE words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word TEXT NOT NULL,
      pinyin TEXT,
      han_viet TEXT,
      definition TEXT NOT NULL
    )
  ''');

  db.execute('CREATE INDEX idx_word ON words(word)');
  db.execute('CREATE INDEX idx_pinyin ON words(pinyin)');

  print('Created database schema');

  // Read and parse file
  final lines = inputFile.readAsLinesSync(encoding: utf8);
  print('Read ${lines.length} lines');

  int count = 0;
  int errors = 0;

  // Prepare insert statement
  final stmt = db.prepare('''
    INSERT INTO words (word, pinyin, han_viet, definition)
    VALUES (?, ?, ?, ?)
  ''');

  // Begin transaction for faster inserts
  db.execute('BEGIN TRANSACTION');

  for (final line in lines) {
    if (line.trim().isEmpty) continue;

    try {
      final entry = _parseLine(line);
      if (entry != null) {
        stmt.execute([
          entry.word,
          entry.pinyin,
          entry.hanViet,
          entry.definition,
        ]);
        count++;

        if (count % 10000 == 0) {
          print('Processed $count entries...');
        }
      }
    } catch (e) {
      errors++;
      if (errors <= 5) {
        print('Error parsing line: ${line.substring(0, line.length.clamp(0, 50))}...');
        print('  Error: $e');
      }
    }
  }

  // Commit transaction
  db.execute('COMMIT');

  stmt.dispose();
  db.dispose();

  print('');
  print('Done!');
  print('  Total entries: $count');
  print('  Errors: $errors');
  print('  Output: $outputPath');
  print('');
  print('Database size: ${(dbFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB');
}

class DictEntry {
  final String word;
  final String? pinyin;
  final String? hanViet;
  final String definition;

  DictEntry({
    required this.word,
    this.pinyin,
    this.hanViet,
    required this.definition,
  });
}

/// Parse a line from LacViet.txt
/// Format: 阿哥=✚[āgē] \n\t1. đại ca; anh; huynh\n\t2. ...
/// Multiple pronunciations: 啊=✚[ā] Hán Việt: A a; chà; à\n✚[á] Hán Việt: A hả; há\n✚[à] \n\t1. ...\n\t2. ...
DictEntry? _parseLine(String line) {
  // Split by = to get word and definition
  final eqIndex = line.indexOf('=');
  if (eqIndex == -1) return null;

  final word = line.substring(0, eqIndex).trim();
  if (word.isEmpty) return null;

  var content = line.substring(eqIndex + 1);

  String? pinyin;
  String? hanViet;

  // Extract all pinyin from [pinyin] patterns (may have multiple pronunciations)
  final pinyinMatches = RegExp(r'\[([^\]]+)\]').allMatches(content);
  if (pinyinMatches.isNotEmpty) {
    pinyin = pinyinMatches.map((m) => m.group(1)).join(', ');
  }

  // Extract first Hán Việt for the field (usually single character)
  final hanVietMatch = RegExp(r'Hán Việt:\s*(\S+)').firstMatch(content);
  if (hanVietMatch != null) {
    hanViet = hanVietMatch.group(1)?.trim();
  }

  // Split by ✚ to get each pronunciation section
  final sections = content.split('✚');
  final definitions = <String>[];

  for (var section in sections) {
    if (section.trim().isEmpty) continue;

    // Remove [pinyin] pattern
    section = section.replaceAll(RegExp(r'\[[^\]]+\]\s*'), '');

    // Check for "Hán Việt: X definition" pattern (definition after single char)
    final hvMatch = RegExp(r'Hán Việt:\s*\S+\s+(.+?)(?=\\n|$)').firstMatch(section);
    if (hvMatch != null) {
      final inlineDef = hvMatch.group(1)?.trim();
      if (inlineDef != null && inlineDef.isNotEmpty && !inlineDef.startsWith('1.')) {
        definitions.add(inlineDef);
      }
    }

    // Remove "Hán Việt: X" part for numbered definitions
    section = section.replaceAll(RegExp(r'Hán Việt:\s*\S+\s*'), '');

    // Convert literal \n\t to newlines
    section = section.replaceAll(r'\n\t', '\n').replaceAll(r'\n', '\n').replaceAll(r'\t', '');

    // Extract numbered definitions
    final numPattern = RegExp(r'(\d+)\.\s*([^\n]+)');
    for (final match in numPattern.allMatches(section)) {
      final def = match.group(2)?.trim();
      if (def != null && def.isNotEmpty) {
        definitions.add(def);
      }
    }

    // If no numbered or inline definitions, try to get any remaining text
    if (definitions.isEmpty) {
      final remaining = section.trim();
      if (remaining.isNotEmpty) {
        definitions.add(remaining);
      }
    }
  }

  if (definitions.isEmpty) {
    return null;
  }

  // Build definition with sequential numbering
  String definition;
  if (definitions.length == 1) {
    definition = definitions.first;
  } else {
    definition = definitions
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');
  }

  return DictEntry(
    word: word,
    pinyin: pinyin,
    hanViet: hanViet,
    definition: definition,
  );
}
