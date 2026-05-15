import 'dart:math';

import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../auth/alpha_auth_session.dart';
import '../../models/category.dart';
import '../../models/public_deck.dart';
import '../../models/public_flashcard.dart';
import '../../models/public_profile.dart';
import 'vocab_api_helpers.dart';

/// Filter options for browsing public decks.
class LibraryFilter {
  final String? categoryId;
  final String? sourceLanguage;
  final String? targetLanguage;
  final List<String>? tags;
  final String? searchQuery;
  final LibrarySortBy sortBy;
  final bool descending;

  const LibraryFilter({
    this.categoryId,
    this.sourceLanguage,
    this.targetLanguage,
    this.tags,
    this.searchQuery,
    this.sortBy = LibrarySortBy.popular,
    this.descending = true,
  });

  LibraryFilter copyWith({
    String? categoryId,
    String? sourceLanguage,
    String? targetLanguage,
    List<String>? tags,
    String? searchQuery,
    LibrarySortBy? sortBy,
    bool? descending,
  }) {
    return LibraryFilter(
      categoryId: categoryId ?? this.categoryId,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
    );
  }
}

enum LibrarySortBy {
  popular,
  rating,
  newest,
  updated,
}

/// MongoDB-backed public library API client.
class MongoPublicLibraryService {
  final ApiClient _apiClient = ApiClient();
  final AlphaAuthSession _authSession = AlphaAuthSession();

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/vocab/categories');
      final docs = unwrapApiList(response.data);
      if (docs.isEmpty) return Category.predefined;
      return docs.map(Category.fromMap).toList();
    } catch (e) {
      logVocabApiError('getCategories', e);
      return Category.predefined;
    }
  }

  Future<List<PublicDeck>> browse({
    LibraryFilter? filter,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/vocab/public-decks',
        queryParameters: _filterParams(filter, limit),
      );
      return unwrapApiList(response.data).map(PublicDeck.fromMap).toList();
    } catch (e) {
      logVocabApiError('browse', e);
      return [];
    }
  }

  Future<List<PublicDeck>> search(String query, {int limit = 20}) {
    return browse(
      filter: LibraryFilter(searchQuery: query),
      limit: limit,
    );
  }

  Future<PublicDeck?> getDeck(String deckId) async {
    try {
      final response = await _apiClient.dio.get('/vocab/public-decks/$deckId');
      final doc = unwrapApiMap(response.data);
      return doc == null ? null : PublicDeck.fromMap(doc);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        logVocabApiError('getDeck', e);
      }
      return null;
    } catch (e) {
      logVocabApiError('getDeck', e);
      return null;
    }
  }

  Future<List<PublicFlashcard>> getFlashcards(String publicDeckId) async {
    try {
      final response = await _apiClient.dio.get(
        '/vocab/public-decks/$publicDeckId/flashcards',
      );
      final cards = unwrapApiList(response.data)
          .map(PublicFlashcard.fromMap)
          .toList();
      cards.sort((a, b) => a.order.compareTo(b.order));
      return cards;
    } catch (e) {
      logVocabApiError('getFlashcards', e);
      return [];
    }
  }

  Future<PublicDeck> publishDeck({
    required String localDeckId,
    required String name,
    String? description,
    required String sourceLanguage,
    required String targetLanguage,
    required String categoryId,
    required List<String> tags,
    required List<Map<String, dynamic>> flashcards,
    String? imageUrl,
    String? frontFields,
    String? backFields,
    String? authorName,
    String? imageDisplayMode,
    bool showBackFirst = false,
  }) async {
    final userId = _authSession.userId;
    if (userId == null) {
      throw Exception('User must be signed in to publish');
    }

    final deckId = _generateShortId();
    final response = await _apiClient.dio.post('/vocab/public-decks', data: {
      'id': deckId,
      'short_id': deckId,
      'original_local_id': localDeckId,
      'name': name,
      'description': description,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'category_id': categoryId,
      'tags': tags,
      'flashcards': flashcards,
      'image_url': imageUrl,
      'front_fields': frontFields,
      'back_fields': backFields,
      'author_name': authorName ?? _authSession.displayName ?? 'Anonymous',
      'image_display_mode': imageDisplayMode,
      'show_back_first': showBackFirst,
    });

    final doc = unwrapApiMap(response.data);
    if (doc != null) return PublicDeck.fromMap(doc);

    final now = DateTime.now();
    return PublicDeck(
      id: deckId,
      shortId: deckId,
      originalLocalId: localDeckId,
      authorId: userId,
      authorName: authorName ?? _authSession.displayName ?? 'Anonymous',
      name: name,
      description: description,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      categoryId: categoryId,
      tags: tags,
      cardCount: flashcards.length,
      version: 1,
      publishedAt: now,
      createdAt: now,
      updatedAt: now,
      imageUrl: imageUrl,
      frontFields: frontFields,
      backFields: backFields,
      imageDisplayMode: imageDisplayMode,
      showBackFirst: showBackFirst,
    );
  }

  Future<void> updatePublishedDeck({
    required String publicDeckId,
    String? name,
    String? description,
    String? categoryId,
    List<String>? tags,
    List<Map<String, dynamic>>? flashcards,
    String? changeDescription,
    String? imageUrl,
    String? frontFields,
    String? backFields,
    String? imageDisplayMode,
    bool? showBackFirst,
  }) async {
    await _apiClient.dio.patch('/vocab/public-decks/$publicDeckId', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (tags != null) 'tags': tags,
      if (flashcards != null) 'flashcards': flashcards,
      if (changeDescription != null) 'change_description': changeDescription,
      if (imageUrl != null) 'image_url': imageUrl,
      if (frontFields != null) 'front_fields': frontFields,
      if (backFields != null) 'back_fields': backFields,
      if (imageDisplayMode != null) 'image_display_mode': imageDisplayMode,
      if (showBackFirst != null) 'show_back_first': showBackFirst,
    });
  }

  Future<void> unpublishDeck(String publicDeckId) async {
    await _apiClient.dio.delete('/vocab/public-decks/$publicDeckId');
  }

  Future<void> incrementDownloadCount(String publicDeckId) async {
    try {
      await _apiClient.dio.post('/vocab/public-decks/$publicDeckId/download');
    } catch (e) {
      logVocabApiError('incrementDownloadCount', e);
    }
  }

  Future<List<PublicDeck>> getMyPublishedDecks() async {
    final userId = _authSession.userId;
    if (userId == null) return [];

    try {
      final response = await _apiClient.dio.get('/vocab/public-decks/mine');
      return unwrapApiList(response.data).map(PublicDeck.fromMap).toList();
    } catch (e) {
      logVocabApiError('getMyPublishedDecks', e);
      return [];
    }
  }

  Future<List<PublicDeck>> getFeaturedDecks({int limit = 10}) {
    return browse(
      filter: const LibraryFilter(sortBy: LibrarySortBy.popular),
      limit: limit,
    );
  }

  Future<List<PublicDeck>> getTopRatedDecks({int limit = 10}) {
    return browse(
      filter: const LibraryFilter(sortBy: LibrarySortBy.rating),
      limit: limit,
    );
  }

  Future<List<PublicDeck>> getNewestDecks({int limit = 10}) {
    return browse(
      filter: const LibraryFilter(sortBy: LibrarySortBy.newest),
      limit: limit,
    );
  }

  Future<PublicProfile?> getAuthorProfile(String authorId) async {
    try {
      final response = await _apiClient.dio.get('/vocab/profiles/$authorId');
      final doc = unwrapApiMap(response.data);
      return doc == null ? null : PublicProfile.fromMap(authorId, doc);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        logVocabApiError('getAuthorProfile', e);
      }
      return null;
    } catch (e) {
      logVocabApiError('getAuthorProfile', e);
      return null;
    }
  }

  Map<String, dynamic> _filterParams(LibraryFilter? filter, int limit) {
    final params = <String, dynamic>{
      'limit': limit,
      'sort_by': (filter?.sortBy ?? LibrarySortBy.popular).name,
      'descending': filter?.descending ?? true,
    };
    if (filter?.categoryId != null) {
      params['category_id'] = filter!.categoryId;
    }
    if (filter?.sourceLanguage != null) {
      params['source_language'] = filter!.sourceLanguage;
    }
    if (filter?.targetLanguage != null) {
      params['target_language'] = filter!.targetLanguage;
    }
    if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
      params['q'] = filter.searchQuery;
    }
    if (filter?.tags != null && filter!.tags!.isNotEmpty) {
      params['tags'] = filter.tags!.join(',');
    }
    return params;
  }

  String _generateShortId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
