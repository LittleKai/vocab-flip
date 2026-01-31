import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/romaji_converter.dart';
import '../../models/dictionary_result.dart';

/// Decode response body as UTF-8
String _decodeUtf8(http.Response response) {
  try {
    return utf8.decode(response.bodyBytes);
  } catch (e) {
    return response.body;
  }
}

/// Mazii API for Japanese-Vietnamese translation
class MaziiApi {
  final http.Client _client;

  MaziiApi({http.Client? client}) : _client = client ?? http.Client();

  /// Look up a Japanese word and get Vietnamese translation (default filter: exact_first)
  Future<MaziiResult?> lookup(String word) async {
    return lookupWithFilter(word, filterMode: 'exact_first');
  }

  /// Look up with configurable filter mode
  /// [filterMode]: 'exact_first', 'with_meanings', or 'all'
  Future<MaziiResult?> lookupWithFilter(String word, {String filterMode = 'exact_first'}) async {
    debugPrint('[MaziiApi] lookup: "$word" (filter: $filterMode)');
    final results = await search(word);

    if (results.isEmpty) {
      debugPrint('[MaziiApi] No results found');
      return null;
    }

    switch (filterMode) {
      case 'all':
        // Return first result without any filtering
        debugPrint('[MaziiApi] Filter=all, returning first: ${results.first.word}');
        return results.first;

      case 'with_meanings':
        // Return first result that has meanings
        for (final result in results) {
          if (result.meanings.isNotEmpty) {
            debugPrint('[MaziiApi] Filter=with_meanings, found: ${result.word}');
            return result;
          }
        }
        // Try to get detail by mobileId
        for (final result in results) {
          if (result.mobileId != null && result.mobileId! > 0) {
            final detail = await getWordDetail(result.mobileId!);
            if (detail != null && detail.meanings.isNotEmpty) {
              debugPrint('[MaziiApi] Filter=with_meanings, got detail: ${detail.word}');
              return detail;
            }
          }
        }
        debugPrint('[MaziiApi] Filter=with_meanings, no result with meanings');
        return null;

      case 'exact_first':
      default:
        // 1. First try to find exact match with meanings
        for (final result in results) {
          if (result.word == word && result.meanings.isNotEmpty) {
            debugPrint('[MaziiApi] Found exact match with meanings: ${result.word}');
            return result;
          }
        }

        // 2. Try to find exact match and get detail by mobileId
        for (final result in results) {
          if (result.word == word && result.mobileId != null && result.mobileId! > 0) {
            debugPrint('[MaziiApi] Trying detail for exact match: ${result.word} (mobileId: ${result.mobileId})');
            final detail = await getWordDetail(result.mobileId!);
            if (detail != null && detail.meanings.isNotEmpty) {
              debugPrint('[MaziiApi] Got detail with meanings: ${detail.word}');
              return detail;
            }
          }
        }

        // 3. If no exact match, find any result with meanings
        for (final result in results) {
          if (result.meanings.isNotEmpty) {
            debugPrint('[MaziiApi] Found result with meanings (not exact): ${result.word}');
            return result;
          }
        }

        // 4. Try to get detail by mobileId for any result
        for (final result in results) {
          if (result.mobileId != null && result.mobileId! > 0) {
            debugPrint('[MaziiApi] Trying detail for mobileId: ${result.mobileId}');
            final detail = await getWordDetail(result.mobileId!);
            if (detail != null && detail.meanings.isNotEmpty) {
              debugPrint('[MaziiApi] Got detail with meanings: ${detail.word}');
              return detail;
            }
          }
        }

        // 5. Return first result anyway (might have phonetic)
        debugPrint('[MaziiApi] No result with meanings, returning first: ${results.first.word}');
        return results.first;
    }
  }

