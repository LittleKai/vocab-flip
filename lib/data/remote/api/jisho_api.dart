import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../../models/dictionary_result.dart';

class JishoApi {
  final http.Client _client;

  JishoApi({http.Client? client}) : _client = client ?? http.Client();

  Future<JishoResult?> lookup(String word) async {
    final results = await search(word);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<JishoResult>> search(String query) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiEndpoints.jisho(Uri.encodeComponent(query))),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['data'] as List<dynamic>? ?? [];
        return results.map((r) => _parseResult(r as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Log error or handle accordingly
    }
    return [];
  }

  JishoResult _parseResult(Map<String, dynamic> json) {
    // Get Japanese word and reading
    final japanese = json['japanese'] as List<dynamic>? ?? [];
    String word = '';
    String? reading;

    if (japanese.isNotEmpty) {
      final first = japanese.first as Map<String, dynamic>;
      word = first['word'] as String? ?? first['reading'] as String? ?? '';
      reading = first['reading'] as String?;
    }

    // Get JLPT levels
    final jlpt = (json['jlpt'] as List<dynamic>?)?.cast<String>() ?? [];

    // Check if common word
    final isCommon = json['is_common'] as bool? ?? false;

    // Parse senses (meanings)
    final senses = json['senses'] as List<dynamic>? ?? [];
    final meanings = senses.map((s) {
      final sense = s as Map<String, dynamic>;
      return JishoMeaning(
        partsOfSpeech: (sense['parts_of_speech'] as List<dynamic>?)?.cast<String>() ?? [],
        englishDefinitions: (sense['english_definitions'] as List<dynamic>?)?.cast<String>() ?? [],
        tags: (sense['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    }).toList();

    return JishoResult(
      word: word,
      reading: reading,
      meanings: meanings,
      jlptLevels: jlpt,
      isCommon: isCommon,
    );
  }

  void dispose() {
    _client.close();
  }
}
