import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';

class GoogleTranslateApi {
  final String? apiKey;
  final http.Client _client;

  GoogleTranslateApi({
    this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  Future<String?> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (!isConfigured) {
      return null;
    }

    try {
      final response = await _client.post(
        Uri.parse('${ApiEndpoints.googleTranslateBase}?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': sourceLanguage,
          'target': targetLanguage,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final translations = data['data']?['translations'] as List<dynamic>?;
        if (translations != null && translations.isNotEmpty) {
          return translations.first['translatedText'] as String?;
        }
      }
    } catch (e) {
      // Log error or handle accordingly
    }
    return null;
  }

  Future<List<String>> detectLanguage(String text) async {
    if (!isConfigured) {
      return [];
    }

    try {
      final response = await _client.post(
        Uri.parse('${ApiEndpoints.googleTranslateBase}/detect?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'q': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final detections = data['data']?['detections'] as List<dynamic>?;
        if (detections != null && detections.isNotEmpty) {
          final firstDetection = detections.first as List<dynamic>;
          return firstDetection
              .map((d) => (d as Map<String, dynamic>)['language'] as String)
              .toList();
        }
      }
    } catch (e) {
      // Log error or handle accordingly
    }
    return [];
  }

  void dispose() {
    _client.close();
  }
}
