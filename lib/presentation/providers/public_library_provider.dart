import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/public_deck.dart';
import '../../data/models/public_flashcard.dart';
import '../../data/models/deck_rating.dart';
import '../../data/models/category.dart';
import '../../data/models/deck.dart';
import '../../data/repositories/public_library_repository.dart';
import '../../data/remote/firebase/public_library_service.dart';

/// Provider for public library browsing, searching, and importing
class PublicLibraryProvider extends ChangeNotifier {
  final PublicLibraryRepository _repository = PublicLibraryRepository();

  // State
  List<PublicDeck> _decks = [];
  List<PublicDeck> _featuredDecks = [];
  List<PublicDeck> _topRatedDecks = [];
  List<PublicDeck> _newestDecks = [];
  List<Category> _categories = [];
  PublicDeck? _selectedDeck;
  List<PublicFlashcard> _previewFlashcards = [];
  DeckRating? _userRating;
  List<DeckRating> _deckRatings = [];

  LibraryFilter _filter = const LibraryFilter();
  String _searchQuery = '';

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isImporting = false;
  bool _hasMoreDecks = true;
  String? _error;

  // Getters
  List<PublicDeck> get decks => _decks;
  List<PublicDeck> get featuredDecks => _featuredDecks;
  List<PublicDeck> get topRatedDecks => _topRatedDecks;
  List<PublicDeck> get newestDecks => _newestDecks;
  List<Category> get categories => _categories;
  PublicDeck? get selectedDeck => _selectedDeck;
  List<PublicFlashcard> get previewFlashcards => _previewFlashcards;
  DeckRating? get userRating => _userRating;
  List<DeckRating> get deckRatings => _deckRatings;
  LibraryFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isImporting => _isImporting;
  bool get hasMoreDecks => _hasMoreDecks;
  String? get error => _error;

  /// Initialize the library (load categories and featured decks)
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadCategories(),
        loadFeaturedDecks(),
        loadTopRatedDecks(),
        loadNewestDecks(),
      ]);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  /// Load featured decks
  Future<void> loadFeaturedDecks() async {
    try {
      _featuredDecks = await _repository.getFeaturedDecks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured decks: $e');
    }
  }

  /// Load top rated decks
  Future<void> loadTopRatedDecks() async {
    try {
      _topRatedDecks = await _repository.getTopRatedDecks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading top rated decks: $e');
    }
  }

  /// Load newest decks
  Future<void> loadNewestDecks() async {
    try {
      _newestDecks = await _repository.getNewestDecks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading newest decks: $e');
    }
  }

  /// Browse decks with current filter
  Future<void> browse({bool refresh = false}) async {
    if (refresh) {
      _decks = [];
      _hasMoreDecks = true;
    }

    if (!_hasMoreDecks && !refresh) return;

    _isLoading = refresh || _decks.isEmpty;
    _isLoadingMore = !refresh && _decks.isNotEmpty;
    _error = null;
    notifyListeners();

    try {
      final newDecks = await _repository.browse(
        filter: _filter,
        limit: 20,
      );

      if (refresh) {
        _decks = newDecks;
      } else {
        _decks = [..._decks, ...newDecks];
      }

      _hasMoreDecks = newDecks.length >= 20;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Search decks
  Future<void> search(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        await browse(refresh: true);
      } else {
        _decks = await _repository.search(query);
        _hasMoreDecks = false;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update filter
  void setFilter(LibraryFilter newFilter) {
    _filter = newFilter;
    browse(refresh: true);
  }

  /// Set category filter
  void setCategory(String? categoryId) {
    _filter = _filter.copyWith(categoryId: categoryId);
    browse(refresh: true);
  }

  /// Set language filter
  void setLanguages({String? source, String? target}) {
    _filter = _filter.copyWith(
      sourceLanguage: source,
      targetLanguage: target,
    );
    browse(refresh: true);
  }

  /// Set sort order
  void setSortBy(LibrarySortBy sortBy) {
    _filter = _filter.copyWith(sortBy: sortBy);
    browse(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _filter = const LibraryFilter();
    _searchQuery = '';
    browse(refresh: true);
  }

  /// Select a deck to view details
  Future<void> selectDeck(String deckId) async {
    _isLoading = true;
    _error = null;
    _selectedDeck = null;
    _previewFlashcards = [];
    _userRating = null;
    _deckRatings = [];
    notifyListeners();

    try {
      // Load deck details, flashcards, and ratings in parallel
      final results = await Future.wait([
        _repository.getPublicDeck(deckId),
        _repository.getPublicFlashcards(deckId),
        _repository.getUserRating(deckId),
        _repository.getDeckRatings(deckId),
      ]);

      _selectedDeck = results[0] as PublicDeck?;
      _previewFlashcards = results[1] as List<PublicFlashcard>;
      _userRating = results[2] as DeckRating?;
      _deckRatings = results[3] as List<DeckRating>;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear selected deck
  void clearSelection() {
    _selectedDeck = null;
    _previewFlashcards = [];
    _userRating = null;
    _deckRatings = [];
    notifyListeners();
  }

  /// Import a public deck
  Future<Deck?> importDeck(String publicDeckId) async {
    _isImporting = true;
    _error = null;
    notifyListeners();

    try {
      final deck = await _repository.importDeck(publicDeckId);
      _isImporting = false;
      notifyListeners();
      return deck;
    } catch (e) {
      _error = e.toString();
      _isImporting = false;
      notifyListeners();
      return null;
    }
  }

  /// Check if a deck is already imported
  Future<bool> isImported(String publicDeckId) =>
      _repository.isImported(publicDeckId);

  /// Rate the selected deck
  Future<void> rateDeck(int rating, {String? review}) async {
    if (_selectedDeck == null) return;

    try {
      _userRating = await _repository.rateDeck(
        publicDeckId: _selectedDeck!.id,
        rating: rating,
        review: review,
      );

      // Refresh the deck to get updated rating stats
      _selectedDeck = await _repository.getPublicDeck(_selectedDeck!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete user's rating
  Future<void> deleteRating() async {
    if (_selectedDeck == null) return;

    try {
      await _repository.deleteRating(_selectedDeck!.id);
      _userRating = null;

      // Refresh the deck to get updated rating stats
      _selectedDeck = await _repository.getPublicDeck(_selectedDeck!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
