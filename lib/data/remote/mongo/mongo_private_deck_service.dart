import 'package:flutter/foundation.dart';
import '../../api/api_client.dart';
import '../../models/deck.dart';
import 'vocab_api_helpers.dart';

class MongoPrivateDeckService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Deck>> getAllDecks() async {
    try {
      debugPrint('MongoPrivateDeckService.getAllDecks: calling GET /vocab/my-decks');
      final response = await _apiClient.dio.get('/vocab/my-decks');
      debugPrint('MongoPrivateDeckService.getAllDecks: response status=${response.statusCode}');
      debugPrint('MongoPrivateDeckService.getAllDecks: response data=${response.data}');
      final docs = unwrapApiList(response.data);
      debugPrint('MongoPrivateDeckService.getAllDecks: unwrapped ${docs.length} docs');
      return docs.map((doc) => Deck.fromMap(
        doc,
        cardCount: doc['card_count'] as int? ?? 0,
        newCount: doc['new_count'] as int? ?? 0,
        learningCount: doc['learning_count'] as int? ?? 0,
        reviewCount: doc['review_count'] as int? ?? 0,
      )).toList();
    } catch (e) {
      debugPrint('MongoPrivateDeckService.getAllDecks: ERROR $e');
      logVocabApiError('getAllDecks', e);
      rethrow;
    }
  }

  Future<Deck?> getDeckById(String deckId) async {
    try {
      final response = await _apiClient.dio.get('/vocab/my-decks/$deckId');
      final doc = unwrapApiMap(response.data);
      if (doc == null) return null;
      return Deck.fromMap(
        doc,
        cardCount: doc['card_count'] as int? ?? 0,
        newCount: doc['new_count'] as int? ?? 0,
        learningCount: doc['learning_count'] as int? ?? 0,
        reviewCount: doc['review_count'] as int? ?? 0,
      );
    } catch (e) {
      logVocabApiError('getDeckById', e);
      return null;
    }
  }

  Future<Deck?> createDeck(Deck deck) async {
    try {
      final data = deck.toMap();
      debugPrint('MongoPrivateDeckService.createDeck: POST /vocab/my-decks');
      debugPrint('MongoPrivateDeckService.createDeck: request data=$data');
      final response = await _apiClient.dio.post(
        '/vocab/my-decks',
        data: data,
      );
      debugPrint('MongoPrivateDeckService.createDeck: response status=${response.statusCode}');
      debugPrint('MongoPrivateDeckService.createDeck: response data=${response.data}');
      final doc = unwrapApiMap(response.data);
      if (doc == null) {
        debugPrint('MongoPrivateDeckService.createDeck: unwrapApiMap returned null');
        return null;
      }
      return Deck.fromMap(
        doc,
        cardCount: doc['card_count'] as int? ?? 0,
        newCount: doc['new_count'] as int? ?? 0,
        learningCount: doc['learning_count'] as int? ?? 0,
        reviewCount: doc['review_count'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('MongoPrivateDeckService.createDeck: ERROR $e');
      logVocabApiError('createDeck', e);
      rethrow;
    }
  }

  Future<Deck?> updateDeck(Deck deck) async {
    try {
      final response = await _apiClient.dio.put(
        '/vocab/my-decks/${deck.id}',
        data: deck.toMap(),
      );
      final doc = unwrapApiMap(response.data);
      if (doc == null) return null;
      return Deck.fromMap(
        doc,
        cardCount: doc['card_count'] as int? ?? 0,
        newCount: doc['new_count'] as int? ?? 0,
        learningCount: doc['learning_count'] as int? ?? 0,
        reviewCount: doc['review_count'] as int? ?? 0,
      );
    } catch (e) {
      logVocabApiError('updateDeck', e);
      rethrow;
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      await _apiClient.dio.delete('/vocab/my-decks/$deckId');
    } catch (e) {
      logVocabApiError('deleteDeck', e);
      rethrow;
    }
  }
}
