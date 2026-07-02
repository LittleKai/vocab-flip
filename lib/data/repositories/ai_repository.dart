import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/flashcard.dart';

class AiRepository {
  final ApiClient _apiClient;

  AiRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<String> generateMnemonic(String word, String language) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/mnemonic',
        data: {
          'word': word,
          'meaning': '',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      final data = response.data;
      return '${data['mnemonic']}\n\nExplanation: ${data['explanation']}';
    } catch (e) {
      throw Exception('Failed to generate mnemonic: $e');
    }
  }

  /// Generate flashcards via AI.
  ///
  /// [prompt] - description of topic/requirements
  /// [sourceLanguage] / [targetLanguage] - language pair
  /// [count] - desired number of cards (max 100)
  /// [includeExamples] / [includeNotes] - optional fields
  /// [noteInstructions] - optional instructions for what kind of notes to generate
  /// [model] - backend AI model id, e.g. 'gemini-3-flash'
  ///
  /// Returns a map with keys:
  ///   'cards' - List<Flashcard>
  ///   'freeUsesRemaining' - int, daily free Gemini 3 Flash uses
  ///   'creditBalance' - int
  Future<Map<String, dynamic>> generateCards({
    required String prompt,
    required String sourceLanguage,
    required String targetLanguage,
    required int count,
    bool includeExamples = true,
    bool includeNotes = false,
    String? noteInstructions,
    String model = 'gemini-3-flash',
  }) async {
    try {
      final timeoutSeconds = ((count * 3) + 30).clamp(90, 300);
      final response = await _apiClient.dio.post(
        '/ai/generate-cards',
        data: {
          'prompt': prompt,
          'sourceLanguage': sourceLanguage,
          'targetLanguage': targetLanguage,
          'count': count,
          'includeExamples': includeExamples,
          'includeNotes': includeNotes,
          if (includeNotes &&
              noteInstructions != null &&
              noteInstructions.isNotEmpty)
            'noteInstructions': noteInstructions,
          'model': model,
        },
        options: Options(
          receiveTimeout: Duration(seconds: timeoutSeconds),
        ),
      );

      final data = response.data;
      final List<dynamic> cardsData = data['cards'] ?? [];
      final cards = cardsData
          .map((json) => Flashcard(
                deckId: 'draft',
                front: json['word'] ?? json['front'] ?? '',
                frontPhonetic: json['phonetic'] ?? json['front_phonetic'] ?? '',
                back: json['meaning'] ?? json['back'] ?? '',
                example: json['example'] ?? json['examples']?.toString(),
                notes: json['note'] ?? json['notes'],
              ))
          .toList();

      return {
        'cards': cards,
        'freeUsesRemaining': data['freeUsesRemaining'] ?? 0,
        'creditBalance': data['creditBalance'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to generate cards: $e');
    }
  }

  /// Check how many free AI uses remain and credit balance.
  Future<Map<String, dynamic>> getAiUsageInfo() async {
    try {
      final response = await _apiClient.dio.get('/ai/usage');
      return {
        'freeUsesRemaining': response.data['freeUsesRemaining'] ?? 0,
        'creditBalance': response.data['creditBalance'] ?? 0,
      };
    } catch (e) {
      // Default: assume one daily Gemini 3 Flash free use if endpoint is unavailable.
      return {
        'freeUsesRemaining': 1,
        'creditBalance': 0,
      };
    }
  }
}
