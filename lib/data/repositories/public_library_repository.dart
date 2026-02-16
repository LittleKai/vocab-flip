import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/public_deck.dart';
import '../models/public_flashcard.dart';
import '../models/public_profile.dart';
import '../models/deck_rating.dart';
import '../models/category.dart';
import '../models/imported_deck_link.dart';
import '../models/sync_notification.dart';
import '../../core/constants/app_constants.dart';
import '../remote/firebase/public_library_service.dart';
import '../remote/firebase/rating_service.dart';
import '../remote/firebase/sync_service.dart';
import '../remote/firebase/firestore_rest_client.dart';
import '../local/database/deck_dao.dart';
import '../local/database/flashcard_dao.dart';
import '../services/cloudinary_service.dart';

/// Repository for public library operations
/// Coordinates between remote Firebase services and local database
class PublicLibraryRepository {
  final PublicLibraryService _libraryService = PublicLibraryService();
  final RatingService _ratingService = RatingService();
  final SyncService _syncService = SyncService();
  final DeckDao _deckDao = DeckDao();
  final FlashcardDao _flashcardDao = FlashcardDao();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirestoreRestClient _firestoreClient = FirestoreRestClient();

  bool get _useRest => !kIsWeb && Platform.isWindows;

  /// Parse comma-separated field types string to List<CardFieldType>
  static List<CardFieldType>? _parseFieldTypes(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      return str.split(',').map((s) => CardFieldType.values.firstWhere((f) => f.name == s)).toList();
    } catch (_) {
      return null;
    }
  }

  // ===== Browse & Search =====

  /// Get all available categories
  Future<List<Category>> getCategories() => _libraryService.getCategories();

  /// Browse public decks with filters
  Future<List<PublicDeck>> browse({
    LibraryFilter? filter,
    int limit = 20,
  }) => _libraryService.browse(filter: filter, limit: limit);

  /// Search public decks
  Future<List<PublicDeck>> search(String query, {int limit = 20}) =>
      _libraryService.search(query, limit: limit);

  /// Get a single public deck
  Future<PublicDeck?> getPublicDeck(String deckId) =>
      _libraryService.getDeck(deckId);

  /// Get flashcards for a public deck (preview)
  Future<List<PublicFlashcard>> getPublicFlashcards(String publicDeckId) =>
      _libraryService.getFlashcards(publicDeckId);

  /// Get featured decks for homepage
  Future<List<PublicDeck>> getFeaturedDecks({int limit = 10}) =>
      _libraryService.getFeaturedDecks(limit: limit);

  /// Get top rated decks
  Future<List<PublicDeck>> getTopRatedDecks({int limit = 10}) =>
      _libraryService.getTopRatedDecks(limit: limit);

  /// Get newest decks
  Future<List<PublicDeck>> getNewestDecks({int limit = 10}) =>
      _libraryService.getNewestDecks(limit: limit);

  // ===== Author Profiles =====

  /// Get a public profile for an author
  Future<PublicProfile?> getAuthorProfile(String authorId) async {
    try {
      if (_useRest) {
        final data = await _firestoreClient.getDocument(
          AppConstants.collectionPublicProfiles, authorId,
        );
        if (data != null) {
          return PublicProfile.fromFirestore(authorId, data);
        }
      } else {
        final doc = await FirebaseFirestore.instance
            .collection(AppConstants.collectionPublicProfiles)
            .doc(authorId)
            .get();
        if (doc.exists && doc.data() != null) {
          return PublicProfile.fromFirestore(authorId, doc.data()!);
        }
      }
    } catch (e) {
      debugPrint('PublicLibraryRepository: getAuthorProfile error: $e');
    }
    return null;
  }

  // ===== Import =====

  /// Import a public deck to local storage
  /// Creates a local copy and establishes a link for sync
  /// [onImageProgress] callback for image download progress
  Future<Deck> importDeck(
    String publicDeckId, {
    ImageProgressCallback? onImageProgress,
  }) async {
    // Get the public deck and its flashcards
    final publicDeck = await _libraryService.getDeck(publicDeckId);
    if (publicDeck == null) {
      throw Exception('Public deck not found');
    }

    final publicFlashcards = await _libraryService.getFlashcards(publicDeckId);

    // Count total images to download
    final cardsWithImages = publicFlashcards.where((pf) =>
      (pf.frontImageUrl != null && pf.frontImageUrl!.isNotEmpty) ||
      (pf.backImageUrl != null && pf.backImageUrl!.isNotEmpty)
    ).toList();

    int totalImages = 0;
    for (final pf in cardsWithImages) {
      if (pf.frontImageUrl != null && pf.frontImageUrl!.isNotEmpty) totalImages++;
      if (pf.backImageUrl != null && pf.backImageUrl!.isNotEmpty) totalImages++;
    }

    // Get local image directory
    String? localImageDir;
    if (totalImages > 0) {
      localImageDir = await _cloudinaryService.getImageDirectory();
    }

    // Create local deck
    final localDeck = Deck(
      id: const Uuid().v4(),
      name: publicDeck.name,
      description: publicDeck.description,
      sourceLanguage: publicDeck.sourceLanguage,
      targetLanguage: publicDeck.targetLanguage,
      linkedPublicDeckId: publicDeckId,
      linkedVersion: publicDeck.version,
      wasImported: true,
      category: publicDeck.categoryId,
      tags: publicDeck.tags,
      imagePath: publicDeck.imageUrl,
      frontFields: _parseFieldTypes(publicDeck.frontFields),
      backFields: _parseFieldTypes(publicDeck.backFields),
    );

    // Insert deck to local DB
    await _deckDao.insert(localDeck);

    // Download images and create flashcards
    int imageCompleted = 0;
    int imageFailed = 0;
    final localFlashcards = <Flashcard>[];

    for (final pf in publicFlashcards) {
      String? localFrontImage;
      String? localBackImage;

      // Download front image
      if (pf.frontImageUrl != null && pf.frontImageUrl!.isNotEmpty && localImageDir != null) {
        localFrontImage = await _cloudinaryService.downloadImage(pf.frontImageUrl!, localImageDir);
        imageCompleted++;
        if (localFrontImage == null) imageFailed++;
        onImageProgress?.call(imageCompleted, totalImages, imageFailed);
      }

      // Download back image
      if (pf.backImageUrl != null && pf.backImageUrl!.isNotEmpty && localImageDir != null) {
        localBackImage = await _cloudinaryService.downloadImage(pf.backImageUrl!, localImageDir);
        imageCompleted++;
        if (localBackImage == null) imageFailed++;
        onImageProgress?.call(imageCompleted, totalImages, imageFailed);
      }

      localFlashcards.add(Flashcard(
        id: const Uuid().v4(),
        deckId: localDeck.id,
        front: pf.front,
        frontPhonetic: pf.frontPhonetic,
        back: pf.back,
        example: pf.example,
        notes: pf.notes,
        tags: pf.tags,
        frontImageUrl: localFrontImage,
        backImageUrl: localBackImage,
        shareImage: pf.shareImage,
      ));
    }

    await _flashcardDao.insertBatch(localFlashcards);

    // Record the import link
    await _syncService.recordImport(
      publicDeckId: publicDeckId,
      localDeckId: localDeck.id,
      importedVersion: publicDeck.version,
    );

    // Increment download count
    await _libraryService.incrementDownloadCount(publicDeckId);

    return localDeck;
  }

  /// Check if a public deck is already imported
  Future<bool> isImported(String publicDeckId) async {
    final link = await _syncService.getImportLinkByPublicDeck(publicDeckId);
    return link != null;
  }

  /// Get import link for a local deck
  Future<ImportedDeckLink?> getImportLink(String localDeckId) =>
      _syncService.getImportLink(localDeckId);

  // ===== Sync =====

  /// Check for updates on all imported decks
  Future<List<({ImportedDeckLink link, PublicDeck deck})>> checkForUpdates() =>
      _syncService.checkAllUpdates();

  /// Sync an imported deck with its source
  /// Keeps learning progress, updates content
  Future<void> syncDeck(String localDeckId) async {
    final link = await _syncService.getImportLink(localDeckId);
    if (link == null) {
      throw Exception('Deck is not linked to a public deck');
    }

    // Get current public deck and flashcards
    final publicDeck = await _libraryService.getDeck(link.publicDeckId);
    if (publicDeck == null) {
      throw Exception('Source public deck not found');
    }

    if (publicDeck.version <= link.importedVersion) {
      return; // Already up to date
    }

    final publicFlashcards = await _libraryService.getFlashcards(link.publicDeckId);

    // Get existing local flashcards (to preserve learning progress)
    final localFlashcards = await _flashcardDao.getByDeckId(localDeckId);
    final localCardMap = <String, Flashcard>{};
    for (final card in localFlashcards) {
      // Map by front text for matching
      localCardMap[card.front.toLowerCase()] = card;
    }

    // Process each public flashcard
    for (final publicCard in publicFlashcards) {
      final frontKey = publicCard.front.toLowerCase();
      final existingCard = localCardMap[frontKey];

      if (existingCard != null) {
        // Update content, keep learning progress
        final updatedCard = existingCard.copyWith(
          front: publicCard.front,
          frontPhonetic: publicCard.frontPhonetic,
          back: publicCard.back,
          example: publicCard.example,
          notes: publicCard.notes,
          tags: publicCard.tags,
        );
        await _flashcardDao.update(updatedCard);
        localCardMap.remove(frontKey);
      } else {
        // Add new card
        final newCard = Flashcard(
          id: const Uuid().v4(),
          deckId: localDeckId,
          front: publicCard.front,
          frontPhonetic: publicCard.frontPhonetic,
          back: publicCard.back,
          example: publicCard.example,
          notes: publicCard.notes,
          tags: publicCard.tags,
        );
        await _flashcardDao.insert(newCard);
      }
    }

    // Cards remaining in localCardMap were removed by author
    // Keep them for now (user might have their own notes/progress)

    // Update local deck metadata
    final localDeck = await _deckDao.getById(localDeckId);
    if (localDeck != null) {
      final updatedDeck = localDeck.copyWith(
        name: publicDeck.name,
        description: publicDeck.description,
        linkedVersion: publicDeck.version,
      );
      await _deckDao.update(updatedDeck);
    }

    // Update the import link
    await _syncService.updateImportLink(
      linkId: link.id,
      newVersion: publicDeck.version,
    );
  }

  /// Unlink a deck from its public source
  Future<void> unlinkDeck(String localDeckId) async {
    final link = await _syncService.getImportLink(localDeckId);
    if (link == null) return;

    // Delete the link
    await _syncService.deleteImportLink(link.id);

    // Clear link fields only (safe partial update, preserves all other data)
    await _deckDao.updateFields(localDeckId, {
      'linked_public_deck_id': null,
      'linked_version': null,
    });
  }

  // ===== Publish =====

  /// Publish a local deck to the public library
  /// [onImageProgress] callback for image upload progress
  Future<PublicDeck> publishDeck({
    required String localDeckId,
    required String categoryId,
    required List<String> tags,
    String? authorName,
    ImageProgressCallback? onImageProgress,
  }) async {
    // Get local deck and flashcards
    final deck = await _deckDao.getById(localDeckId);
    if (deck == null) {
      throw Exception('Deck not found');
    }

    final flashcards = await _flashcardDao.getByDeckId(localDeckId);

    // Collect all local image paths that need uploading
    final localImagePaths = <String>{};
    for (final f in flashcards) {
      final frontImg = f.effectiveFrontImageUrl;
      if (frontImg != null && CloudinaryService.isLocalPath(frontImg)) {
        localImagePaths.add(frontImg);
      }
      final backImg = f.backImageUrl;
      if (backImg != null && CloudinaryService.isLocalPath(backImg)) {
        localImagePaths.add(backImg);
      }
    }

    // Upload images to Cloudinary if any
    Map<String, String?> uploadedUrls = {};
    if (localImagePaths.isNotEmpty) {
      uploadedUrls = await _cloudinaryService.uploadImages(
        localImagePaths.toList(),
        subfolder: localDeckId,
        onProgress: onImageProgress,
      );
    }

    // Helper to resolve image path to URL
    String? resolveImageUrl(String? path) {
      if (path == null || path.isEmpty) return null;
      if (CloudinaryService.isUrl(path)) return path;
      // Local path - check if uploaded
      return uploadedUrls[path];
    }

    // Convert flashcards to maps with image URLs
    final flashcardMaps = flashcards.map((f) => {
      'front': f.front,
      'front_phonetic': f.frontPhonetic,
      'back': f.back,
      'example': f.example,
      'notes': f.notes,
      'tags': f.tags,
      'front_image_url': resolveImageUrl(f.effectiveFrontImageUrl),
      'back_image_url': resolveImageUrl(f.backImageUrl),
      'share_image': f.shareImage,
    }).toList();

    // Upload deck cover image if local
    String? deckImageUrl;
    if (deck.imagePath != null && deck.imagePath!.isNotEmpty) {
      if (CloudinaryService.isUrl(deck.imagePath!)) {
        deckImageUrl = deck.imagePath;
      } else if (CloudinaryService.isLocalPath(deck.imagePath!)) {
        final uploaded = await _cloudinaryService.uploadImages(
          [deck.imagePath!],
          subfolder: '${localDeckId}_cover',
        );
        deckImageUrl = uploaded[deck.imagePath!];
      }
    }

    // Build front/back fields string from deck
    final frontFieldsStr = deck.frontFields.map((f) => f.name).join(',');
    final backFieldsStr = deck.backFields.map((f) => f.name).join(',');

    // Publish to library
    final publicDeck = await _libraryService.publishDeck(
      localDeckId: localDeckId,
      name: deck.name,
      description: deck.description,
      sourceLanguage: deck.sourceLanguage,
      targetLanguage: deck.targetLanguage,
      categoryId: categoryId,
      tags: tags,
      flashcards: flashcardMaps,
      imageUrl: deckImageUrl,
      frontFields: frontFieldsStr,
      backFields: backFieldsStr,
      authorName: authorName,
      imageDisplayMode: deck.imageDisplayMode.name,
      showBackFirst: deck.showBackFirst,
    );

    // Update local deck with published info
    final updatedDeck = deck.copyWith(
      isPublished: true,
      publishedDeckId: publicDeck.id,
    );
    await _deckDao.update(updatedDeck);

    return publicDeck;
  }

  /// Update a published deck
  /// [onImageProgress] callback for image upload progress
  Future<void> updatePublishedDeck({
    required String localDeckId,
    String? categoryId,
    List<String>? tags,
    bool updateCards = true,
    ImageProgressCallback? onImageProgress,
  }) async {
    final deck = await _deckDao.getById(localDeckId);
    if (deck == null || deck.publishedDeckId == null) {
      throw Exception('Deck not found or not published');
    }

    List<Map<String, dynamic>>? flashcardMaps;
    if (updateCards) {
      final flashcards = await _flashcardDao.getByDeckId(localDeckId);

      // Collect local image paths
      final localImagePaths = <String>{};
      for (final f in flashcards) {
        final frontImg = f.effectiveFrontImageUrl;
        if (frontImg != null && CloudinaryService.isLocalPath(frontImg)) {
          localImagePaths.add(frontImg);
        }
        final backImg = f.backImageUrl;
        if (backImg != null && CloudinaryService.isLocalPath(backImg)) {
          localImagePaths.add(backImg);
        }
      }

      // Upload images
      Map<String, String?> uploadedUrls = {};
      if (localImagePaths.isNotEmpty) {
        uploadedUrls = await _cloudinaryService.uploadImages(
          localImagePaths.toList(),
          subfolder: localDeckId,
          onProgress: onImageProgress,
        );
      }

      String? resolveImageUrl(String? path) {
        if (path == null || path.isEmpty) return null;
        if (CloudinaryService.isUrl(path)) return path;
        return uploadedUrls[path];
      }

      flashcardMaps = flashcards.map((f) => {
        'front': f.front,
        'front_phonetic': f.frontPhonetic,
        'back': f.back,
        'example': f.example,
        'notes': f.notes,
        'tags': f.tags,
        'front_image_url': resolveImageUrl(f.effectiveFrontImageUrl),
        'back_image_url': resolveImageUrl(f.backImageUrl),
        'share_image': f.shareImage,
      }).toList();
    }

    // Upload deck cover image if local
    String? deckImageUrl;
    if (deck.imagePath != null && deck.imagePath!.isNotEmpty) {
      if (CloudinaryService.isUrl(deck.imagePath!)) {
        deckImageUrl = deck.imagePath;
      } else if (CloudinaryService.isLocalPath(deck.imagePath!)) {
        final uploaded = await _cloudinaryService.uploadImages(
          [deck.imagePath!],
          subfolder: '${localDeckId}_cover',
        );
        deckImageUrl = uploaded[deck.imagePath!];
      }
    }

    final frontFieldsStr = deck.frontFields.map((f) => f.name).join(',');
    final backFieldsStr = deck.backFields.map((f) => f.name).join(',');

    await _libraryService.updatePublishedDeck(
      publicDeckId: deck.publishedDeckId!,
      name: deck.name,
      description: deck.description,
      categoryId: categoryId,
      tags: tags,
      flashcards: flashcardMaps,
      imageUrl: deckImageUrl,
      frontFields: frontFieldsStr,
      backFields: backFieldsStr,
      imageDisplayMode: deck.imageDisplayMode.name,
      showBackFirst: deck.showBackFirst,
    );
  }

  /// Unpublish a deck
  Future<void> unpublishDeck(String localDeckId) async {
    final deck = await _deckDao.getById(localDeckId);
    if (deck == null || deck.publishedDeckId == null) {
      throw Exception('Deck not found or not published');
    }

    await _libraryService.unpublishDeck(deck.publishedDeckId!);

    // Update only publish-related fields (safe partial update)
    await _deckDao.updateFields(localDeckId, {
      'is_published': 0,
      'published_deck_id': null,
    });
  }

  /// Unpublish a deck by public deck ID (used from library screen)
  Future<void> unpublishByPublicId(String publicDeckId) async {
    await _libraryService.unpublishDeck(publicDeckId);

    // Find and update local deck (safe partial update - only publish fields)
    final localDecks = await _deckDao.getAll();
    final localDeck = localDecks.where((d) => d.publishedDeckId == publicDeckId).firstOrNull;
    if (localDeck != null) {
      await _deckDao.updateFields(localDeck.id, {
        'is_published': 0,
        'published_deck_id': null,
      });
    }
  }

  /// Get decks published by the current user
  Future<List<PublicDeck>> getMyPublishedDecks() =>
      _libraryService.getMyPublishedDecks();

  // ===== Rating =====

  /// Rate a public deck
  Future<DeckRating> rateDeck({
    required String publicDeckId,
    required int rating,
    String? review,
    String? nickname,
  }) => _ratingService.rateDeck(
    publicDeckId: publicDeckId,
    rating: rating,
    review: review,
    nickname: nickname,
  );

  /// Get user's rating for a deck
  Future<DeckRating?> getUserRating(String publicDeckId) =>
      _ratingService.getUserRating(publicDeckId);

  /// Get all ratings for a deck
  Future<List<DeckRating>> getDeckRatings(String publicDeckId, {int limit = 20}) =>
      _ratingService.getDeckRatings(publicDeckId, limit: limit);

  /// Delete user's rating
  Future<void> deleteRating(String publicDeckId) =>
      _ratingService.deleteRating(publicDeckId);

  // ===== Notifications =====

  /// Get unread sync notifications
  Future<List<SyncNotification>> getUnreadNotifications() =>
      _syncService.getUnreadNotifications();

  /// Get all notifications
  Future<List<SyncNotification>> getAllNotifications({int limit = 50}) =>
      _syncService.getAllNotifications(limit: limit);

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) =>
      _syncService.markNotificationRead(notificationId);

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() =>
      _syncService.markAllNotificationsRead();
}
