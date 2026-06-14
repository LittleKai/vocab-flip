import 'package:flutter/foundation.dart';
import '../../local/database/chinese_dict_dao.dart';
import '../../models/dictionary_result.dart';
import '../../api/api_client.dart';
import 'package:lpinyin/lpinyin.dart';

/// chineseDict API for Chinese-Vietnamese translation
/// Uses local SQLite database from LacViet dictionary on mobile/desktop,
/// and falls back to Alpha Studio REST API on Web.
class ChineseDictApi {
  final ChineseDictDao _dao;
  final ApiClient _apiClient;

  ChineseDictApi({ChineseDictDao? dao, ApiClient? apiClient})
      : _dao = dao ?? ChineseDictDao.instance,
        _apiClient = apiClient ?? ApiClient();

  /// Initialize the database (should be called on app start)
  Future<void> init() async {
    if (!kIsWeb) {
      await _dao.init();
    }
  }

  /// Look up a Chinese word and get Vietnamese translation
  Future<ChineseDictResult?> lookup(String word,
      {String fetchMode = 'both'}) async {
    final String searchWord = ChineseHelper.convertToSimplifiedChinese(word);
    debugPrint(
        '[ChineseDictApi] lookup: "$word" -> "$searchWord" (fetchMode: $fetchMode)');

    try {
      bool tryOnline = fetchMode == 'online' || (fetchMode == 'both' && kIsWeb);
      bool tryOffline =
          (fetchMode == 'offline' || fetchMode == 'both') && !kIsWeb;

      debugPrint(
          '[ChineseDictApi] lookup flags - tryOnline: $tryOnline, tryOffline: $tryOffline');

      ChineseDictResult? apiResult;
      if (tryOnline) {
        try {
          debugPrint(
              '[ChineseDictApi] lookup - Calling API /vocab/dictionary/chinese/lookup');
          final response = await _apiClient.dio.get(
              '/vocab/dictionary/chinese/lookup',
              queryParameters: {'word': searchWord});
          debugPrint(
              '[ChineseDictApi] lookup - API Response Status: ${response.statusCode}');
          if (response.data['success'] == true &&
              response.data['data'] != null) {
            final data = response.data['data'];
            final entry = ChineseDictEntry(
              id: data['wordId'] ?? 0,
              word: data['word'] ?? '',
              pinyin: data['pinyin'],
              hanViet: data['hanViet'],
              definition: data['definition'] ?? '',
            );
            debugPrint('[ChineseDictApi] Found (REST API): ${entry.word}');
            apiResult = _entryToResult(entry, dataSource: 'Từ điển trực tuyến (Lạc Việt)');
          } else {
            debugPrint('[ChineseDictApi] API returned no valid data');
          }
        } catch (apiError) {
          debugPrint('[ChineseDictApi] API Error: $apiError');
        }
      }

      ChineseDictResult? dbResult;
      if (tryOffline && apiResult == null) {
        debugPrint('[ChineseDictApi] lookup - Calling SQLite DB');
        final entry = await _dao.lookup(searchWord);
        if (entry == null) {
          debugPrint('[ChineseDictApi] No exact match found (Local DB)');
        } else {
          debugPrint('[ChineseDictApi] Found (Local DB): ${entry.word}');
          dbResult = _entryToResult(entry);
        }
      }

      // Prefer API result, fallback to DB
      return apiResult ?? dbResult;
    } catch (e) {
      debugPrint('[ChineseDictApi] Error: $e');
      return null;
    }
  }

  /// Search for Chinese words
  Future<List<ChineseDictResult>> search(String query,
      {int limit = 10, String fetchMode = 'both'}) async {
    final String searchQuery = ChineseHelper.convertToSimplifiedChinese(query);
    debugPrint(
        '[ChineseDictApi] search: "$query" -> "$searchQuery" (limit: $limit, fetchMode: $fetchMode)');

    try {
      bool tryOnline = fetchMode == 'online' || (fetchMode == 'both' && kIsWeb);
      bool tryOffline =
          (fetchMode == 'offline' || fetchMode == 'both') && !kIsWeb;

      debugPrint(
          '[ChineseDictApi] search flags - tryOnline: $tryOnline, tryOffline: $tryOffline');

      List<ChineseDictResult> apiResults = [];
      if (tryOnline) {
        try {
          debugPrint(
              '[ChineseDictApi] search - Calling API /vocab/dictionary/chinese/search');
          final response = await _apiClient.dio.get(
              '/vocab/dictionary/chinese/search',
              queryParameters: {'query': searchQuery, 'limit': limit});
          debugPrint(
              '[ChineseDictApi] search - API Response Status: ${response.statusCode}');
          if (response.data['success'] == true &&
              response.data['data'] != null) {
            final items = response.data['data'] as List;
            final entries = items
                .map((data) => ChineseDictEntry(
                      id: data['wordId'] ?? 0,
                      word: data['word'] ?? '',
                      pinyin: data['pinyin'],
                      hanViet: data['hanViet'],
                      definition: data['definition'] ?? '',
                    ))
                .toList();
            debugPrint(
                '[ChineseDictApi] Found ${entries.length} results (REST API)');
            apiResults = entries
                .map((e) => _entryToResult(e, dataSource: 'Từ điển trực tuyến (Lạc Việt)'))
                .toList();
          } else {
            debugPrint('[ChineseDictApi] API returned no valid data');
          }
        } catch (apiError) {
          debugPrint('[ChineseDictApi] API Error: $apiError');
        }
      }

      List<ChineseDictResult> dbResults = [];
      if (tryOffline && apiResults.isEmpty) {
        debugPrint('[ChineseDictApi] search - Calling SQLite DB');
        final entries = await _dao.search(query, limit: limit);
        debugPrint(
            '[ChineseDictApi] Found ${entries.length} results (Local DB)');
        dbResults = entries.map((e) => _entryToResult(e)).toList();
      }

      // Combine and deduplicate
      if (fetchMode == 'both') {
        final Map<String, ChineseDictResult> combined = {};
        for (var r in dbResults) combined[r.word] = r; // DB first
        for (var r in apiResults)
          combined[r.word] = r; // API overrides DB if same word
        debugPrint('[ChineseDictApi] Combined results: ${combined.length}');
        return combined.values.toList();
      }

      return tryOnline && fetchMode == 'online' ? apiResults : dbResults;
    } catch (e) {
      debugPrint('[ChineseDictApi] Error: $e');
      return [];
    }
  }

