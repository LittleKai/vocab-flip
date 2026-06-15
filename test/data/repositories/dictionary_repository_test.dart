import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/repositories/dictionary_repository.dart';

void main() {
  test('effectiveFetchMode keeps web both lookups offline', () {
    expect(
      DictionaryRepository.effectiveFetchMode('both', isWeb: true),
      'offline',
    );
    expect(
      DictionaryRepository.effectiveFetchMode('online', isWeb: true),
      'online',
    );
    expect(
      DictionaryRepository.effectiveFetchMode('both', isWeb: false),
      'both',
    );
  });
}
