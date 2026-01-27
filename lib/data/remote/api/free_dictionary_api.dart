import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../../models/dictionary_result.dart';

class FreeDictionaryApi {
  final http.Client _client;

  FreeDictionaryApi({http.Client? client}) : _client = client ?? http.Client();

  Future<DictionaryResult?> lookup(String word) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiEndpoints.freeDictionary(word)),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return _parseResponse(data.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // Log error or handle accordingly
    }
    return null;
  }

  DictionaryResult _parseResponse(Map<String, dynamic> json) {
    final word = json['word'] as String;

    // Get phonetic
    String? phonetic;
    String? audioUrl;

    final phonetics = json['phonetics'] as List<dynamic>? ?? [];
    for (final p in phonetics) {
      final map = p as Map<String, dynamic>;
      if (phonetic == null && map['text'] != null) {
        phonetic = map['text'] as String;
      }
      if (audioUrl == null && map['audio'] != null) {
        final audio = map['audio'] as String;
        if (audio.isNotEmpty) {
          audioUrl = audio;
        }
      }
    }

    // Parse meanings
    final meaningsJson = json['meanings'] as List<dynamic>? ?? [];
    final meanings = meaningsJson.map((m) {
      final map = m as Map<String, dynamic>;
      final partOfSpeech = map['partOfSpeech'] as String? ?? '';

      final definitionsJson = map['definitions'] as List<dynamic>? ?? [];
      final definitions = definitionsJson.map((d) {
        final defMap = d as Map<String, dynamic>;
        return DictionaryDefinition(
          definition: defMap['definition'] as String? ?? '',
          example: defMap['example'] as String?,
        );
      }).toList();

      final synonyms = (map['synonyms'] as List<dynamic>?)?.cast<String>() ?? [];
      final antonyms = (map['antonyms'] as List<dynamic>?)?.cast<String>() ?? [];

      return DictionaryMeaning(
        partOfSpeech: partOfSpeech,
        definitions: definitions,
        synonyms: synonyms,
        antonyms: antonyms,
      );
    }).toList();

    return DictionaryResult(
      word: word,
      phonetic: phonetic,
      audioUrl: audioUrl,
      meanings: meanings,
      sourceLanguage: 'en',
    );
  }

  void dispose() {
    _client.close();
  }
}
