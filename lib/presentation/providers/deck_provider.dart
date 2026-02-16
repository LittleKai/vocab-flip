import 'package:flutter/foundation.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../data/models/deck.dart';
import '../../data/models/flashcard.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/flashcard_repository.dart';

enum DeckSortBy { recentlyUpdated, nameAZ, nameZA, mostCards, mostDue, oldest }

DeckSortBy _parseDeckSortBy(String value) {
  return DeckSortBy.values.firstWhere(
    (e) => e.name == value,
    orElse: () => DeckSortBy.recentlyUpdated,
  );
}

class DeckProvider extends ChangeNotifier {
  final DeckRepository _repository;
  final FlashcardRepository _flashcardRepository;
  final AppPreferences? _preferences;

  List<Deck> _decks = [];
  Deck? _selectedDeck;
  bool _isLoading = false;
  String? _error;

  // Search & filter state
  String _searchQuery = '';
  String? _filterCategory;
  String? _filterLanguage;
  DeckSortBy _sortBy = DeckSortBy.recentlyUpdated;

  DeckProvider({
    DeckRepository? repository,
    FlashcardRepository? flashcardRepository,
    AppPreferences? preferences,
  })  : _repository = repository ?? DeckRepository(),
        _flashcardRepository = flashcardRepository ?? FlashcardRepository(),
        _preferences = preferences {
    _loadSavedFilters();
  }

  void _loadSavedFilters() {
    if (_preferences == null) return;
    _filterCategory = _preferences.deckFilterCategory;
    _filterLanguage = _preferences.deckFilterLanguage;
    _sortBy = _parseDeckSortBy(_preferences.deckFilterSortBy);
  }

  void _saveFilters() {
    if (_preferences == null) return;
    _preferences.setDeckFilterCategory(_filterCategory);
    _preferences.setDeckFilterLanguage(_filterLanguage);
    _preferences.setDeckFilterSortBy(_sortBy.name);
  }

  List<Deck> get decks => _decks;
  Deck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Search & filter getters
  String get searchQuery => _searchQuery;
  String? get filterCategory => _filterCategory;
  String? get filterLanguage => _filterLanguage;
  DeckSortBy get sortBy => _sortBy;

  bool get hasActiveFilters =>
      _filterCategory != null ||
      _filterLanguage != null ||
      _sortBy != DeckSortBy.recentlyUpdated;

  List<Deck> get filteredDecks {
    var result = List<Deck>.from(_decks);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((deck) {
        return deck.name.toLowerCase().contains(query) ||
            (deck.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by category
    if (_filterCategory != null) {
      result = result.where((deck) => deck.category == _filterCategory).toList();
    }

    // Filter by source language
    if (_filterLanguage != null) {
      result = result.where((deck) => deck.sourceLanguage == _filterLanguage).toList();
    }

    // Sort
    switch (_sortBy) {
      case DeckSortBy.recentlyUpdated:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case DeckSortBy.nameAZ:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case DeckSortBy.nameZA:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case DeckSortBy.mostCards:
        result.sort((a, b) => b.cardCount.compareTo(a.cardCount));
      case DeckSortBy.mostDue:
        result.sort((a, b) => b.dueCount.compareTo(a.dueCount));
      case DeckSortBy.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return result;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDeckFilter({String? category, String? language, DeckSortBy? sortBy}) {
    _filterCategory = category;
    _filterLanguage = language;
    if (sortBy != null) _sortBy = sortBy;
    _saveFilters();
    notifyListeners();
  }

  void clearDeckFilters() {
    _searchQuery = '';
    _filterCategory = null;
    _filterLanguage = null;
    _sortBy = DeckSortBy.recentlyUpdated;
    _saveFilters();
    notifyListeners();
  }

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

  /// Set a temporary deck for online browsing (no DB load)
  void setTemporaryDeck(Deck deck) {
    _selectedDeck = deck;
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

  /// Add a flashcard to a deck from dictionary lookup
  Future<void> addFlashcard({
    required String deckId,
    required String front,
    required String back,
    String? phonetic,
    String? example,
    String? notes,
  }) async {
    try {
      debugPrint('DeckProvider: Adding flashcard to deck $deckId');
      final flashcard = Flashcard(
        deckId: deckId,
        front: front,
        back: back,
        frontPhonetic: phonetic,
        example: example,
        notes: notes,
      );
      await _flashcardRepository.createFlashcard(flashcard);
      debugPrint('DeckProvider: Flashcard added successfully');

      // Reload decks to update card counts
      await loadDecks();
    } catch (e, stackTrace) {
      debugPrint('DeckProvider: Error adding flashcard: $e');
      debugPrint('DeckProvider: Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
