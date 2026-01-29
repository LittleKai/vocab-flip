import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/deck_rating.dart';
import 'firebase_service.dart';
import 'firestore_rest_client.dart';

/// Service for managing deck ratings
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _authService = FirebaseService();
  final FirestoreRestClient _restClient = FirestoreRestClient();

  /// Check if we should use REST API (Windows)
  bool get _useRest => FirestoreRestClient.shouldUseRest;

  String _ratingsPath(String publicDeckId) =>
      '${AppConstants.collectionPublicDecks}/$publicDeckId/${AppConstants.collectionRatings}';

  CollectionReference<Map<String, dynamic>> _ratingsRef(String publicDeckId) =>
      _firestore
          .collection(AppConstants.collectionPublicDecks)
          .doc(publicDeckId)
          .collection(AppConstants.collectionRatings);

  DocumentReference<Map<String, dynamic>> _deckRef(String publicDeckId) =>
      _firestore.collection(AppConstants.collectionPublicDecks).doc(publicDeckId);

  /// Submit or update a rating for a deck
  Future<DeckRating> rateDeck({
    required String publicDeckId,
    required int rating,
    String? review,
  }) async {
    final userId = _authService.userId;
    final userName = _authService.userName;

    if (userId == null) {
      throw Exception('User must be signed in to rate');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    // Check if user already rated this deck
    final existingRating = await getUserRating(publicDeckId);

    if (_useRest) {
      return _rateDeckRest(
        publicDeckId: publicDeckId,
        userId: userId,
        userName: userName,
        rating: rating,
        review: review,
        existingRating: existingRating,
      );
    }

    final batch = _firestore.batch();

    if (existingRating != null) {
      // Update existing rating
      final ratingDiff = rating - existingRating.rating;

      // Update the rating document
      batch.update(_ratingsRef(publicDeckId).doc(userId), {
        'rating': rating,
        'review': review,
        'updated_at': Timestamp.now(),
      });

      // Update deck aggregate (adjust for rating change)
      batch.update(_deckRef(publicDeckId), {
        'rating_sum': FieldValue.increment(ratingDiff),
      });
    } else {
      // Create new rating
      final ratingDoc = DeckRating(
        id: userId,
        publicDeckId: publicDeckId,
        userId: userId,
        userName: userName,
        rating: rating,
        review: review,
      );

      batch.set(_ratingsRef(publicDeckId).doc(userId), ratingDoc.toFirestore());

      // Update deck aggregate
      batch.update(_deckRef(publicDeckId), {
        'rating_sum': FieldValue.increment(rating),
        'rating_count': FieldValue.increment(1),
      });
    }

    await batch.commit();

    return DeckRating(
      id: userId,
      publicDeckId: publicDeckId,
      userId: userId,
      userName: userName,
      rating: rating,
      review: review,
    );
  }

  Future<DeckRating> _rateDeckRest({
    required String publicDeckId,
    required String userId,
    required String? userName,
    required int rating,
    String? review,
    DeckRating? existingRating,
  }) async {
    final now = DateTime.now();

    if (existingRating != null) {
      // Update existing rating
      final ratingDiff = rating - existingRating.rating;

      await _restClient.updateDocument(
        _ratingsPath(publicDeckId),
        userId,
        {
          'rating': rating,
          'review': review,
          'updated_at': now,
        },
      );

      // Update deck aggregate
      final deckDoc = await _restClient.getDocument(AppConstants.collectionPublicDecks, publicDeckId);
      if (deckDoc != null) {
        final currentSum = deckDoc['rating_sum'] as int? ?? 0;
        await _restClient.updateDocument(AppConstants.collectionPublicDecks, publicDeckId, {
          'rating_sum': currentSum + ratingDiff,
        });
      }
    } else {
      // Create new rating
      await _restClient.setDocument(
        _ratingsPath(publicDeckId),
        userId,
        {
          'public_deck_id': publicDeckId,
          'user_id': userId,
          'user_name': userName,
          'rating': rating,
          'review': review,
          'created_at': now,
          'updated_at': now,
        },
      );

      // Update deck aggregate
      final deckDoc = await _restClient.getDocument(AppConstants.collectionPublicDecks, publicDeckId);
      if (deckDoc != null) {
        final currentSum = deckDoc['rating_sum'] as int? ?? 0;
        final currentCount = deckDoc['rating_count'] as int? ?? 0;
        await _restClient.updateDocument(AppConstants.collectionPublicDecks, publicDeckId, {
          'rating_sum': currentSum + rating,
          'rating_count': currentCount + 1,
        });
      }
    }

    return DeckRating(
      id: userId,
      publicDeckId: publicDeckId,
      userId: userId,
      userName: userName,
      rating: rating,
      review: review,
    );
  }

  /// Get the current user's rating for a deck
  Future<DeckRating?> getUserRating(String publicDeckId) async {
    final userId = _authService.userId;
    if (userId == null) return null;

    if (_useRest) {
      try {
        final doc = await _restClient.getDocument(_ratingsPath(publicDeckId), userId);
        if (doc == null) return null;
        return DeckRating.fromMap(doc);
      } catch (e) {
        debugPrint('getUserRating REST error: $e');
        return null;
      }
    }

    final doc = await _ratingsRef(publicDeckId).doc(userId).get();
    if (!doc.exists) return null;

    return DeckRating.fromFirestore(doc);
  }

  /// Get all ratings for a deck
  Future<List<DeckRating>> getDeckRatings(
    String publicDeckId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(
          _ratingsPath(publicDeckId),
          orderBy: [OrderBy('created_at', descending: true)],
          limit: limit,
        );
        return docs.map((doc) => DeckRating.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('getDeckRatings REST error: $e');
        return [];
      }
    }

    Query<Map<String, dynamic>> query = _ratingsRef(publicDeckId)
        .orderBy('created_at', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => DeckRating.fromFirestore(doc)).toList();
  }

  /// Delete user's rating for a deck
  Future<void> deleteRating(String publicDeckId) async {
    final userId = _authService.userId;
    if (userId == null) {
      throw Exception('User must be signed in');
    }

    final existingRating = await getUserRating(publicDeckId);
    if (existingRating == null) return;

    if (_useRest) {
      await _restClient.deleteDocument(_ratingsPath(publicDeckId), userId);

      // Update deck aggregate
      final deckDoc = await _restClient.getDocument(AppConstants.collectionPublicDecks, publicDeckId);
      if (deckDoc != null) {
        final currentSum = deckDoc['rating_sum'] as int? ?? 0;
        final currentCount = deckDoc['rating_count'] as int? ?? 0;
        await _restClient.updateDocument(AppConstants.collectionPublicDecks, publicDeckId, {
          'rating_sum': currentSum - existingRating.rating,
          'rating_count': currentCount - 1,
        });
      }
      return;
    }

    final batch = _firestore.batch();

    // Delete the rating document
    batch.delete(_ratingsRef(publicDeckId).doc(userId));

    // Update deck aggregate
    batch.update(_deckRef(publicDeckId), {
      'rating_sum': FieldValue.increment(-existingRating.rating),
      'rating_count': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Get rating statistics for a deck
  Future<Map<int, int>> getRatingDistribution(String publicDeckId) async {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(_ratingsPath(publicDeckId));
        for (final doc in docs) {
          final rating = doc['rating'] as int;
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
        return distribution;
      } catch (e) {
        debugPrint('getRatingDistribution REST error: $e');
        return distribution;
      }
    }

    final snapshot = await _ratingsRef(publicDeckId).get();

    for (final doc in snapshot.docs) {
      final rating = doc.data()['rating'] as int;
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return distribution;
  }
}
