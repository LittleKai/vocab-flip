import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../api/api_client.dart';
import '../../auth/alpha_auth_session.dart';
import '../../models/deck_rating.dart';
import 'vocab_api_helpers.dart';

class MongoRatingService {
  final ApiClient _apiClient = ApiClient();
  final AlphaAuthSession _authSession = AlphaAuthSession();

  Future<DeckRating> rateDeck({
    required String publicDeckId,
    required int rating,
    String? review,
    String? nickname,
  }) async {
    final userId = _authSession.userId;
    if (userId == null) {
      throw Exception('User must be signed in to rate decks');
    }

    final response = await _apiClient.dio.put(
      '/vocab/public-decks/$publicDeckId/rating',
      data: {
        'rating': rating,
        'review': review,
        'user_name': nickname ?? _authSession.displayName,
      },
    );

    final doc = unwrapApiMap(response.data);
    if (doc != null) return DeckRating.fromMap(doc);

    return DeckRating(
      id: const Uuid().v4(),
      publicDeckId: publicDeckId,
      userId: userId,
      userName: nickname ?? _authSession.displayName,
      rating: rating,
      review: review,
    );
  }

  Future<DeckRating?> getUserRating(String publicDeckId) async {
    final userId = _authSession.userId;
    if (userId == null) return null;

    try {
      final response = await _apiClient.dio.get(
        '/vocab/public-decks/$publicDeckId/rating/me',
      );
      final doc = unwrapApiMap(response.data);
      return doc == null ? null : DeckRating.fromMap(doc);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && e.response?.statusCode != 401) {
        logVocabApiError('getUserRating', e);
      }
      return null;
    }
  }

  Future<List<DeckRating>> getDeckRatings(
    String publicDeckId, {
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/vocab/public-decks/$publicDeckId/ratings',
        queryParameters: {'limit': limit},
      );
      return unwrapApiList(response.data).map(DeckRating.fromMap).toList();
    } catch (e) {
      logVocabApiError('getDeckRatings', e);
      return [];
    }
  }

  Future<void> deleteRating(String publicDeckId) async {
    await _apiClient.dio.delete('/vocab/public-decks/$publicDeckId/rating');
  }
}
