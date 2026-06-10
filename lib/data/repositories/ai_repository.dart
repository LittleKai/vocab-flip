import '../api/api_client.dart';
import '../models/flashcard.dart';

class AiRepository {
  final ApiClient _apiClient;

  AiRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<String> generateMnemonic(String word, String language) async {
    try {
      final response = await _apiClient.dio.post('/ai/mnemonic', data: {
        'word': word,
        'meaning': '',
      });
      final data = response.data;
      return '${data['mnemonic']}\n\nExplanation: ${data['explanation']}';
    } catch (e) {
      throw Exception('Failed to generate mnemonic: $e');
    }
  }

  Future<List<Flashcard>> generateDeck(String text, String language, String targetLanguage) async {
    try {
      final response = await _apiClient.dio.post('/ai/generate-deck', data: {
        'text': text,
        'language': language,
        'targetLanguage': targetLanguage,
      });
      final List<dynamic> cardsData = response.data['cards'] ?? [];
      return cardsData.map((json) => Flashcard(
        deckId: 'draft',
        front: json['front'] ?? '',
        back: json['back'] ?? '',
        frontPhonetic: json['phonetic'] ?? '',
      )).toList();
    } catch (e) {
      throw Exception('Failed to generate deck: $e');
    }
  }
}