  /// Convert database entry to ChineseDictResult
  ChineseDictResult _entryToResult(ChineseDictEntry entry,
      {String dataSource = 'Offline DB (LacViet)'}) {
    // Keep all definitions as a single meaning to preserve numbering
    // The definition already has proper numbering from the database
    final definition = entry.definition.trim();

    // Extract first line for shortMean (without number prefix)
    String? firstMeaning;
    final firstLine = definition.split('\n').first;
    final numMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(firstLine);
    if (numMatch != null) {
      firstMeaning = numMatch.group(2)?.trim();
    } else {
      firstMeaning = firstLine.trim();
    }

    return ChineseDictResult(
      word: entry.word,
      phonetic: entry.pinyin,
      hanViet: entry.hanViet,
      shortMean: firstMeaning,
      dataSource: dataSource,
      meanings: [
        ChineseDictMeaning(
          kind: '',
          meaning: definition, // Keep full definition with numbering
          examples: [],
        ),
      ],
    );
  }

  void dispose() {
    // Database is shared singleton, don't close it
  }
}

/// Result from chineseDict (Chinese-Vietnamese dictionary)
class ChineseDictResult {
  final String word;
  final String? phonetic;
  final String? hanViet;
  final String? shortMean;
  final List<ChineseDictMeaning> meanings;
  final List<String> relatedWords;
  final List<String> oppositeWords;
  final List<String> synonyms;
  final int? mobileId;
  final String dataSource;

  ChineseDictResult({
    required this.word,
    this.phonetic,
    this.hanViet,
    this.shortMean,
    this.meanings = const [],
    this.relatedWords = const [],
    this.oppositeWords = const [],
    this.synonyms = const [],
    this.mobileId,
    this.dataSource = 'Từ điển trực tuyến (Lạc Việt)',
  });

  /// Convert to generic DictionaryResult
  DictionaryResult toDictionaryResult() {
    // Build phonetic string with Han-Viet if available
    String? fullPhonetic = phonetic;
    if (hanViet != null && hanViet!.isNotEmpty) {
      if (fullPhonetic != null) {
        fullPhonetic = '$fullPhonetic (HV: $hanViet)';
      } else {
        fullPhonetic = 'HV: $hanViet';
      }
    }

    return DictionaryResult(
      word: word,
      phonetic: fullPhonetic,
      sourceLanguage: 'zh',
      dataSource: dataSource,
      meanings: meanings.map((m) {
        final allExamples = m.examples.map((ex) {
          if (ex.meaning.isNotEmpty) {
            return '${ex.content}\n→ ${ex.meaning}';
          }
          return ex.content;
        }).join('\n\n');

        return DictionaryMeaning(
          partOfSpeech: m.kind,
          definitions: [
            DictionaryDefinition(
              definition: m.meaning,
              example: allExamples.isNotEmpty ? allExamples : null,
            ),
          ],
          synonyms: synonyms,
          antonyms: oppositeWords,
        );
      }).toList(),
    );
  }

  String? get primaryDefinition {
    if (meanings.isEmpty) return null;
    return meanings.first.meaning;
  }

  String? get firstExample {
    for (final m in meanings) {
      if (m.examples.isNotEmpty) {
        return m.examples.first.content;
      }
    }
    return null;
  }
}

class ChineseDictMeaning {
  final String kind;
  final String meaning;
  final List<ChineseDictExample> examples;

  ChineseDictMeaning({
    required this.kind,
    required this.meaning,
    this.examples = const [],
  });
}

class ChineseDictExample {
  final String content;
  final String meaning;
  final String? pinyin;

  ChineseDictExample({
    required this.content,
    required this.meaning,
    this.pinyin,
  });
}
