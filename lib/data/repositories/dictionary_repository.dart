import 'package:flutter/foundation.dart';
import '../models/dictionary_result.dart';
import '../remote/api/free_dictionary_api.dart';
import '../remote/api/jisho_api.dart';
import '../remote/api/laban_api.dart';
import '../remote/api/mazii_api.dart';
import '../remote/api/chinese_dict_api.dart';
import '../local/database/offline_dict_dao.dart';
import '../remote/api/offline_stardict_api.dart';
import '../../core/constants/supported_languages.dart';
import '../remote/api/web_proxy_http_client.dart';

/// Result wrapper that includes fallback information
class DictionaryLookupResult {
  final List<DictionaryResult> results;
  final bool usedFallback;
  final String? fallbackSource;

  DictionaryLookupResult({
    required this.results,
    this.usedFallback = false,
    this.fallbackSource,
  });
}

class DictionaryRepository {
  final FreeDictionaryApi _freeDictionaryApi;
  final JishoApi _jishoApi;
  final LabanApi _labanApi;
  final MaziiApi _maziiApi;
  final ChineseDictApi _chineseDictApi;

  final OfflineStardictApi _offlineEnApi;
  final OfflineStardictApi _offlineZhApi;
  final OfflineStardictApi _offlineJaApi;

  DictionaryRepository({
    FreeDictionaryApi? freeDictionaryApi,
    JishoApi? jishoApi,
    LabanApi? labanApi,
    MaziiApi? maziiApi,
    ChineseDictApi? chineseDictApi,
  })  : _freeDictionaryApi = freeDictionaryApi ?? FreeDictionaryApi(client: kIsWeb ? WebProxyHttpClient() : null),
        _jishoApi = jishoApi ?? JishoApi(client: kIsWeb ? WebProxyHttpClient() : null),
        _labanApi = labanApi ?? LabanApi(client: kIsWeb ? WebProxyHttpClient() : null),
        _maziiApi = maziiApi ?? MaziiApi(client: kIsWeb ? WebProxyHttpClient() : null),
        _chineseDictApi = chineseDictApi ?? ChineseDictApi(),
        _offlineEnApi = OfflineStardictApi(
            dao: OfflineDictDao(
                assetName: 'assets/en_vi_dict.db', dbName: 'en_vi_dict.db'),
            sourceLanguage: 'en'),
        _offlineZhApi = OfflineStardictApi(
            dao: OfflineDictDao(
                assetName: 'assets/zh_vi_dict.db', dbName: 'zh_vi_dict.db'),
            sourceLanguage: 'zh'),
        _offlineJaApi = OfflineStardictApi(
            dao: OfflineDictDao(
                assetName: 'assets/ja_vi_dict.db', dbName: 'ja_vi_dict.db'),
            sourceLanguage: 'ja');

  static String effectiveFetchMode(String fetchMode, {required bool isWeb}) {
    return fetchMode;
  }

