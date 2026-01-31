import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../../models/dictionary_result.dart';

/// Decode response body as UTF-8
String _decodeUtf8(http.Response response) {
  // Try to decode as UTF-8 explicitly
  try {
    return utf8.decode(response.bodyBytes);
  } catch (e) {
    // Fallback to default body
    return response.body;
  }
}

/// Laban Dictionary API for English-Vietnamese translation
class LabanApi {
  final http.Client _client;

  LabanApi({http.Client? client}) : _client = client ?? http.Client();

  /// Look up a word and get Vietnamese translation
  Future<DictionaryResult?> lookup(String word) async {
    try {
      final url = ApiEndpoints.laban(word);
      debugPrint('[LabanApi] GET $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'VocabFlip/1.0',
        },
      );
      debugPrint('[LabanApi] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = _decodeUtf8(response);
        debugPrint('[LabanApi] Response body: $body');
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (data['error'] == 0) {
          debugPrint('[LabanApi] Found result for "$word"');
          return _parseResponse(word, data);
        }
      }
    } catch (e) {
      debugPrint('[LabanApi] Error: $e');
    }
    return null;
  }

  DictionaryResult? _parseResponse(String query, Map<String, dynamic> data) {
    final meanings = <DictionaryMeaning>[];
    String? phonetic;

    // Parse English-Vietnamese data (primary)
    final enViData = data['enViData'] as Map<String, dynamic>?;
    if (enViData != null) {
      final best = enViData['best'] as Map<String, dynamic>?;
      if (best != null) {
        final detailsHtml = best['details'] as String?;
        if (detailsHtml != null) {
          // Extract phonetic from HTML
          phonetic = _extractPhonetic(detailsHtml);

          // Parse definitions from HTML
          final parsed = _parseDetailsHtml(detailsHtml);
          meanings.addAll(parsed);
        }
      }
    }

    if (meanings.isEmpty) {
      return null;
    }

    return DictionaryResult(
      word: query,
      phonetic: phonetic,
      meanings: meanings,
      sourceLanguage: 'en',
    );
  }

  /// Extract phonetic from HTML like: <span class="color-black">/'æpl/</span>
  String? _extractPhonetic(String html) {
    // Match IPA in format /.../ or /'.../ etc
    final phoneticRegex = RegExp(r"/[^/]+/");
    final match = phoneticRegex.firstMatch(html);
    return match?.group(0);
  }

  /// Parse the details HTML to extract meanings
  /// HTML format:
  /// <div class="bg-grey bold font-large m-top20"><span>Danh từ</span></div>
  /// <div class="green margin25 m-top15">quả táo tây</div>
  /// <div class="color-light-blue margin25 m-top15">example sentence</div>
  List<DictionaryMeaning> _parseDetailsHtml(String html) {
    final meanings = <DictionaryMeaning>[];

    // Find all part-of-speech sections
    // Pattern: <div class="bg-grey..."><span>Danh từ</span></div>
    final posRegex = RegExp(
      r'<div[^>]*class="[^"]*bg-grey[^"]*"[^>]*>\s*<span>([^<]+)</span>\s*</div>',
      caseSensitive: false,
    );

    // Find Vietnamese definitions (green class)
    final defRegex = RegExp(
      r'<div[^>]*class="[^"]*green[^"]*"[^>]*>([^<]+)</div>',
      caseSensitive: false,
    );

    // Find examples (color-light-blue class)
    final exampleRegex = RegExp(
      r'<div[^>]*class="[^"]*color-light-blue[^"]*"[^>]*>([^<]+)</div>',
      caseSensitive: false,
    );

    // Split by part-of-speech sections
    final posSections = posRegex.allMatches(html).toList();

    if (posSections.isEmpty) {
      // No part-of-speech found, just extract all green definitions
      final defs = defRegex.allMatches(html).map((m) {
        final text = _cleanHtml(m.group(1) ?? '');
        return DictionaryDefinition(definition: text);
      }).where((d) => d.definition.isNotEmpty).toList();

      if (defs.isNotEmpty) {
        meanings.add(DictionaryMeaning(
          partOfSpeech: '',
          definitions: defs,
        ));
      }
    } else {
      // Parse each section
      for (var i = 0; i < posSections.length; i++) {
        final pos = _cleanHtml(posSections[i].group(1) ?? '');
        final startIndex = posSections[i].end;
        final endIndex = i + 1 < posSections.length
            ? posSections[i + 1].start
            : html.length;

        final section = html.substring(startIndex, endIndex);

        // Extract definitions from this section
        final defs = <DictionaryDefinition>[];
        final defMatches = defRegex.allMatches(section).toList();
        final exampleMatches = exampleRegex.allMatches(section).toList();

        for (var j = 0; j < defMatches.length; j++) {
          final defText = _cleanHtml(defMatches[j].group(1) ?? '');
          String? example;

          // Try to find an example near this definition
          if (j < exampleMatches.length) {
            example = _cleanHtml(exampleMatches[j].group(1) ?? '');
          }

          if (defText.isNotEmpty) {
            defs.add(DictionaryDefinition(
              definition: defText,
              example: example?.isNotEmpty == true ? example : null,
            ));
          }
        }

        if (defs.isNotEmpty) {
          meanings.add(DictionaryMeaning(
            partOfSpeech: pos,
            definitions: defs,
          ));
        }
      }
    }

    return meanings;
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void dispose() {
    _client.close();
  }
}
