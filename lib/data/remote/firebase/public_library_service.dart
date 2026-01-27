import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/public_deck.dart';
import '../../models/public_flashcard.dart';
import '../../models/category.dart';
import 'firebase_service.dart';

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
    Query<Map<String, dynamic>> query = _publicDecksRef
        .where('is_active', isEqualTo: true);

    // Apply filters
    if (filter != null) {
      if (filter.categoryId != null && filter.categoryId!.isNotEmpty) {
        query = query.where('category_id', isEqualTo: filter.categoryId);
      }

      if (filter.sourceLanguage != null && filter.sourceLanguage!.isNotEmpty) {
        query = query.where('source_language', isEqualTo: filter.sourceLanguage);
      }

      if (filter.targetLanguage != null && filter.targetLanguage!.isNotEmpty) {
        query = query.where('target_language', isEqualTo: filter.targetLanguage);
      }

      // Sort order
      String orderField;
      switch (filter.sortBy) {
        case LibrarySortBy.popular:
          orderField = 'download_count';
          break;
        case LibrarySortBy.rating:
          orderField = 'rating_sum'; // Will calculate average on client
          break;
        case LibrarySortBy.newest:
          orderField = 'published_at';
          break;
        case LibrarySortBy.updated:
          orderField = 'updated_at';
          break;
      }
      query = query.orderBy(orderField, descending: filter.descending);
    } else {
      query = query.orderBy('download_count', descending: true);
    }

    // Pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(limit);

    final snapshot = await query.get();
    final decks = snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();

    // Client-side filtering for search query and tags (Firestore limitations)
    if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
      final searchLower = filter.searchQuery!.toLowerCase();
      return decks.where((deck) {
        return deck.name.toLowerCase().contains(searchLower) ||
            (deck.description?.toLowerCase().contains(searchLower) ?? false) ||
            deck.authorName.toLowerCase().contains(searchLower);
      }).toList();
    }

    if (filter?.tags != null && filter!.tags!.isNotEmpty) {
      return decks.where((deck) {
        return filter.tags!.any((tag) => deck.tags.contains(tag));
      }).toList();
    }

    return decks;
  }

  /// Search public decks by keyword
  Future<List<PublicDeck>> search(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    // Firestore doesn't support full-text search, so we fetch and filter
    final snapshot = await _publicDecksRef
        .where('is_active', isEqualTo: true)
        .orderBy('download_count', descending: true)
        .limit(100) // Fetch more for client-side filtering
        .get();

    final queryLower = query.toLowerCase();
    return snapshot.docs
        .map((doc) => PublicDeck.fromFirestore(doc))
        .where((deck) {
          return deck.name.toLowerCase().contains(queryLower) ||
              (deck.description?.toLowerCase().contains(queryLower) ?? false) ||
              deck.authorName.toLowerCase().contains(queryLower) ||
              deck.tags.any((tag) => tag.toLowerCase().contains(queryLower));
        })
        .take(limit)
        .toList();
  }

  /// Get a single public deck by ID
  Future<PublicDeck?> getDeck(String deckId) async {
    final doc = await _publicDecksRef.doc(deckId).get();
    if (!doc.exists) return null;
    return PublicDeck.fromFirestore(doc);
  }

  /// Get flashcards for a public deck
  Future<List<PublicFlashcard>> getFlashcards(String publicDeckId) async {
    final snapshot = await _publicDecksRef
        .doc(publicDeckId)
        .collection(AppConstants.collectionPublicFlashcards)
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) => PublicFlashcard.fromFirestore(doc)).toList();
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
  }) async {
    final userId = _authService.userId;
    final userName = _authService.userName ?? 'Anonymous';

    if (userId == null) {
      throw Exception('User must be signed in to publish');
    }

    // Create the public deck document
    final docRef = _publicDecksRef.doc();
    final publicDeck = PublicDeck(
      id: docRef.id,
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
        'order': i,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
    }

    await batch.commit();
    return publicDeck;
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

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (tags != null) updates['tags'] = tags;
    if (flashcards != null) updates['card_count'] = flashcards.length;

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
          'order': i,
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });
      }
    }

    await batch.commit();

    // TODO: Trigger Cloud Function to notify importers about update
    // This would create sync_notifications for users who imported this deck
  }

  /// Unpublish a deck (set inactive)
  Future<void> unpublishDeck(String publicDeckId) async {
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
      throw Exception('Only the author can unpublish this deck');
    }

    await _publicDecksRef.doc(publicDeckId).update({
      'is_active': false,
      'updated_at': Timestamp.now(),
    });
  }

  /// Increment download count when a deck is imported
  Future<void> incrementDownloadCount(String publicDeckId) async {
    await _publicDecksRef.doc(publicDeckId).update({
      'download_count': FieldValue.increment(1),
    });
  }

  /// Get decks published by the current user
  Future<List<PublicDeck>> getMyPublishedDecks() async {
    final userId = _authService.userId;
    if (userId == null) return [];

    final snapshot = await _publicDecksRef
        .where('author_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .get();

    return snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
  }

  /// Get featured/popular decks for homepage
  Future<List<PublicDeck>> getFeaturedDecks({int limit = 10}) async {
    final snapshot = await _publicDecksRef
        .where('is_active', isEqualTo: true)
        .orderBy('download_count', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
  }

  /// Get top rated decks
  Future<List<PublicDeck>> getTopRatedDecks({int limit = 10}) async {
    final snapshot = await _publicDecksRef
        .where('is_active', isEqualTo: true)
        .where('rating_count', isGreaterThan: 0)
        .orderBy('rating_count', descending: true)
        .limit(limit * 2) // Fetch more to sort by average
        .get();

    final decks = snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();

    // Sort by average rating
    decks.sort((a, b) => b.averageRating.compareTo(a.averageRating));

    return decks.take(limit).toList();
  }

  /// Get newest decks
  Future<List<PublicDeck>> getNewestDecks({int limit = 10}) async {
    final snapshot = await _publicDecksRef
        .where('is_active', isEqualTo: true)
        .orderBy('published_at', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PublicDeck.fromFirestore(doc)).toList();
  }
}
