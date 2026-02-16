import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../../../core/constants/app_constants.dart';
import '../../models/public_deck.dart';
import '../../models/public_flashcard.dart';
import '../../models/category.dart';
import 'firebase_service.dart';
import 'firestore_rest_client.dart';

/// Filter options for browsing public decks
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
  popular,    // by download count
  rating,     // by average rating
  newest,     // by published date
  updated,    // by last update
}

/// Service for interacting with public library on Firestore
class PublicLibraryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _authService = FirebaseService();
  final FirestoreRestClient _restClient = FirestoreRestClient();

  /// Check if we should use REST API (Windows)
  bool get _useRest => FirestoreRestClient.shouldUseRest;

  /// Generate a unique 4-character alphanumeric ID
  String _generateShortId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Generate a unique short ID, checking for collisions
  Future<String> _generateUniqueShortId() async {
    for (int attempt = 0; attempt < 10; attempt++) {
      final id = _generateShortId();
      final existing = await getDeck(id);
      if (existing == null) return id;
    }
    // Fallback: unlikely to reach here
    return _generateShortId();
  }

  CollectionReference<Map<String, dynamic>> get _publicDecksRef =>
      _firestore.collection(AppConstants.collectionPublicDecks);

  /// Get all categories (returns predefined + any custom from Firestore)
  Future<List<Category>> getCategories() async {
    // Return predefined categories (could extend with Firestore custom categories)
    return Category.predefined;
  }

  /// Browse public decks with filters and pagination
  Future<List<PublicDeck>> browse({
    LibraryFilter? filter,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (_useRest) {
      return _browseRest(filter: filter, limit: limit);
    }
    return _browseNative(filter: filter, limit: limit, startAfter: startAfter);
  }

  Future<List<PublicDeck>> _browseNative({
    LibraryFilter? filter,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _publicDecksRef;

      if (filter?.categoryId != null) {
        query = query.where('category_id', isEqualTo: filter!.categoryId);
      }
      if (filter?.sourceLanguage != null) {
        query = query.where('source_language', isEqualTo: filter!.sourceLanguage);
      }
      if (filter?.targetLanguage != null) {
        query = query.where('target_language', isEqualTo: filter!.targetLanguage);
      }

      // Sort
      final sortField = _getSortField(filter?.sortBy ?? LibrarySortBy.popular);
      query = query.orderBy(sortField, descending: filter?.descending ?? true);

      query = query.limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('browse error: $e');
      return [];
    }
  }

  Future<List<PublicDeck>> _browseRest({
    LibraryFilter? filter,
    int limit = 20,
  }) async {
    try {
      final filters = <QueryFilter>[];

      if (filter?.categoryId != null) {
        filters.add(QueryFilter.isEqualTo('category_id', filter!.categoryId));
      }
      if (filter?.sourceLanguage != null) {
        filters.add(QueryFilter.isEqualTo('source_language', filter!.sourceLanguage));
      }
      if (filter?.targetLanguage != null) {
        filters.add(QueryFilter.isEqualTo('target_language', filter!.targetLanguage));
      }

      final sortField = _getSortField(filter?.sortBy ?? LibrarySortBy.popular);
      final orderBy = [OrderBy(sortField, descending: filter?.descending ?? true)];

      final docs = await _restClient.getCollection(
        AppConstants.collectionPublicDecks,
        where: filters,
        orderBy: orderBy,
        limit: limit,
      );

      return docs.map((doc) => PublicDeck.fromMap(doc)).toList();
    } catch (e) {
      debugPrint('browse REST error: $e');
      return [];
    }
  }

  String _getSortField(LibrarySortBy sortBy) {
    switch (sortBy) {
      case LibrarySortBy.popular:
        return 'download_count';
      case LibrarySortBy.rating:
        return 'rating_sum';
      case LibrarySortBy.newest:
        return 'published_at';
      case LibrarySortBy.updated:
        return 'updated_at';
    }
  }

  /// Search public decks by keyword
  Future<List<PublicDeck>> search(String query, {int limit = 20}) async {
    debugPrint('[LibraryService] search("$query") _useRest=$_useRest');
    if (_useRest) {
      return _searchRest(query, limit: limit);
    }
    return _searchNative(query, limit: limit);
  }

  Future<List<PublicDeck>> _searchNative(String query, {int limit = 20}) async {
    debugPrint('[LibraryService] _searchNative("$query") starting...');
    try {
      // Firestore prefix search is case-sensitive and name-only
      // Fetch all and filter client-side for consistent behavior with REST
      debugPrint('[LibraryService] _searchNative: fetching all decks for client-side filtering...');
      final snapshot = await _publicDecksRef
          .limit(100)
          .get();

      debugPrint('[LibraryService] _searchNative: got ${snapshot.docs.length} docs from Firestore');

      final lowerQuery = query.toLowerCase();
      final allDecks = snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
      debugPrint('[LibraryService] _searchNative: parsed ${allDecks.length} decks');

      final filtered = allDecks
          .where((deck) =>
              deck.name.toLowerCase().contains(lowerQuery) ||
              (deck.description?.toLowerCase().contains(lowerQuery) ?? false) ||
              deck.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .take(limit)
          .toList();

      debugPrint('[LibraryService] _searchNative: filtered to ${filtered.length} results for "$query"');
      if (filtered.isNotEmpty) {
        debugPrint('[LibraryService] _searchNative: first match="${filtered.first.name}"');
      }

      return filtered;
    } catch (e, stackTrace) {
      debugPrint('[LibraryService] _searchNative ERROR: $e');
      debugPrint('[LibraryService] _searchNative stack: $stackTrace');
      return [];
    }
  }

  Future<List<PublicDeck>> _searchRest(String query, {int limit = 20}) async {
    try {
      // REST API doesn't support startAt/endAt easily, get all and filter client-side
      final docs = await _restClient.getCollection(
        AppConstants.collectionPublicDecks,
        limit: 100,
      );

      final lowerQuery = query.toLowerCase();
      final filtered = docs
          .map((doc) => PublicDeck.fromMap(doc))
          .where((deck) =>
              deck.name.toLowerCase().contains(lowerQuery) ||
              (deck.description?.toLowerCase().contains(lowerQuery) ?? false) ||
              deck.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .take(limit)
          .toList();

      return filtered;
    } catch (e) {
      debugPrint('search REST error: $e');
      return [];
    }
  }

  /// Get a single public deck by ID
  Future<PublicDeck?> getDeck(String deckId) async {
    if (_useRest) {
      return _getDeckRest(deckId);
    }
    return _getDeckNative(deckId);
  }

  Future<PublicDeck?> _getDeckNative(String deckId) async {
    try {
      final doc = await _publicDecksRef.doc(deckId).get();
      if (!doc.exists) return null;
      return PublicDeck.fromFirestore(doc);
    } catch (e) {
      debugPrint('getDeck error: $e');
      return null;
    }
  }

  Future<PublicDeck?> _getDeckRest(String deckId) async {
    try {
      final doc = await _restClient.getDocument(AppConstants.collectionPublicDecks, deckId);
      if (doc == null) return null;
      return PublicDeck.fromMap(doc);
    } catch (e) {
      debugPrint('getDeck REST error: $e');
      return null;
    }
  }

  /// Get flashcards for a public deck
  Future<List<PublicFlashcard>> getFlashcards(String publicDeckId) async {
    if (_useRest) {
      return _getFlashcardsRest(publicDeckId);
    }
    return _getFlashcardsNative(publicDeckId);
  }

  Future<List<PublicFlashcard>> _getFlashcardsNative(String publicDeckId) async {
    try {
      final snapshot = await _publicDecksRef
          .doc(publicDeckId)
          .collection(AppConstants.collectionPublicFlashcards)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) => PublicFlashcard.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('getFlashcards error: $e');
      return [];
    }
  }

  Future<List<PublicFlashcard>> _getFlashcardsRest(String publicDeckId) async {
    try {
      final collectionPath = '${AppConstants.collectionPublicDecks}/$publicDeckId/${AppConstants.collectionPublicFlashcards}';
      // Use simple list (no orderBy) to avoid structuredQuery, sort client-side
      final docs = await _restClient.getCollection(collectionPath);



      final flashcards = docs.map((doc) => PublicFlashcard.fromMap(doc)).toList();
      // Sort by order field client-side
      flashcards.sort((a, b) => a.order.compareTo(b.order));
      return flashcards;
    } catch (e) {
      debugPrint('getFlashcards REST error: $e');
      return [];
    }
  }

  /// Publish a local deck to the public library
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
    if (_useRest) {
      return _publishDeckRest(
        localDeckId: localDeckId,
        name: name,
        description: description,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        categoryId: categoryId,
        tags: tags,
        flashcards: flashcards,
        imageUrl: imageUrl,
        frontFields: frontFields,
        backFields: backFields,
        authorName: authorName,
        imageDisplayMode: imageDisplayMode,
        showBackFirst: showBackFirst,
      );
    }
    return _publishDeckNative(
      localDeckId: localDeckId,
      name: name,
      description: description,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      categoryId: categoryId,
      tags: tags,
      flashcards: flashcards,
      imageUrl: imageUrl,
      frontFields: frontFields,
      backFields: backFields,
      authorName: authorName,
      imageDisplayMode: imageDisplayMode,
      showBackFirst: showBackFirst,
    );
  }

  Future<PublicDeck> _publishDeckNative({
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
    final userId = _authService.userId;
    final userName = authorName ?? _authService.userName ?? 'Anonymous';

    if (userId == null) {
      throw Exception('User must be signed in to publish');
    }

    // Create the public deck document with short 4-char ID
    final shortId = await _generateUniqueShortId();
    final docRef = _publicDecksRef.doc(shortId);
    final publicDeck = PublicDeck(
      id: shortId,
      shortId: shortId,
      originalLocalId: localDeckId,
      authorId: userId,
      authorName: userName,
      name: name,
      description: description,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      categoryId: categoryId,
      tags: tags,
      cardCount: flashcards.length,
      version: 1,
      publishedAt: DateTime.now(),
      imageUrl: imageUrl,
      frontFields: frontFields,
      backFields: backFields,
      imageDisplayMode: imageDisplayMode,
      showBackFirst: showBackFirst,
    );

    // Use batch write for atomicity
    final batch = _firestore.batch();

    // Create deck document
    batch.set(docRef, publicDeck.toFirestore());

    // Create flashcard subcollection documents
    final flashcardsRef = docRef.collection(AppConstants.collectionPublicFlashcards);
    for (int i = 0; i < flashcards.length; i++) {
      final cardData = flashcards[i];
      final cardDocRef = flashcardsRef.doc();
      batch.set(cardDocRef, {
        'public_deck_id': docRef.id,
        'front': cardData['front'],
        'front_phonetic': cardData['front_phonetic'],
        'back': cardData['back'],
        'example': cardData['example'],
        'notes': cardData['notes'],
        'tags': cardData['tags'] ?? [],
        'front_image_url': cardData['front_image_url'],
        'back_image_url': cardData['back_image_url'],
        'share_image': cardData['share_image'] ?? true,
        'order': i,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
    }

    await batch.commit();
    return publicDeck;
  }

  Future<PublicDeck> _publishDeckRest({
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
    final userId = _authService.userId;
    final userName = authorName ?? _authService.userName ?? 'Anonymous';

    if (userId == null) {
      throw Exception('User must be signed in to publish');
    }

    final now = DateTime.now();

    // Generate short 4-char ID
    final deckId = await _generateUniqueShortId();

    final deckData = {
      'original_local_id': localDeckId,
      'author_id': userId,
      'author_name': userName,
      'name': name,
      'description': description,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'category_id': categoryId,
      'tags': tags,
      'card_count': flashcards.length,
      'download_count': 0,
      'rating_sum': 0,
      'rating_count': 0,
      'version': 1,
      'created_at': now,
      'updated_at': now,
      'published_at': now,
      'short_id': deckId,
      'image_url': imageUrl,
      'front_fields': frontFields,
      'back_fields': backFields,
      'image_display_mode': imageDisplayMode,
      'show_back_first': showBackFirst,
    };

    // Create deck document with custom ID
    final deckDoc = await _restClient.createDocument(
      AppConstants.collectionPublicDecks,
      deckData,
      documentId: deckId,
    );

    if (deckDoc == null) {
      throw Exception('Failed to create deck');
    }

    // Create flashcards using batch
    final batchOps = <BatchOperation>[];
    for (int i = 0; i < flashcards.length; i++) {
      final cardData = flashcards[i];
      final cardId = '${deckId}_card_$i';
      batchOps.add(BatchOperation.set(
        '${AppConstants.collectionPublicDecks}/$deckId/${AppConstants.collectionPublicFlashcards}',
        cardId,
        {
          'public_deck_id': deckId,
          'front': cardData['front'],
          'front_phonetic': cardData['front_phonetic'],
          'back': cardData['back'],
          'example': cardData['example'],
          'notes': cardData['notes'],
          'tags': cardData['tags'] ?? [],
          'front_image_url': cardData['front_image_url'],
          'back_image_url': cardData['back_image_url'],
          'share_image': cardData['share_image'] ?? true,
          'order': i,
          'created_at': now,
          'updated_at': now,
        },
      ));
    }

    // Batch write in chunks of 500 (Firestore REST API limit)
    for (int i = 0; i < batchOps.length; i += 500) {
      final chunk = batchOps.sublist(i, (i + 500).clamp(0, batchOps.length));
      final success = await _restClient.batchWrite(chunk);
      if (!success) {
        // Clean up: delete the deck document since flashcards failed
        await _restClient.deleteDocument(AppConstants.collectionPublicDecks, deckId);
        throw Exception('Failed to write flashcards to Firestore (batch ${i ~/ 500 + 1})');
      }
    }

    return PublicDeck(
      id: deckId,
      shortId: deckId,
      originalLocalId: localDeckId,
      authorId: userId,
      authorName: userName,
      name: name,
      description: description,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      categoryId: categoryId,
      tags: tags,
      cardCount: flashcards.length,
      version: 1,
      publishedAt: now,
      imageUrl: imageUrl,
      frontFields: frontFields,
      backFields: backFields,
      imageDisplayMode: imageDisplayMode,
    );
  }

  /// Update a published deck (author only)
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
    if (_useRest) {
      return _updatePublishedDeckRest(
        publicDeckId: publicDeckId,
        name: name,
        description: description,
        categoryId: categoryId,
        tags: tags,
        flashcards: flashcards,
        imageUrl: imageUrl,
        frontFields: frontFields,
        backFields: backFields,
        imageDisplayMode: imageDisplayMode,
        showBackFirst: showBackFirst,
      );
    }
    return _updatePublishedDeckNative(
      publicDeckId: publicDeckId,
      name: name,
      description: description,
      categoryId: categoryId,
      tags: tags,
      flashcards: flashcards,
      imageUrl: imageUrl,
      frontFields: frontFields,
      backFields: backFields,
      imageDisplayMode: imageDisplayMode,
      showBackFirst: showBackFirst,
    );
  }

  Future<void> _updatePublishedDeckNative({
    required String publicDeckId,
    String? name,
    String? description,
    String? categoryId,
    List<String>? tags,
    List<Map<String, dynamic>>? flashcards,
    String? imageUrl,
    String? frontFields,
    String? backFields,
    String? imageDisplayMode,
    bool? showBackFirst,
  }) async {
    final userId = _authService.userId;
    if (userId == null) {
      throw Exception('User must be signed in');
    }

    final deckDoc = await _publicDecksRef.doc(publicDeckId).get();
    if (!deckDoc.exists) {
      throw Exception('Deck not found');
    }

    final deck = PublicDeck.fromFirestore(deckDoc);
    if (deck.authorId != userId) {
      throw Exception('Only the author can update this deck');
    }

    final batch = _firestore.batch();

    // Update deck metadata
    final updates = <String, dynamic>{
      'version': deck.version + 1,
      'updated_at': Timestamp.now(),
    };

    // Generate short_id for old decks that don't have one
    if (deck.shortId == null) {
      final newShortId = await _generateUniqueShortId();
      updates['short_id'] = newShortId;
    }

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (tags != null) updates['tags'] = tags;
    if (flashcards != null) updates['card_count'] = flashcards.length;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (frontFields != null) updates['front_fields'] = frontFields;
    if (backFields != null) updates['back_fields'] = backFields;
    if (imageDisplayMode != null) updates['image_display_mode'] = imageDisplayMode;
    if (showBackFirst != null) updates['show_back_first'] = showBackFirst;

    batch.update(_publicDecksRef.doc(publicDeckId), updates);

    // If flashcards are provided, replace all cards
    if (flashcards != null) {
      // Delete existing flashcards
      final existingCards = await _publicDecksRef
          .doc(publicDeckId)
          .collection(AppConstants.collectionPublicFlashcards)
          .get();

      for (final doc in existingCards.docs) {
        batch.delete(doc.reference);
      }

      // Add new flashcards
      final flashcardsRef = _publicDecksRef
          .doc(publicDeckId)
          .collection(AppConstants.collectionPublicFlashcards);

      for (int i = 0; i < flashcards.length; i++) {
        final cardData = flashcards[i];
        final cardDocRef = flashcardsRef.doc();
        batch.set(cardDocRef, {
          'public_deck_id': publicDeckId,
          'front': cardData['front'],
          'front_phonetic': cardData['front_phonetic'],
          'back': cardData['back'],
          'example': cardData['example'],
          'notes': cardData['notes'],
          'tags': cardData['tags'] ?? [],
          'front_image_url': cardData['front_image_url'],
          'back_image_url': cardData['back_image_url'],
          'share_image': cardData['share_image'] ?? true,
          'order': i,
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });
      }
    }

    await batch.commit();
  }

  Future<void> _updatePublishedDeckRest({
    required String publicDeckId,
    String? name,
    String? description,
    String? categoryId,
    List<String>? tags,
    List<Map<String, dynamic>>? flashcards,
    String? imageUrl,
    String? frontFields,
    String? backFields,
    String? imageDisplayMode,
    bool? showBackFirst,
  }) async {
    final userId = _authService.userId;
    if (userId == null) {
      throw Exception('User must be signed in');
    }

    final deckDoc = await _restClient.getDocument(AppConstants.collectionPublicDecks, publicDeckId);
    if (deckDoc == null) {
      throw Exception('Deck not found');
    }

    final deck = PublicDeck.fromMap(deckDoc);
    if (deck.authorId != userId) {
      throw Exception('Only the author can update this deck');
    }

    final now = DateTime.now();
    final updates = <String, dynamic>{
      'version': deck.version + 1,
      'updated_at': now,
    };

    // Generate short_id for old decks that don't have one
    if (deck.shortId == null) {
      final newShortId = await _generateUniqueShortId();
      updates['short_id'] = newShortId;
    }

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (tags != null) updates['tags'] = tags;
    if (flashcards != null) updates['card_count'] = flashcards.length;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (frontFields != null) updates['front_fields'] = frontFields;
    if (backFields != null) updates['back_fields'] = backFields;
    if (imageDisplayMode != null) updates['image_display_mode'] = imageDisplayMode;
    if (showBackFirst != null) updates['show_back_first'] = showBackFirst;

    await _restClient.updateDocument(AppConstants.collectionPublicDecks, publicDeckId, updates);

    // Handle flashcards update
    if (flashcards != null) {
      // Get and delete existing flashcards
      final collectionPath = '${AppConstants.collectionPublicDecks}/$publicDeckId/${AppConstants.collectionPublicFlashcards}';
      final existingCards = await _restClient.getCollection(collectionPath);

      final batchOps = <BatchOperation>[];
      for (final card in existingCards) {
        batchOps.add(BatchOperation.delete(collectionPath, card['id']));
      }

      // Add new flashcards
      for (int i = 0; i < flashcards.length; i++) {
        final cardData = flashcards[i];
        final cardId = '${publicDeckId}_card_$i';
        batchOps.add(BatchOperation.set(
          collectionPath,
          cardId,
          {
            'public_deck_id': publicDeckId,
            'front': cardData['front'],
            'front_phonetic': cardData['front_phonetic'],
            'back': cardData['back'],
            'example': cardData['example'],
            'notes': cardData['notes'],
            'tags': cardData['tags'] ?? [],
            'front_image_url': cardData['front_image_url'],
            'back_image_url': cardData['back_image_url'],
            'share_image': cardData['share_image'] ?? true,
            'order': i,
            'created_at': now,
            'updated_at': now,
          },
        ));
      }

      // Batch write in chunks of 500 (Firestore REST API limit)
      for (int i = 0; i < batchOps.length; i += 500) {
        final chunk = batchOps.sublist(i, (i + 500).clamp(0, batchOps.length));
        final success = await _restClient.batchWrite(chunk);
        if (!success) {
          throw Exception('Failed to write flashcards to Firestore (batch ${i ~/ 500 + 1})');
        }
      }
    }
  }

  /// Unpublish a deck (set inactive)
  Future<void> unpublishDeck(String publicDeckId) async {
    final userId = _authService.userId;
    if (userId == null) {
      throw Exception('User must be signed in');
    }

    if (_useRest) {
      // Verify ownership
      final deckDoc = await _restClient.getDocument(AppConstants.collectionPublicDecks, publicDeckId);
      if (deckDoc == null) {
        throw Exception('Deck not found: $publicDeckId');
      }

      final deck = PublicDeck.fromMap(deckDoc);
      if (deck.authorId != userId) {
        throw Exception('Only the author can unpublish this deck');
      }

      // Delete flashcards subcollection first
      final flashcardsPath = '${AppConstants.collectionPublicDecks}/$publicDeckId/${AppConstants.collectionPublicFlashcards}';
      final flashcards = await _restClient.getCollection(flashcardsPath);
      for (final card in flashcards) {
        final cardId = card['id'] as String?;
        if (cardId != null) {
          await _restClient.deleteDocument(flashcardsPath, cardId);
        }
      }
      // Delete the deck document
      final deleteSuccess = await _restClient.deleteDocument(AppConstants.collectionPublicDecks, publicDeckId);
      if (!deleteSuccess) {
        throw Exception('Failed to delete deck from Firestore');
      }
    } else {
      final deckDoc = await _publicDecksRef.doc(publicDeckId).get();
      if (!deckDoc.exists) {
        throw Exception('Deck not found');
      }

      final deck = PublicDeck.fromFirestore(deckDoc);
      if (deck.authorId != userId) {
        throw Exception('Only the author can unpublish this deck');
      }

      // Delete flashcards subcollection first
      final flashcardsRef = _publicDecksRef.doc(publicDeckId).collection(AppConstants.collectionPublicFlashcards);
      final flashcardsSnapshot = await flashcardsRef.get();
      for (final doc in flashcardsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the deck document
      await _publicDecksRef.doc(publicDeckId).delete();
    }
  }

  /// Increment download count when a deck is imported
  Future<void> incrementDownloadCount(String publicDeckId) async {
    if (_useRest) {
      // For REST, we need to read current value and update
      final doc = await _restClient.getDocument(AppConstants.collectionPublicDecks, publicDeckId);
      if (doc != null) {
        final currentCount = doc['download_count'] as int? ?? 0;
        await _restClient.updateDocument(AppConstants.collectionPublicDecks, publicDeckId, {
          'download_count': currentCount + 1,
        });
      }
    } else {
      await _publicDecksRef.doc(publicDeckId).update({
        'download_count': FieldValue.increment(1),
      });
    }
  }

  /// Get decks published by the current user
  Future<List<PublicDeck>> getMyPublishedDecks() async {
    final userId = _authService.userId;
    if (userId == null) return [];

    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(
          AppConstants.collectionPublicDecks,
          where: [
            QueryFilter.isEqualTo('author_id', userId),
          ],
          orderBy: [OrderBy('updated_at', descending: true)],
          requireAuth: true,
        );
        return docs.map((doc) => PublicDeck.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('getMyPublishedDecks REST error: $e');
        return [];
      }
    } else {
      try {
        final snapshot = await _publicDecksRef
            .where('author_id', isEqualTo: userId)
            .orderBy('updated_at', descending: true)
            .get();

        return snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
      } catch (e) {
        debugPrint('getMyPublishedDecks error: $e');
        return [];
      }
    }
  }

  /// Get featured/popular decks for homepage
  Future<List<PublicDeck>> getFeaturedDecks({int limit = 10}) async {
    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(
          AppConstants.collectionPublicDecks,

          orderBy: [OrderBy('download_count', descending: true)],
          limit: limit,
        );
        return docs.map((doc) => PublicDeck.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('getFeaturedDecks REST error: $e');
        return [];
      }
    } else {
      try {
        final snapshot = await _publicDecksRef

            .orderBy('download_count', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
      } catch (e) {
        debugPrint('getFeaturedDecks error: $e');
        return [];
      }
    }
  }

  /// Get top rated decks
  Future<List<PublicDeck>> getTopRatedDecks({int limit = 10}) async {
    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(
          AppConstants.collectionPublicDecks,

          orderBy: [OrderBy('rating_sum', descending: true)],
          limit: limit,
        );
        return docs.map((doc) => PublicDeck.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('getTopRatedDecks REST error: $e');
        return [];
      }
    } else {
      try {
        final snapshot = await _publicDecksRef

            .orderBy('rating_sum', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
      } catch (e) {
        debugPrint('getTopRatedDecks error: $e');
        return [];
      }
    }
  }

  /// Get newest decks
  Future<List<PublicDeck>> getNewestDecks({int limit = 10}) async {
    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(
          AppConstants.collectionPublicDecks,

          orderBy: [OrderBy('published_at', descending: true)],
          limit: limit,
        );
        return docs.map((doc) => PublicDeck.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('getNewestDecks REST error: $e');
        return [];
      }
    } else {
      try {
        final snapshot = await _publicDecksRef

            .orderBy('published_at', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
      } catch (e) {
        debugPrint('getNewestDecks error: $e');
        return [];
      }
    }
  }
}
