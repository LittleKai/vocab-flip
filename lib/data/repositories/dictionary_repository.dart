import 'package:flutter/foundation.dart';
import '../models/dictionary_result.dart';
import '../remote/api/free_dictionary_api.dart';
import '../remote/api/jisho_api.dart';
import '../remote/api/laban_api.dart';
import '../remote/api/mazii_api.dart';
import '../remote/api/hanzii_api.dart';
import '../../core/constants/supported_languages.dart';

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
  final HanziiApi _hanziiApi;

  DictionaryRepository({
    FreeDictionaryApi? freeDictionaryApi,
    JishoApi? jishoApi,
    LabanApi? labanApi,
    MaziiApi? maziiApi,
    HanziiApi? hanziiApi,
  })  : _freeDictionaryApi = freeDictionaryApi ?? FreeDictionaryApi(),
        _jishoApi = jishoApi ?? JishoApi(),
        _labanApi = labanApi ?? LabanApi(),
        _maziiApi = maziiApi ?? MaziiApi(),
        _hanziiApi = hanziiApi ?? HanziiApi();

  /// Lookup all results for a word
  /// Returns DictionaryLookupResult with results and fallback info
  Future<DictionaryLookupResult> lookupAll(
    String word,
    SupportedLanguage language, {
    bool fallbackToEnglish = true,
  }) async {
    debugPrint('[DictionaryRepository] lookupAll: "$word" (fallback: $fallbackToEnglish)');

    switch (language) {
      case SupportedLanguage.english:
        // Try Laban (English → Vietnamese) first
        final labanResult = await _labanApi.lookup(word);
        if (labanResult != null) {
          debugPrint('[DictionaryRepository] Got Vietnamese result from Laban');
          return DictionaryLookupResult(results: [labanResult]);
        }
        // Fallback to FreeDictionary (English → English)
        if (fallbackToEnglish) {
          debugPrint('[DictionaryRepository] Falling back to FreeDictionary');
          final freeResult = await _freeDictionaryApi.lookup(word);
          if (freeResult != null) {
            return DictionaryLookupResult(
              results: [freeResult],
              usedFallback: true,
              fallbackSource: 'FreeDictionary (Anh-Anh)',
            );
          }
        }
        return DictionaryLookupResult(results: []);

      case SupportedLanguage.japanese:
        // Get all results from Mazii (Japanese → Vietnamese)
        final maziiResults = await _maziiApi.search(word);
        if (maziiResults.isNotEmpty) {
          debugPrint('[DictionaryRepository] Got ${maziiResults.length} Vietnamese results from Mazii');
          return DictionaryLookupResult(
            results: maziiResults.map((r) => r.toDictionaryResult()).toList(),
          );
        }
        // Fallback to Jisho (Japanese → English)
        if (fallbackToEnglish) {
          debugPrint('[DictionaryRepository] Falling back to Jisho');
          final jishoResults = await _jishoApi.search(word);
          return DictionaryLookupResult(
            results: jishoResults.map((r) => r.toDictionaryResult()).toList(),
            usedFallback: jishoResults.isNotEmpty,
            fallbackSource: 'Jisho (Nhật-Anh)',
          );
        }
        return DictionaryLookupResult(results: []);

      case SupportedLanguage.chinese:
        // Get all results from Hanzii (Chinese → Vietnamese)
        final hanziiResults = await _hanziiApi.search(word);
        if (hanziiResults.isNotEmpty) {
          debugPrint('[DictionaryRepository] Got ${hanziiResults.length} Chinese-Vietnamese results from Hanzii');
          return DictionaryLookupResult(
            results: hanziiResults.map((r) => r.toDictionaryResult()).toList(),
          );
        }
        // No fallback for Chinese yet
        return DictionaryLookupResult(results: []);

      case SupportedLanguage.vietnamese:
        // Vietnamese is typically the target language
        return DictionaryLookupResult(results: []);
    }
  }

  /// Search for words with Vietnamese translation as primary
  Future<List<DictionaryResult>> search(String query, SupportedLanguage language) async {
    switch (language) {
      case SupportedLanguage.english:
        // Try Laban first
        final labanResult = await _labanApi.lookup(query);
        if (labanResult != null) {
          return [labanResult];
        }
        // Fallback to FreeDictionary
        final freeResult = await _freeDictionaryApi.lookup(query);
        return freeResult != null ? [freeResult] : [];

      case SupportedLanguage.japanese:
        // Try Mazii first
        final maziiResults = await _maziiApi.search(query);
        if (maziiResults.isNotEmpty) {
          return maziiResults.map((r) => r.toDictionaryResult()).toList();
        }
        // Fallback to Jisho
        final jishoResults = await _jishoApi.search(query);
        return jishoResults.map((r) => r.toDictionaryResult()).toList();

      case SupportedLanguage.chinese:
        // Use Hanzii for Chinese → Vietnamese
        final hanziiResults = await _hanziiApi.search(query);
        return hanziiResults.map((r) => r.toDictionaryResult()).toList();

      default:
        return [];
    }
  }

  /// Lookup using only Vietnamese dictionaries (no fallback)
  Future<DictionaryResult?> lookupVietnamese(String word, SupportedLanguage language) async {
    switch (language) {
      case SupportedLanguage.english:
        return await _labanApi.lookup(word);
      case SupportedLanguage.japanese:
        final result = await _maziiApi.lookup(word);
        return result?.toDictionaryResult();
      case SupportedLanguage.chinese:
        final result = await _hanziiApi.lookup(word);
        return result?.toDictionaryResult();
      default:
        return null;
    }
  }

  /// Lookup using only English dictionaries
  Future<DictionaryResult?> lookupEnglish(String word, SupportedLanguage language) async {
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
  Future<List<String>> searchKanjiSuggestions(String query, {int limit = 10}) async {
    debugPrint('[DictionaryRepository] searchKanjiSuggestions: "$query" (limit: $limit)');

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

      debugPrint('[DictionaryRepository] Returning ${kanjiWords.length} kanji words');
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
