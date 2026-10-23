import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabflip/core/constants/supported_languages.dart';
import 'package:vocabflip/data/local/preferences/app_preferences.dart';
import 'package:vocabflip/data/models/dictionary_result.dart';
import 'package:vocabflip/data/repositories/dictionary_repository.dart';
import 'package:vocabflip/presentation/providers/dictionary_provider.dart';

class _PendingLookup {
  final completion = Completer<DictionaryLookupResult>();
  final void Function(DictionaryResult)? onResult;
  _PendingLookup(this.onResult);
}

class _Repository extends DictionaryRepository {
  final pending = <_PendingLookup>[];

  @override
  Future<DictionaryLookupResult> lookupAll(
    String word,
    SupportedLanguage language, {
    bool fallbackToEnglish = true,
    String fetchMode = 'both',
    int limit = 10,
    void Function(DictionaryResult)? onResult,
  }) {
    final request = _PendingLookup(onResult);
    pending.add(request);
    return request.completion.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DictionaryProvider provider;
  late _Repository repository;

  setUp(() async {
    dotenv.testLoad(fileInput: '');
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPreferences();
    await prefs.init();
    repository = _Repository();
    provider = DictionaryProvider(repository: repository, prefs: prefs);
    addTearDown(provider.dispose);
  });

  test('language changes clear results and ignore stale partial/final results',
      () async {
    final request = provider.lookup('cat');
    final old = DictionaryResult(word: 'cat', sourceLanguage: 'en');
    repository.pending.single.onResult!(old);
    expect(provider.results, [old]);
    provider.setLanguage(SupportedLanguage.japanese);
    expect(provider.results, isEmpty);
    expect(provider.isLoading, isFalse);
    repository.pending.single.onResult!(old);
    repository.pending.single.completion.complete(DictionaryLookupResult(
      results: [old],
      usedFallback: true,
      fallbackSource: 'old',
    ));
    await request;
    expect(provider.results, isEmpty);
    expect(provider.usedFallback, isFalse);
    expect(provider.fallbackSource, isNull);
    expect(provider.error, isNull);
  });

  test('new query ignores old errors without clearing current loading state',
      () async {
    final old = provider.lookup('cat');
    final current = provider.lookup('dog');
    repository.pending.first.completion.completeError(StateError('old'));
    await old;
    expect(provider.isLoading, isTrue);
    expect(provider.error, isNull);
    final dog = DictionaryResult(word: 'dog');
    repository.pending.last.completion
        .complete(DictionaryLookupResult(results: [dog]));
    await current;
    expect(provider.results, [dog]);
    expect(provider.isLoading, isFalse);
  });

  test('clear and blank queries invalidate requests already running', () async {
    for (final blank in [false, true]) {
      final request = provider.lookup('cat');
      if (blank) {
        await provider.lookup('  ');
      } else {
        provider.clearResults();
      }
      repository.pending.last.completion.complete(DictionaryLookupResult(
        results: [DictionaryResult(word: 'cat')],
      ));
      await request;
      expect(provider.results, isEmpty);
      expect(provider.isLoading, isFalse);
    }
  });
}
