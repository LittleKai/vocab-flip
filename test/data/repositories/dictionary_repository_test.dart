import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/repositories/dictionary_repository.dart';

void main() {
  test('effectiveFetchMode preserves fetch mode on all platforms', () {
    expect(
      DictionaryRepository.effectiveFetchMode('both', isWeb: true),
      'both',
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
