import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firestore_rest_client.dart';

/// Utility class to seed initial public_decks collection
/// This creates the collection if it doesn't exist
class PublicDeckSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreRestClient _restClient = FirestoreRestClient();

  bool get _useRest => FirestoreRestClient.shouldUseRest;

  /// Seed a sample public deck to create the collection
  Future<void> seedIfNeeded() async {
    try {
      debugPrint('PublicDeckSeeder: Checking if public_decks collection exists...');

      final exists = await _collectionExists();

      if (!exists) {
        debugPrint('PublicDeckSeeder: Collection empty, creating sample deck...');
        await _createSampleDeck();
        debugPrint('PublicDeckSeeder: Sample deck created successfully');
      } else {
        debugPrint('PublicDeckSeeder: Collection already has documents');
      }
    } catch (e) {
      debugPrint('PublicDeckSeeder error: $e');
      // Don't throw - just log the error
    }
  }

  Future<bool> _collectionExists() async {
    if (_useRest) {
      try {
        final docs = await _restClient.getCollection('public_decks', limit: 1);
        return docs.isNotEmpty;
      } catch (e) {
        debugPrint('_collectionExists REST error: $e');
        return false;
      }
    } else {
      final snapshot = await _firestore
          .collection('public_decks')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      return snapshot.docs.isNotEmpty;
    }
  }

  Future<void> _createSampleDeck() async {
    if (_useRest) {
      await _createSampleDeckRest();
    } else {
      await _createSampleDeckNative();
    }
  }

  Future<void> _createSampleDeckNative() async {
    final now = FieldValue.serverTimestamp();

    // Create a sample public deck
    final deckRef = _firestore.collection('public_decks').doc();

    await deckRef.set({
      'name': 'Sample English-Vietnamese Deck',
      'description': 'A sample deck to demonstrate the public library feature. Feel free to delete this.',
      'author_id': 'system',
      'author_name': 'VocabFlip System',
      'source_language': 'en',
      'target_language': 'vi',
      'category_id': 'daily',
      'tags': ['sample', 'english', 'vietnamese', 'beginner'],
      'card_count': 5,
      'download_count': 0,
      'rating_sum': 0,
      'rating_count': 0,
      'version': 1,
      'is_active': true,
      'created_at': now,
      'updated_at': now,
      'published_at': now,
    });

    // Create sample flashcards in subcollection
    final flashcardsRef = deckRef.collection('flashcards');

    final sampleCards = [
      {'front': 'Hello', 'back': 'Xin chào', 'order': 0},
      {'front': 'Goodbye', 'back': 'Tạm biệt', 'order': 1},
      {'front': 'Thank you', 'back': 'Cảm ơn', 'order': 2},
      {'front': 'Please', 'back': 'Làm ơn', 'order': 3},
      {'front': 'Sorry', 'back': 'Xin lỗi', 'order': 4},
    ];

    for (final card in sampleCards) {
      await flashcardsRef.add({
        ...card,
        'example': null,
        'notes': null,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> _createSampleDeckRest() async {
    final now = DateTime.now();

    // Create a sample public deck
    final deckData = {
      'name': 'Sample English-Vietnamese Deck',
      'description': 'A sample deck to demonstrate the public library feature. Feel free to delete this.',
      'author_id': 'system',
      'author_name': 'VocabFlip System',
      'source_language': 'en',
      'target_language': 'vi',
      'category_id': 'daily',
      'tags': ['sample', 'english', 'vietnamese', 'beginner'],
      'card_count': 5,
      'download_count': 0,
      'rating_sum': 0,
      'rating_count': 0,
      'version': 1,
      'is_active': true,
      'created_at': now,
      'updated_at': now,
      'published_at': now,
    };

    final deckDoc = await _restClient.createDocument('public_decks', deckData);
    if (deckDoc == null) {
      debugPrint('PublicDeckSeeder: Failed to create deck via REST');
      return;
    }

    final deckId = deckDoc['id'] as String;

    // Create sample flashcards using batch
    final sampleCards = [
      {'front': 'Hello', 'back': 'Xin chào', 'order': 0},
      {'front': 'Goodbye', 'back': 'Tạm biệt', 'order': 1},
      {'front': 'Thank you', 'back': 'Cảm ơn', 'order': 2},
      {'front': 'Please', 'back': 'Làm ơn', 'order': 3},
      {'front': 'Sorry', 'back': 'Xin lỗi', 'order': 4},
    ];

    final batchOps = <BatchOperation>[];
    for (int i = 0; i < sampleCards.length; i++) {
      final card = sampleCards[i];
      batchOps.add(BatchOperation.set(
        'public_decks/$deckId/flashcards',
        '${deckId}_card_$i',
        {
          ...card,
          'public_deck_id': deckId,
          'example': null,
          'notes': null,
          'tags': <String>[],
          'created_at': now,
          'updated_at': now,
        },
      ));
    }

    await _restClient.batchWrite(batchOps);
  }
}
