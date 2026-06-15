import 'package:dio/dio.dart';
import '../../api/api_client.dart';
import '../../models/flashcard.dart';
import 'vocab_api_helpers.dart';

class MongoPrivateFlashcardService {
  final Dio _dio;

  MongoPrivateFlashcardService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<Flashcard>> getFlashcards(String deckId) async {
    try {
      final response = await _dio.get('/vocab/my-decks/$deckId/cards');
      final docs = unwrapApiList(response.data);
      return docs.map(Flashcard.fromMap).toList();
    } catch (e) {
      logVocabApiError('getFlashcards', e);
      return [];
    }
  }

  Future<Flashcard?> getFlashcardById(String cardId) async {
    try {
      final response = await _dio.get('/vocab/my-decks/cards/$cardId');
      final doc = unwrapApiMap(response.data);
      if (doc == null) return null;
      return Flashcard.fromMap(doc);
    } catch (e) {
      logVocabApiError('getFlashcardById', e);
      return null;
    }
  }

  Future<List<Flashcard>> getDueFlashcards(String deckId) async {
    try {
      final response = await _dio.get('/vocab/my-decks/$deckId/due-cards');
      final docs = unwrapApiList(response.data);
      return docs.map(Flashcard.fromMap).toList();
    } catch (e) {
      logVocabApiError('getDueFlashcards', e);
      return [];
    }
  }

  Future<List<Flashcard>> getNewFlashcards(String deckId) async {
    try {
      final response = await _dio.get('/vocab/my-decks/$deckId/new-cards');
      final docs = unwrapApiList(response.data);
      return docs.map(Flashcard.fromMap).toList();
    } catch (e) {
      logVocabApiError('getNewFlashcards', e);
      return [];
    }
  }

  Future<int> getFlashcardsCount(String deckId) async {
    try {
      final response = await _dio.get('/vocab/my-decks/$deckId/cards/count');
      final data = unwrapApiMap(response.data);
      return data?['count'] as int? ?? 0;
    } catch (e) {
      logVocabApiError('getFlashcardsCount', e);
      return 0;
    }
  }

  Future<Flashcard?> createFlashcard(Flashcard card) async {
    try {
      final response = await _dio.post(
        '/vocab/my-decks/${card.deckId}/cards',
        data: card.toMap(),
      );
      final doc = unwrapApiMap(response.data);
      if (doc == null) return null;
      return Flashcard.fromMap(doc);
    } catch (e) {
      logVocabApiError('createFlashcard', e);
      rethrow;
    }
  }

  Future<List<Flashcard>> syncFlashcardsBatch(
      String deckId, List<Flashcard> cards) async {
    try {
      final data = cards.map((c) => c.toMap()).toList();
      final response = await _dio.post(
        '/vocab/my-decks/$deckId/cards/batch',
        data: data,
      );
      final docs = unwrapApiList(response.data);
      return docs.map(Flashcard.fromMap).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final created = <Flashcard>[];
        for (final card in cards) {
          final result = await createFlashcard(card);
          if (result != null) created.add(result);
        }
        return created;
      }
      logVocabApiError('syncFlashcardsBatch', e);
      rethrow;
    } catch (e) {
      logVocabApiError('syncFlashcardsBatch', e);
      rethrow;
    }
  }

  Future<Flashcard?> updateFlashcard(Flashcard card) async {
    try {
      final response = await _dio.put(
        '/vocab/my-decks/${card.deckId}/cards/${card.id}',
        data: card.toMap(),
      );
      final doc = unwrapApiMap(response.data);
      if (doc == null) return null;
      return Flashcard.fromMap(doc);
    } catch (e) {
      logVocabApiError('updateFlashcard', e);
      rethrow;
    }
  }

  Future<void> deleteFlashcard(String deckId, String cardId) async {
    try {
      await _dio.delete('/vocab/my-decks/$deckId/cards/$cardId');
    } catch (e) {
      logVocabApiError('deleteFlashcard', e);
      rethrow;
    }
  }

  Future<List<Flashcard>> searchFlashcards(String query,
      {int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/vocab/my-decks/cards/search',
        queryParameters: {'q': query, 'limit': limit},
      );
      final docs = unwrapApiList(response.data);
      return docs.map(Flashcard.fromMap).toList();
    } catch (e) {
      logVocabApiError('searchFlashcards', e);
      return [];
    }
  }
}
