import 'package:flutter/foundation.dart';
import '../../data/models/deck.dart';
import '../../data/repositories/deck_repository.dart';

class DeckProvider extends ChangeNotifier {
  final DeckRepository _repository;

  List<Deck> _decks = [];
  Deck? _selectedDeck;
  bool _isLoading = false;
  String? _error;

  DeckProvider({DeckRepository? repository})
      : _repository = repository ?? DeckRepository();

  List<Deck> get decks => _decks;
  Deck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalDecks => _decks.length;
  int get totalCards => _decks.fold(0, (sum, deck) => sum + deck.cardCount);
  int get totalDueCards => _decks.fold(0, (sum, deck) => sum + deck.dueCount);

  Future<void> loadDecks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _decks = await _repository.getAllDecks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectDeck(String id) async {
    _selectedDeck = await _repository.getDeckById(id);
    notifyListeners();
  }

  void clearSelectedDeck() {
    _selectedDeck = null;
    notifyListeners();
  }

  Future<void> createDeck(Deck deck) async {
    try {
      debugPrint('DeckProvider: Creating deck: ${deck.name}');
      await _repository.createDeck(deck);
      debugPrint('DeckProvider: Deck created successfully');
      await loadDecks();
      debugPrint('DeckProvider: Decks reloaded, total: ${_decks.length}');
    } catch (e, stackTrace) {
      debugPrint('DeckProvider: Error creating deck: $e');
      debugPrint('DeckProvider: Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDeck(Deck deck) async {
    try {
      debugPrint('DeckProvider: Updating deck: ${deck.name}');
      await _repository.updateDeck(deck);
      debugPrint('DeckProvider: Deck updated successfully');
      await loadDecks();
      if (_selectedDeck?.id == deck.id) {
        _selectedDeck = deck;
      }
    } catch (e, stackTrace) {
      debugPrint('DeckProvider: Error updating deck: $e');
      debugPrint('DeckProvider: Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDeck(String id) async {
    try {
      await _repository.deleteDeck(id);
      if (_selectedDeck?.id == id) {
        _selectedDeck = null;
      }
      await loadDecks();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Deck?> getDeckById(String id) async {
    return await _repository.getDeckById(id);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