  /// Lookup all results for a word
  /// Returns DictionaryLookupResult with results and fallback info
  Future<DictionaryLookupResult> lookupAll(
    String word,
    SupportedLanguage language, {
    bool fallbackToEnglish = true,
    String fetchMode = 'both',
    int limit = 10,
    void Function(DictionaryResult)? onResult,
  }) async {
    fetchMode = effectiveFetchMode(fetchMode, isWeb: kIsWeb);
    debugPrint(
        '[DictionaryRepository] lookupAll: "$word" (fallback: $fallbackToEnglish, fetchMode: $fetchMode, limit: $limit)');

    Future<void> runParallel(
        List<Future<dynamic>> tasks, void Function(dynamic) onRes) async {
      await Future.wait(tasks.map((task) async {
        try {
          final res = await task;
          if (res != null) {
            onRes(res);
          }
        } catch (e) {
          debugPrint('[DictionaryRepository] Task error: $e');
        }
      }));
    }

    switch (language) {
      case SupportedLanguage.english:
        if (fetchMode == 'both') {
          final results = <DictionaryResult>[];

          final tasks = <Future<DictionaryResult?>>[];
          tasks.add(_offlineEnApi.lookup(word));
          tasks.add(_labanApi.lookup(word));

          await runParallel(tasks, (res) {
            if (res is DictionaryResult) {
              results.add(res);
              onResult?.call(res);
            }
          });

          if (results.isEmpty && fallbackToEnglish) {
            debugPrint('[DictionaryRepository] Falling back to FreeDictionary');
            final freeResult = await _freeDictionaryApi.lookup(word);
            if (freeResult != null) {
              onResult?.call(freeResult);
              return DictionaryLookupResult(
                results: [freeResult],
                usedFallback: true,
                fallbackSource: 'FreeDictionary (Anh-Anh)',
              );
            }
          }
          return DictionaryLookupResult(results: results);
        } else if (fetchMode == 'offline') {
          final offlineResult = await _offlineEnApi.lookup(word);
          if (offlineResult != null) {
            onResult?.call(offlineResult);
            return DictionaryLookupResult(results: [offlineResult]);
          }
          return DictionaryLookupResult(results: []);
        } else {
          // Online only
          final labanResult = await _labanApi.lookup(word);
          if (labanResult != null) {
            onResult?.call(labanResult);
            return DictionaryLookupResult(results: [labanResult]);
          }
          if (fallbackToEnglish) {
            final freeResult = await _freeDictionaryApi.lookup(word);
            if (freeResult != null) {
              onResult?.call(freeResult);
              return DictionaryLookupResult(
                results: [freeResult],
                usedFallback: true,
                fallbackSource: 'FreeDictionary (Anh-Anh)',
              );
            }
          }
          return DictionaryLookupResult(results: []);
        }

      case SupportedLanguage.japanese:
        if (fetchMode == 'both') {
          final results = <DictionaryResult>[];

          final tasks = <Future<dynamic>>[];
          tasks.add(_offlineJaApi.lookup(word));
          tasks.add(_maziiApi.search(word, limit: limit));

          await runParallel(tasks, (res) {
            if (res is DictionaryResult) {
              results.add(res);
              onResult?.call(res);
            } else if (res is List) {
              for (var r in res) {
                final dr = r.toDictionaryResult();
                results.add(dr);
                onResult?.call(dr);
              }
            }
          });

          if (results.isEmpty && fallbackToEnglish) {
            debugPrint('[DictionaryRepository] Falling back to Jisho');
            final jishoResults = await _jishoApi.search(word);
            final mapped =
                jishoResults.map((r) => r.toDictionaryResult()).toList();
            for (var dr in mapped) onResult?.call(dr);
            return DictionaryLookupResult(
              results: mapped,
              usedFallback: jishoResults.isNotEmpty,
              fallbackSource: 'Jisho (Nhật-Anh)',
            );
          }
          return DictionaryLookupResult(results: results);
        } else if (fetchMode == 'offline') {
          final offlineResultJa = await _offlineJaApi.lookup(word);
          if (offlineResultJa != null) {
            onResult?.call(offlineResultJa);
            return DictionaryLookupResult(results: [offlineResultJa]);
          }
          return DictionaryLookupResult(results: []);
        } else {
          // Online only
          final maziiResults = await _maziiApi.search(word, limit: limit);
          if (maziiResults.isNotEmpty) {
            final mapped =
                maziiResults.map((r) => r.toDictionaryResult()).toList();
            for (var dr in mapped) onResult?.call(dr);
            return DictionaryLookupResult(
              results: mapped,
            );
          }
          if (fallbackToEnglish) {
            final jishoResults = await _jishoApi.search(word);
            final mapped =
                jishoResults.map((r) => r.toDictionaryResult()).toList();
            for (var dr in mapped) onResult?.call(dr);
            return DictionaryLookupResult(
              results: mapped,
              usedFallback: jishoResults.isNotEmpty,
              fallbackSource: 'Jisho (Nhật-Anh)',
            );
          }
          return DictionaryLookupResult(results: []);
        }

      case SupportedLanguage.chinese:
        if (fetchMode == 'both') {
          final results = <DictionaryResult>[];

          final tasks = <Future<dynamic>>[];
          tasks.add(_offlineZhApi.lookup(word));
          tasks.add(_chineseDictApi.search(word, fetchMode: fetchMode));

          await runParallel(tasks, (res) {
            if (res is DictionaryResult) {
              results.add(res);
              onResult?.call(res);
            } else if (res is List) {
              for (var r in res) {
                final dr = r.toDictionaryResult();
                results.add(dr);
                onResult?.call(dr);
              }
            }
          });

          return DictionaryLookupResult(
            results: results,
          );
        } else if (fetchMode == 'offline') {
          // Try Offline StarDict first
          final offlineResultZh = await _offlineZhApi.lookup(word);
          if (offlineResultZh != null) {
            debugPrint(
                '[DictionaryRepository] Got Vietnamese result from Offline StarDict ZH');
            onResult?.call(offlineResultZh);
            return DictionaryLookupResult(results: [offlineResultZh]);
          }

          // Get all results from chineseDict (Chinese → Vietnamese)
          final chineseDictResults =
              await _chineseDictApi.search(word, fetchMode: fetchMode);
          if (chineseDictResults.isNotEmpty) {
            debugPrint(
                '[DictionaryRepository] Got ${chineseDictResults.length} Chinese-Vietnamese results from chineseDict');
            final mapped =
                chineseDictResults.map((r) => r.toDictionaryResult()).toList();
            for (var dr in mapped) onResult?.call(dr);
            return DictionaryLookupResult(
              results: mapped,
            );
          }
        } else {
          // Online only
          final chineseDictResults =
              await _chineseDictApi.search(word, fetchMode: fetchMode);
          final mapped =
              chineseDictResults.map((r) => r.toDictionaryResult()).toList();
          for (var dr in mapped) onResult?.call(dr);
          return DictionaryLookupResult(
            results: mapped,
          );
        }
        return DictionaryLookupResult(results: []);

      case SupportedLanguage.vietnamese:
        // Vietnamese is typically the target language
        return DictionaryLookupResult(results: []);
    }
  }

