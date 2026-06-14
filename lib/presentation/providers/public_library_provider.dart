import 'package:flutter/foundation.dart' hide Category;
import '../../data/local/preferences/app_preferences.dart';
import '../../data/models/public_deck.dart';
import '../../data/models/public_flashcard.dart';
import '../../data/models/public_profile.dart';
import '../../data/models/deck_rating.dart';
import '../../data/models/category.dart';
import '../../data/models/deck.dart';
import '../../data/repositories/public_library_repository.dart';
import '../../data/remote/mongo/mongo_public_library_service.dart';

LibrarySortBy _parseLibrarySortBy(String value) {
  return LibrarySortBy.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LibrarySortBy.popular,
  );
}

/// Provider for public library browsing, searching, and importing
class PublicLibraryProvider extends ChangeNotifier {
  final PublicLibraryRepository _repository = PublicLibraryRepository();
  final AppPreferences? _preferences;

  PublicLibraryProvider({AppPreferences? preferences})
      : _preferences = preferences {
    _loadSavedFilters();
  }

  void _loadSavedFilters() {
    if (_preferences == null) return;
    _filter = LibraryFilter(
      categoryId: _preferences.libFilterCategory,
      sourceLanguage: _preferences.libFilterSourceLang,
      sortBy: _parseLibrarySortBy(_preferences.libFilterSortBy),
    );
  }

  void _saveFilters() {
    if (_preferences == null) return;
    _preferences.setLibFilterCategory(_filter.categoryId);
    _preferences.setLibFilterSourceLang(_filter.sourceLanguage);
    _preferences.setLibFilterSortBy(_filter.sortBy.name);
  }

  /// The public library is backed by the Alpha Studio REST API.
  bool get isRemoteLibraryAvailable => true;

  // State
  List<PublicDeck> _decks = [];
  List<PublicDeck> _featuredDecks = [];
  List<PublicDeck> _topRatedDecks = [];
  List<PublicDeck> _newestDecks = [];
  List<Category> _categories = [];
  final Map<String, PublicProfile?> _authorProfiles = {};
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

  // Image download progress
  int _imageDownloadCompleted = 0;
  int _imageDownloadTotal = 0;

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
  int get imageDownloadCompleted => _imageDownloadCompleted;
  int get imageDownloadTotal => _imageDownloadTotal;

  /// Initialize the library (load categories and featured decks)
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await loadCategories();
      await loadNewestDecks();
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
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  /// Load featured decks
  Future<void> loadFeaturedDecks() async {
    try {
      _featuredDecks = await _repository.getFeaturedDecks();
    } catch (e) {
      debugPrint('Error loading featured decks: $e');
    }
  }

  /// Load top rated decks
  Future<void> loadTopRatedDecks() async {
    try {
      _topRatedDecks = await _repository.getTopRatedDecks();
    } catch (e) {
      debugPrint('Error loading top rated decks: $e');
    }
  }

  bool _hasMoreNewestDecks = true;
  bool get hasMoreNewestDecks => _hasMoreNewestDecks;