  /// Get word detail by mobileId
  Future<MaziiResult?> getWordDetail(int mobileId) async {
    try {
      final url = ApiEndpoints.maziiDetail(mobileId);
      debugPrint('[MaziiApi] GET detail $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'VocabFlip/1.0',
        },
      );
      debugPrint('[MaziiApi] Detail response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = _decodeUtf8(response);
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (data['status'] == 200) {
          final resultData = data['data'];
          if (resultData is Map<String, dynamic>) {
            return _parseResult(resultData);
          }
        }
      }
    } catch (e) {
      debugPrint('[MaziiApi] Detail error: $e');
    }
    return null;
  }

  /// Search for Japanese words using POST API
  /// Automatically converts romaji to hiragana since Mazii doesn't support romaji
  Future<List<MaziiResult>> search(String query, {int limit = 10, int page = 1}) async {
    // Convert romaji to hiragana if needed
    String searchQuery = query;
    if (RomajiConverter.isRomaji(query) && !RomajiConverter.isJapanese(query)) {
      searchQuery = RomajiConverter.toHiragana(query);
      debugPrint('[MaziiApi] Converted romaji "$query" to hiragana "$searchQuery"');
    }

    try {
      // Try POST API first (returns full definitions)
      final postResult = await _searchPost(searchQuery, limit: limit, page: page);
      if (postResult.isNotEmpty) {
        return postResult;
      }

      // Fallback to GET API
      return await _searchGet(searchQuery, limit: limit, page: page);
    } catch (e) {
      debugPrint('[MaziiApi] Search error: $e');
      return [];
    }
  }

  /// Search using POST API (better results with meanings)
  Future<List<MaziiResult>> _searchPost(String query, {int limit = 10, int page = 1}) async {
    try {
      const url = ApiEndpoints.maziiSearch;
      debugPrint('[MaziiApi] POST $url (query: $query)');

      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'VocabFlip/1.0',
        },
        body: jsonEncode({
          'dict': 'javi',
          'type': 'word',
          'query': query,
          'limit': limit,
          'page': page,
        }),
      );
      debugPrint('[MaziiApi] POST Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = _decodeUtf8(response);
        debugPrint('[MaziiApi] POST Response body: $body');
        final data = jsonDecode(body) as Map<String, dynamic>;
        final status = data['status'];

        if (status == 200) {
          final results = data['data'] as List<dynamic>? ?? [];
          debugPrint('[MaziiApi] POST Found ${results.length} results');
          if (results.isNotEmpty) {
            final parsed = <MaziiResult>[];
            for (final r in results) {
              final result = _parseResult(r as Map<String, dynamic>);
              if (result != null) {
                parsed.add(result);
                debugPrint('[MaziiApi] POST + Word: ${result.word} (meanings: ${result.meanings.length})');
              }
            }
            debugPrint('[MaziiApi] POST Parsed ${parsed.length} valid results');
            return parsed;
          }
        }
      }
    } catch (e) {
      debugPrint('[MaziiApi] POST error: $e');
    }
    return [];
  }

  /// Search using GET API (legacy, may not have meanings)
  Future<List<MaziiResult>> _searchGet(String query, {int limit = 10, int page = 1}) async {
    try {
      final url = ApiEndpoints.mazii(query, limit: limit, page: page);
      debugPrint('[MaziiApi] GET $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'VocabFlip/1.0',
        },
      );
      debugPrint('[MaziiApi] GET Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = _decodeUtf8(response);
        debugPrint('[MaziiApi] GET Response body: $body');
        final data = jsonDecode(body) as Map<String, dynamic>;
        final status = data['status'];

        // Accept results if status is 200 and data is not empty
        // Note: 'found' can be false but still have relevant results
        if (status == 200) {
          final results = data['data'] as List<dynamic>? ?? [];
          debugPrint('[MaziiApi] GET Found ${results.length} results');
          if (results.isNotEmpty) {
            final parsed = <MaziiResult>[];
            for (final r in results) {
              final result = _parseResult(r as Map<String, dynamic>);
              if (result != null) {
                parsed.add(result);
                debugPrint('[MaziiApi] + Word: ${result.word}');
              }
            }
            debugPrint('[MaziiApi] Parsed ${parsed.length} valid results');
            return parsed;
          }
        }
      }
    } catch (e) {
      debugPrint('[MaziiApi] Error: $e');
    }
    return [];
  }

  MaziiResult? _parseResult(Map<String, dynamic> json) {
    try {
      final word = json['word'] as String? ?? '';
      if (word.isEmpty) return null;

      // Phonetic can be String or sometimes other types
      String? phonetic;
      final phoneticRaw = json['phonetic'];
      if (phoneticRaw is String) {
        phonetic = phoneticRaw;
      }

      final mobileId = json['mobileId'] as int?;

      // Parse meanings - handle both List and other types safely
      final meanings = <MaziiMeaning>[];
      final meansRaw = json['means'];
      debugPrint('[MaziiApi] Parsing "$word": means type=${meansRaw.runtimeType}');
      if (meansRaw is List) {
        for (final m in meansRaw) {
          if (m is Map<String, dynamic>) {
            // Kind can be String or null
            String kind = '';
            final kindRaw = m['kind'] ?? m['field'];
            if (kindRaw is String) {
              kind = kindRaw;
            }

            // Mean should be String
            String mean = '';
            final meanRaw = m['mean'];
            if (meanRaw is String) {
              mean = meanRaw;
            }

            // Parse examples - handle both List and other types
            final examples = <MaziiExample>[];
            final examplesRaw = m['examples'];
            if (examplesRaw is List) {
              for (final ex in examplesRaw) {
                if (ex is Map<String, dynamic>) {
                  final content = ex['content'];
                  final exMean = ex['mean'];
                  final transcription = ex['transcription'];
                  examples.add(MaziiExample(
                    content: content is String ? content : '',
                    meaning: exMean is String ? exMean : '',
                    transcription: transcription is String ? transcription : null,
                  ));
                }
              }
            }

            if (mean.isNotEmpty) {
              meanings.add(MaziiMeaning(
                kind: kind,
                meaning: mean,
                examples: examples,
              ));
            }
          }
        }
      }

      // Parse related words - handle both List and String
      final relatedWords = <String>[];
      final related = json['related_words'];
      if (related is List) {
        for (final r in related) {
          if (r is String) {
            relatedWords.add(r);
          } else if (r is Map<String, dynamic>) {
            final w = r['word'];
            if (w is String) relatedWords.add(w);
          }
        }
      } else if (related is String) {
        relatedWords.add(related);
      }

      // Parse opposite words (can be String, List<String>, or null)
      final oppositeWords = <String>[];
      final opposite = json['opposite_word'];
      if (opposite is String) {
        oppositeWords.add(opposite);
      } else if (opposite is List) {
        for (final o in opposite) {
          if (o is String) {
            oppositeWords.add(o);
          }
        }
      }

      // Parse short_mean
      final shortMean = json['short_mean'] as String?;

      // Parse synonyms from synsets
      final synonyms = <String>[];
      final synsets = json['synsets'];
      if (synsets is List) {
        for (final s in synsets) {
          if (s is Map<String, dynamic>) {
            final entry = s['entry'];
            if (entry is List) {
              for (final e in entry) {
                if (e is Map<String, dynamic>) {
                  final syn = e['synonym'];
                  if (syn is List) {
                    for (final w in syn) {
                      if (w is String && !synonyms.contains(w)) {
                        synonyms.add(w);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      return MaziiResult(
        word: word,
        phonetic: phonetic,
        shortMean: shortMean,
        meanings: meanings,
        relatedWords: relatedWords,
        oppositeWords: oppositeWords,
        synonyms: synonyms,
        mobileId: mobileId,
      );
    } catch (e) {
      debugPrint('MaziiApi: Error parsing result: $e');
      debugPrint('MaziiApi: JSON was: $json');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Result from Mazii API for Japanese-Vietnamese
class MaziiResult {
  final String word;
  final String? phonetic;
  final String? shortMean;
  final List<MaziiMeaning> meanings;
  final List<String> relatedWords;
  final List<String> oppositeWords;
  final List<String> synonyms;
  final int? mobileId;

  MaziiResult({
    required this.word,
    this.phonetic,
    this.shortMean,
    this.meanings = const [],
    this.relatedWords = const [],
    this.oppositeWords = const [],
    this.synonyms = const [],
    this.mobileId,
  });

  /// Get first opposite word (for backwards compatibility)
  String? get oppositeWord => oppositeWords.isNotEmpty ? oppositeWords.first : null;

  /// Convert to generic DictionaryResult
  DictionaryResult toDictionaryResult() {
    return DictionaryResult(
      word: word,
      phonetic: phonetic,
      sourceLanguage: 'ja',
      meanings: meanings.map((m) {
        // Include all examples
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

  /// Get primary Vietnamese definition
  String? get primaryDefinition {
    if (meanings.isEmpty) return null;
    return meanings.first.meaning;
  }

  /// Get first example
  String? get firstExample {
    for (final m in meanings) {
      if (m.examples.isNotEmpty) {
        return m.examples.first.content;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'MaziiResult(word: $word, phonetic: $phonetic, meanings: ${meanings.length})';
  }
}

class MaziiMeaning {
  final String kind;
  final String meaning;
  final List<MaziiExample> examples;

  MaziiMeaning({
    required this.kind,
    required this.meaning,
    this.examples = const [],
  });
}

class MaziiExample {
  final String content;
  final String meaning;
  final String? transcription;

  MaziiExample({
    required this.content,
    required this.meaning,
    this.transcription,
  });
}