  /// Search for words with Vietnamese translation as primary
  Future<List<DictionaryResult>> search(
      String query, SupportedLanguage language,
      {String fetchMode = 'both'}) async {
    fetchMode = effectiveFetchMode(fetchMode, isWeb: kIsWeb);

    switch (language) {
      case SupportedLanguage.english:
        if (fetchMode == 'both') {
          final results = <DictionaryResult>[];
          final offlineResults = await _offlineEnApi.search(query);
          results.addAll(offlineResults);

          final labanResult = await _labanApi.lookup(query);
          if (labanResult != null) {
            results.add(labanResult);
          }

          if (results.isEmpty) {
            final freeResult = await _freeDictionaryApi.lookup(query);
            if (freeResult != null) results.add(freeResult);
          }
          return results;
        } else if (fetchMode == 'offline') {
          return await _offlineEnApi.search(query);
        } else {
          final labanResult = await _labanApi.lookup(query);
          if (labanResult != null) return [labanResult];
          final freeResult = await _freeDictionaryApi.lookup(query);
          return freeResult != null ? [freeResult] : [];
        }

      case SupportedLanguage.japanese:
        if (fetchMode == 'both') {
          final results = <DictionaryResult>[];
          final offlineResultsJa = await _offlineJaApi.search(query);
          results.addAll(offlineResultsJa);

          final maziiResults = await _maziiApi.search(query);
          for (var r in maziiResults) {
            results.add(r.toDictionaryResult());
          }

          if (results.isEmpty) {
            final jishoResults = await _jishoApi.search(query);
            return jishoResults.map((r) => r.toDictionaryResult()).toList();
          }
          return results;
        } else if (fetchMode == 'offline') {
          return await _offlineJaApi.search(query);
        } else {
          final maziiResults = await _maziiApi.search(query);
          if (maziiResults.isNotEmpty) {
            return maziiResults.map((r) => r.toDictionaryResult()).toList();
          }
          final jishoResults = await _jishoApi.search(query);
          return jishoResults.map((r) => r.toDictionaryResult()).toList();
        }

      case SupportedLanguage.chinese:
        if (fetchMode == 'both') {
          // Both: get from both and do not merge (keep separate cards)
          final offlineResultsZh = await _offlineZhApi.search(query);
          final chineseDictResults =
              await _chineseDictApi.search(query, fetchMode: fetchMode);
          final combined = [
            ...offlineResultsZh,
            ...chineseDictResults.map((r) => r.toDictionaryResult())
          ];

          return combined;
        } else if (fetchMode == 'offline') {
          final offlineResultsZh = await _offlineZhApi.search(query);
          if (offlineResultsZh.isNotEmpty) return offlineResultsZh;
          final chineseDictResults =
              await _chineseDictApi.search(query, fetchMode: fetchMode);
          return chineseDictResults.map((r) => r.toDictionaryResult()).toList();
        } else {
          // Online only
          final chineseDictResults =
              await _chineseDictApi.search(query, fetchMode: fetchMode);
          return chineseDictResults.map((r) => r.toDictionaryResult()).toList();
        }

      default:
        return [];
    }
  }

