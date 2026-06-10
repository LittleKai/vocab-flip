import 'package:flutter/foundation.dart';
import '../../local/database/chinese_dict_dao.dart';
import '../../models/dictionary_result.dart';
import '../../api/api_client.dart';

/// Hanzii API for Chinese-Vietnamese translation
/// Uses local SQLite database from LacViet dictionary on mobile/desktop,
/// and falls back to Alpha Studio REST API on Web.
class HanziiApi {
  final ChineseDictDao _dao;
  final ApiClient _apiClient;

  HanziiApi({ChineseDictDao? dao, ApiClient? apiClient})
      : _dao = dao ?? ChineseDictDao.instance,
        _apiClient = apiClient ?? ApiClient();

  /// Initialize the database (should be called on app start)
  Future<void> init() async {
    if (!kIsWeb) {
      await _dao.init();
    }
  }

  /// Look up a Chinese word and get Vietnamese translation
  Future<HanziiResult?> lookup(String word) async {
    debugPrint('[HanziiApi] lookup: "$word"');

    try {
      if (kIsWeb) {
        // Use REST API for Web
        final response = await _apiClient.dio.get('/vocab/dictionary/chinese/lookup', queryParameters: {'word': word});
        if (response.data['success'] == true && response.data['data'] != null) {
          final data = response.data['data'];
          final entry = ChineseDictEntry(
            id: data['wordId'] ?? 0,
            word: data['word'] ?? '',
            pinyin: data['pinyin'],
            hanViet: data['hanViet'],
            definition: data['definition'] ?? '',
          );
          debugPrint('[HanziiApi] Found (Web): ${entry.word}');
          return _entryToResult(entry);
        }
        debugPrint('[HanziiApi] No exact match found (Web)');
        return null;
      } else {
        // Use local SQLite for Mobile/Desktop
        final entry = await _dao.lookup(word);
        if (entry == null) {
          debugPrint('[HanziiApi] No exact match found (Local)');
          return null;
        }

        debugPrint('[HanziiApi] Found (Local): ${entry.word}');
        return _entryToResult(entry);
      }
    } catch (e) {
      debugPrint('[HanziiApi] Error: $e');
      return null;
    }
  }

  /// Search for Chinese words
  Future<List<HanziiResult>> search(String query, {int limit = 10}) async {
    debugPrint('[HanziiApi] search: "$query" (limit: $limit)');

    try {
      if (kIsWeb) {
        // Use REST API for Web
        final response = await _apiClient.dio.get('/vocab/dictionary/chinese/search', queryParameters: {'query': query, 'limit': limit});
        if (response.data['success'] == true && response.data['data'] != null) {
          final items = response.data['data'] as List;
          final entries = items.map((data) => ChineseDictEntry(
            id: data['wordId'] ?? 0,
            word: data['word'] ?? '',
            pinyin: data['pinyin'],
            hanViet: data['hanViet'],
            definition: data['definition'] ?? '',
          )).toList();
          debugPrint('[HanziiApi] Found ${entries.length} results (Web)');
          return entries.map((e) => _entryToResult(e)).toList();
        }
        return [];
      } else {
        // Use local SQLite for Mobile/Desktop
        final entries = await _dao.search(query, limit: limit);
        debugPrint('[HanziiApi] Found ${entries.length} results (Local)');

        return entries.map((e) => _entryToResult(e)).toList();
      }
    } catch (e) {
      debugPrint('[HanziiApi] Error: $e');
      return [];
    }
  }

  /// Convert database entry to HanziiResult
  HanziiResult _entryToResult(ChineseDictEntry entry) {
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

    return HanziiResult(
      word: entry.word,
      phonetic: entry.pinyin,
      hanViet: entry.hanViet,
      shortMean: firstMeaning,
      meanings: [
        HanziiMeaning(
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

/// Result from Hanzii (Chinese-Vietnamese dictionary)
class HanziiResult {
  final String word;
  final String? phonetic;
  final String? hanViet;
  final String? shortMean;
  final List<HanziiMeaning> meanings;
  final List<String> relatedWords;
  final List<String> oppositeWords;
  final List<String> synonyms;
  final int? mobileId;

  HanziiResult({
    required this.word,
    this.phonetic,
    this.hanViet,
    this.shortMean,
    this.meanings = const [],
    this.relatedWords = const [],
    this.oppositeWords = const [],
    this.synonyms = const [],
    this.mobileId,
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

class HanziiMeaning {
  final String kind;
  final String meaning;
  final List<HanziiExample> examples;

  HanziiMeaning({
    required this.kind,
    required this.meaning,
    this.examples = const [],
  });
}

class HanziiExample {
  final String content;
  final String meaning;
  final String? pinyin;

  HanziiExample({
    required this.content,
    required this.meaning,
    this.pinyin,
  });
}