  /// Load newest decks
  Future<void> loadNewestDecks({bool refresh = false}) async {
    if (refresh) {
      _newestDecks = [];
      _hasMoreNewestDecks = true;
    }

    if (!_hasMoreNewestDecks && !refresh) return;

    _isLoading = refresh || _newestDecks.isEmpty;
    _isLoadingMore = !refresh && _newestDecks.isNotEmpty;
    notifyListeners();

    try {
      final offset = refresh ? 0 : _newestDecks.length;
      final newDecks = await _repository.getNewestDecks(limit: 20, offset: offset);
      
      if (refresh) {
        _newestDecks = newDecks;
      } else {
        final existingIds = _newestDecks.map((d) => d.id).toSet();
        final filteredNewDecks = newDecks.where((d) => !existingIds.contains(d.id)).toList();
        if (filteredNewDecks.isEmpty && newDecks.isNotEmpty) {
          _hasMoreNewestDecks = false;
        } else {
          _newestDecks = [..._newestDecks, ...filteredNewDecks];
        }
      }
      
      _hasMoreNewestDecks = _hasMoreNewestDecks && newDecks.length >= 20;
      _prefetchAuthorProfiles(newDecks);
    } catch (e) {
      debugPrint('Error loading newest decks: $e');
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Browse decks with current filter
  Future<void> browse({bool refresh = false}) async {
    debugPrint('[PublicLibraryProvider] browse called. refresh=$refresh, hasMoreDecks=$_hasMoreDecks, currentDecksLength=${_decks.length}');
    if (refresh) {
      _decks = [];
      _hasMoreDecks = true;
    }

    if (!_hasMoreDecks && !refresh) {
      debugPrint('[PublicLibraryProvider] browse aborted: no more decks and not refreshing');
      return;
    }

    _isLoading = refresh || _decks.isEmpty;
    _isLoadingMore = !refresh && _decks.isNotEmpty;
    _error = null;
    notifyListeners();

    try {
      final offset = refresh ? 0 : _decks.length;
      debugPrint('[PublicLibraryProvider] browse requesting API: limit=20, offset=$offset, filter=$_filter');
      final newDecks = await _repository.browse(
        filter: _filter,
        limit: 20,
        offset: offset,
      );
      debugPrint('[PublicLibraryProvider] browse received ${newDecks.length} decks from API');

      if (refresh) {
        _decks = newDecks;
      } else {
        final existingIds = _decks.map((d) => d.id).toSet();
        final filteredNewDecks = newDecks.where((d) => !existingIds.contains(d.id)).toList();
        debugPrint('[PublicLibraryProvider] browse filtered new decks: ${filteredNewDecks.length} (after removing ${newDecks.length - filteredNewDecks.length} duplicates)');
        if (filteredNewDecks.isEmpty && newDecks.isNotEmpty) {
          debugPrint('[PublicLibraryProvider] browse: all new decks were duplicates, setting hasMoreDecks=false');
          _hasMoreDecks = false;
        } else {
          _decks = [..._decks, ...filteredNewDecks];
        }
      }

      _hasMoreDecks = _hasMoreDecks && newDecks.length >= 20;
      debugPrint('[PublicLibraryProvider] browse completed. totalDecks=${_decks.length}, hasMoreDecks=$_hasMoreDecks');
      // Prefetch author profiles in background
      _prefetchAuthorProfiles(_decks);
    } catch (e) {
      debugPrint('[PublicLibraryProvider] browse error: $e');
      _error = e.toString();
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Search decks
  Future<void> search(String query, {bool refresh = false}) async {
    debugPrint('[PublicLibraryProvider] search("$query") called');
    
    if (query != _searchQuery) {
      refresh = true;
    }
    _searchQuery = query;

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
      if (query.isEmpty) {
        debugPrint('[PublicLibraryProvider] search: empty query, calling browse()');
        await browse(refresh: true);
        } else {
          debugPrint('[PublicLibraryProvider] search: calling repository.search("$query")');
          final offset = refresh ? 0 : _decks.length;
          final newDecks = await _repository.search(query, limit: 20, offset: offset);
          
          if (refresh) {
            _decks = newDecks;
          } else {
            final existingIds = _decks.map((d) => d.id).toSet();
            final filteredNewDecks = newDecks.where((d) => !existingIds.contains(d.id)).toList();
            if (filteredNewDecks.isEmpty && newDecks.isNotEmpty) {
              _hasMoreDecks = false;
            } else {
              _decks = [..._decks, ...filteredNewDecks];
            }
          }
          
          _hasMoreDecks = _hasMoreDecks && newDecks.length >= 20;
        debugPrint('[PublicLibraryProvider] search: got ${newDecks.length} results, total: ${_decks.length}');
        // Prefetch author profiles in background
        _prefetchAuthorProfiles(newDecks);
      }
    } catch (e, stackTrace) {
      debugPrint('[PublicLibraryProvider] search ERROR: $e');
      debugPrint('[PublicLibraryProvider] search stack: $stackTrace');
      _error = e.toString();
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Update filter
  void setFilter(LibraryFilter newFilter) {
    _filter = newFilter;
    _saveFilters();
    browse(refresh: true);
  }

  /// Set category filter
  void setCategory(String? categoryId) {
    _filter = _filter.copyWith(categoryId: categoryId);
    _saveFilters();
    browse(refresh: true);
  }

  /// Set language filter
  void setLanguages({String? source, String? target}) {
    _filter = _filter.copyWith(
      sourceLanguage: source,
      targetLanguage: target,
    );
    _saveFilters();
    browse(refresh: true);
  }

  /// Set sort order
  void setSortBy(LibrarySortBy sortBy) {
    _filter = _filter.copyWith(sortBy: sortBy);
    _saveFilters();
    browse(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _filter = const LibraryFilter();
    _searchQuery = '';
    _saveFilters();
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
        _repository.getPublicFlashcards(deckId, limit: 50), // Only fetch 50 for preview
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
    _imageDownloadCompleted = 0;
    _imageDownloadTotal = 0;
    notifyListeners();

    try {
      final deck = await _repository.importDeck(
        publicDeckId,
        onImageProgress: (completed, total, failed) {
          _imageDownloadCompleted = completed;
          _imageDownloadTotal = total;
          notifyListeners();
        },
      );
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
  Future<void> rateDeck(int rating, {String? review, String? nickname}) async {
    if (_selectedDeck == null) return;

    try {
      _userRating = await _repository.rateDeck(
        publicDeckId: _selectedDeck!.id,
        rating: rating,
        review: review,
        nickname: nickname,
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

  // ===== Author Profiles =====

  /// Get cached author profile (sync, for UI)
  PublicProfile? getCachedAuthorProfile(String authorId) {
    return _authorProfiles[authorId];
  }

  /// Fetch and cache an author profile
  Future<PublicProfile?> getAuthorProfile(String authorId) async {
    if (_authorProfiles.containsKey(authorId)) {
      return _authorProfiles[authorId];
    }
    try {
      final profile = await _repository.getAuthorProfile(authorId);
      _authorProfiles[authorId] = profile;
      return profile;
    } catch (e) {
      debugPrint('PublicLibraryProvider: getAuthorProfile error: $e');
      return null;
    }
  }

  /// Prefetch author profiles for a list of decks
  Future<void> _prefetchAuthorProfiles(List<PublicDeck> decks) async {
    final uniqueIds = decks
        .map((d) => d.authorId)
        .where((id) => id.isNotEmpty && !_authorProfiles.containsKey(id))
        .toSet();

    if (uniqueIds.isEmpty) return;

    await Future.wait(
      uniqueIds.map((id) => getAuthorProfile(id)),
    );
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
