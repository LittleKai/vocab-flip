// ignore_for_file: avoid_print
import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('assets/chinese_dict.db');

  // Test cases to verify Hán Việt extraction
  final testWords = ['啊', '嫕', '应和', '稳如泰山', '的', '中国', '学习'];

  for (final word in testWords) {
    final result = db.select(
      'SELECT word, pinyin, han_viet, definition FROM words WHERE word = ? LIMIT 1',
      [word],
    );

    print('─' * 50);
    if (result.isNotEmpty) {
      final row = result.first;
      print('Word: ${row['word']} (${word.length} chars)');
      print('Pinyin: ${row['pinyin']}');
      print('Hán Việt: ${row['han_viet'] ?? '(none)'}');
      print('Definition: ${(row['definition'] as String).split('\n').first}...');
    } else {
      print('Word: $word - NOT FOUND');
    }
  }

  print('─' * 50);
  db.dispose();
}
