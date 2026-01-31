import 'package:flutter/foundation.dart';
import '../../local/database/chinese_dict_dao.dart';
import '../../models/dictionary_result.dart';

/// Hanzii API for Chinese-Vietnamese translation
/// Uses local SQLite database from LacViet dictionary
class HanziiApi {
  final ChineseDictDao _dao;

  HanziiApi({ChineseDictDao? dao}) : _dao = dao ?? ChineseDictDao.instance;

  /// Initialize the database (should be called on app start)
  Future<void> init() async {
    await _dao.init();
  }

  /// Look up a Chinese word and get Vietnamese translation
  Future<HanziiResult?> lookup(String word) async {
    debugPrint('[HanziiApi] lookup: "$word"');

    try {
      final entry = await _dao.lookup(word);
      if (entry == null) {
        debugPrint('[HanziiApi] No exact match found');
        return null;
      }

      debugPrint('[HanziiApi] Found: ${entry.word}');
      return _entryToResult(entry);
    } catch (e) {
      debugPrint('[HanziiApi] Error: $e');
      return null;
    }
  }

  /// Search for Chinese words
  Future<List<HanziiResult>> search(String query, {int limit = 10}) async {
    debugPrint('[HanziiApi] search: "$query" (limit: $limit)');

    try {
      final entries = await _dao.search(query, limit: limit);
      debugPrint('[HanziiApi] Found ${entries.length} results');

      return entries.map((e) => _entryToResult(e)).toList();
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