  /// Lookup using only Vietnamese dictionaries (no fallback)
  Future<DictionaryResult?> lookupVietnamese(
      String word, SupportedLanguage language,
      {String fetchMode = 'both'}) async {
    fetchMode = effectiveFetchMode(fetchMode, isWeb: kIsWeb);

    switch (language) {
      case SupportedLanguage.english:
        if (fetchMode == 'both') {
          final offlineResult = await _offlineEnApi.lookup(word);
          if (offlineResult != null) return offlineResult;
          return await _labanApi.lookup(word);
        } else if (fetchMode == 'offline') {
          return await _offlineEnApi.lookup(word);
        } else {
          return await _labanApi.lookup(word);
        }

      case SupportedLanguage.japanese:
        if (fetchMode == 'both') {
          final offlineResult = await _offlineJaApi.lookup(word);
          if (offlineResult != null) return offlineResult;
          final result = await _maziiApi.lookup(word);
          return result?.toDictionaryResult();
        } else if (fetchMode == 'offline') {
          return await _offlineJaApi.lookup(word);
        } else {
          final result = await _maziiApi.lookup(word);
          return result?.toDictionaryResult();
        }

      case SupportedLanguage.chinese:
        if (fetchMode == 'both' || fetchMode == 'offline') {
          final offlineResult = await _offlineZhApi.lookup(word);
          if (offlineResult != null) return offlineResult;
        }
        final result = await _chineseDictApi.lookup(word, fetchMode: fetchMode);
        return result?.toDictionaryResult();

      default:
        return null;
    }
  }

  /// Lookup using only English dictionaries
  Future<DictionaryResult?> lookupEnglish(
      String word, SupportedLanguage language) async {
    switch (language) {
      case SupportedLanguage.english:
        return await _freeDictionaryApi.lookup(word);
      case SupportedLanguage.japanese:
        final result = await _jishoApi.lookup(word);
        return result?.toDictionaryResult();
      default:
        return null;
    }
  }

  /// Search for Kanji suggestions based on hiragana/katakana/romaji input
  /// Uses Jisho API which returns all kanji variants for each word
  Future<List<String>> searchKanjiSuggestions(String query,
      {int limit = 10}) async {
    debugPrint(
        '[DictionaryRepository] searchKanjiSuggestions: "$query" (limit: $limit)');

    try {
      // Use Jisho's searchKanjiWords which extracts all kanji variants
      final allKanjiWords = await _jishoApi.searchKanjiWords(query);

      // Filter unique words that contain kanji
      final seen = <String>{};
      final kanjiWords = <String>[];

      for (final word in allKanjiWords) {
        if (!seen.contains(word) && _containsKanji(word)) {
          seen.add(word);
          kanjiWords.add(word);
          debugPrint('[DictionaryRepository] + Kanji: $word');
        }
      }

      debugPrint(
          '[DictionaryRepository] Returning ${kanjiWords.length} kanji words');
      return kanjiWords.take(limit).toList();
    } catch (e) {
      debugPrint('[DictionaryRepository] Error: $e');
      return [];
    }
  }

  /// Check if string contains kanji characters
  bool _containsKanji(String text) {
    // Kanji Unicode range: 4E00-9FFF (CJK Unified Ideographs)
    // Also includes: 3400-4DBF (CJK Extension A), F900-FAFF (CJK Compatibility)
    return RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF]').hasMatch(text);
  }
}
