// ignore_for_file: avoid_print
import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('assets/chinese_dict.db');

  // Test query for 啊
  final result = db.select(
    'SELECT word, pinyin, definition FROM words WHERE word = ? LIMIT 1',
    ['啊'],
  );

  if (result.isNotEmpty) {
    final row = result.first;
    print('Word: ${row['word']}');
    print('Pinyin: ${row['pinyin']}');
    print('Definition:');
    print(row['definition']);
  } else {
    print('Not found');
  }

  db.dispose();
}
