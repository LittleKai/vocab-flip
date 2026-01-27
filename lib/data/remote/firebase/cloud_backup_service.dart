// Cloud backup service placeholder
// Uncomment and configure when Firebase is set up

/*
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/deck.dart';
import '../../../data/models/flashcard.dart';
import 'firebase_service.dart';

class CloudBackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  String? get _userId => _firebaseService.currentUser?.uid;

  CollectionReference get _decksCollection =>
      _firestore.collection('users').doc(_userId).collection('decks');

  Future<void> backupDeck(Deck deck, List<Flashcard> cards) async {
    if (_userId == null) throw Exception('Not signed in');

    final deckRef = _decksCollection.doc(deck.id);

    await deckRef.set(deck.toMap());

    final batch = _firestore.batch();
    final cardsCollection = deckRef.collection('cards');

    for (final card in cards) {
      batch.set(cardsCollection.doc(card.id), card.toMap());
    }

    await batch.commit();
  }

  Future<Map<String, dynamic>?> restoreDeck(String deckId) async {
    if (_userId == null) throw Exception('Not signed in');

    final deckDoc = await _decksCollection.doc(deckId).get();
    if (!deckDoc.exists) return null;

    final cardsSnapshot = await _decksCollection
        .doc(deckId)
        .collection('cards')
        .get();

    return {
      'deck': deckDoc.data(),
      'cards': cardsSnapshot.docs.map((doc) => doc.data()).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> listBackups() async {
    if (_userId == null) throw Exception('Not signed in');

    final snapshot = await _decksCollection.get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> deleteBackup(String deckId) async {
    if (_userId == null) throw Exception('Not signed in');

    // Delete all cards first
    final cardsSnapshot = await _decksCollection
        .doc(deckId)
        .collection('cards')
        .get();

    final batch = _firestore.batch();
    for (final doc in cardsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete deck
    await _decksCollection.doc(deckId).delete();
  }
}
*/

class CloudBackupService {
  Future<void> backupDeck(dynamic deck, List<dynamic> cards) async {
    throw UnimplementedError('Firebase not configured');
  }

  Future<Map<String, dynamic>?> restoreDeck(String deckId) async {
    throw UnimplementedError('Firebase not configured');
  }

  Future<List<Map<String, dynamic>>> listBackups() async {
    throw UnimplementedError('Firebase not configured');
  }

  Future<void> deleteBackup(String deckId) async {
    throw UnimplementedError('Firebase not configured');
  }
}
