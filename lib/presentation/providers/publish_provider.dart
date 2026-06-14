import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/public_deck.dart';
import '../../data/models/category.dart';
import '../../data/repositories/public_library_repository.dart';

/// State for publish process
enum PublishState {
  idle,
  loading,
  publishing,
  uploadingImages,
  success,
  error,
}

/// Provider for publishing decks to the public library
class PublishProvider extends ChangeNotifier {
  final PublicLibraryRepository _repository = PublicLibraryRepository();

  // State
  PublishState _state = PublishState.idle;
  List<PublicDeck> _myPublishedDecks = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  List<String> _selectedTags = [];
  String? _error;
  PublicDeck? _lastPublishedDeck;

  // Image upload progress
  int _imageUploadCompleted = 0;
  int _imageUploadTotal = 0;
  int _imageUploadFailed = 0;

  bool _hasLoadedMyDecks = false;

  // Getters
  PublishState get state => _state;
  List<PublicDeck> get myPublishedDecks => _myPublishedDecks;
  bool get hasLoadedMyDecks => _hasLoadedMyDecks;
  List<Category> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  List<String> get selectedTags => _selectedTags;
  String? get error => _error;
  PublicDeck? get lastPublishedDeck => _lastPublishedDeck;
  bool get isLoading => _state == PublishState.loading;
  bool get isPublishing => _state == PublishState.publishing || _state == PublishState.uploadingImages;
  int get imageUploadCompleted => _imageUploadCompleted;
  int get imageUploadTotal => _imageUploadTotal;
  int get imageUploadFailed => _imageUploadFailed;
  bool get isUploadingImages => _state == PublishState.uploadingImages;

  /// Initialize publish provider
  Future<void> initialize() async {
    _state = PublishState.loading;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadCategories(),
        loadMyPublishedDecks(),
      ]);
      _state = PublishState.idle;
    } catch (e) {
      _error = e.toString();
      _state = PublishState.error;
    }

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

  /// Load user's published decks
  Future<void> loadMyPublishedDecks() async {
    try {
      _myPublishedDecks = await _repository.getMyPublishedDecks();
      _hasLoadedMyDecks = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading published decks: $e');
    }
  }

  /// Set selected category
  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Add a tag
  void addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      _selectedTags = [..._selectedTags, tag];
      notifyListeners();
    }
  }

  /// Remove a tag
  void removeTag(String tag) {
    _selectedTags = _selectedTags.where((t) => t != tag).toList();
    notifyListeners();
  }

  /// Clear all tags
  void clearTags() {
    _selectedTags = [];
    notifyListeners();
  }

  /// Reset publish form
  void resetForm() {
    _selectedCategoryId = null;
    _selectedTags = [];
    _error = null;
    _lastPublishedDeck = null;
    _state = PublishState.idle;
    notifyListeners();
  }

  /// Publish a deck to the library
  Future<bool> publishDeck(String localDeckId, {String? authorName}) async {
    if (_selectedCategoryId == null) {
      _error = 'Please select a category';
      notifyListeners();
      return false;
    }

    _state = PublishState.uploadingImages;
    _error = null;
    _imageUploadCompleted = 0;
    _imageUploadTotal = 0;
    _imageUploadFailed = 0;
    notifyListeners();

    try {
      _lastPublishedDeck = await _repository.publishDeck(
        localDeckId: localDeckId,
        categoryId: _selectedCategoryId!,
        tags: _selectedTags,
        authorName: authorName,
        onImageProgress: (completed, total, failed) {
          _imageUploadCompleted = completed;
          _imageUploadTotal = total;
          _imageUploadFailed = failed;
          _state = PublishState.uploadingImages;
          notifyListeners();
        },
      );

      _state = PublishState.publishing;
      notifyListeners();

      // Refresh published decks list
      await loadMyPublishedDecks();

      _state = PublishState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _state = PublishState.error;
      notifyListeners();
      return false;
    }
  }

  /// Update a published deck
  Future<bool> updatePublishedDeck(String localDeckId) async {
    _state = PublishState.uploadingImages;
    _error = null;
    _imageUploadCompleted = 0;
    _imageUploadTotal = 0;
    _imageUploadFailed = 0;
    notifyListeners();

    try {
      await _repository.updatePublishedDeck(
        localDeckId: localDeckId,
        categoryId: _selectedCategoryId,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        onImageProgress: (completed, total, failed) {
          _imageUploadCompleted = completed;
          _imageUploadTotal = total;
          _imageUploadFailed = failed;
          _state = PublishState.uploadingImages;
          notifyListeners();
        },
      );

      // Refresh published decks list
      await loadMyPublishedDecks();

      _state = PublishState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _state = PublishState.error;
      notifyListeners();
      return false;
    }
  }

  /// Unpublish a deck by local deck ID
  Future<bool> unpublishDeck(String localDeckId) async {
    _state = PublishState.loading;
    _error = null;
    notifyListeners();

    try {
      await _repository.unpublishDeck(localDeckId);

      // Refresh published decks list
      await loadMyPublishedDecks();

      _state = PublishState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _state = PublishState.error;
      notifyListeners();
      return false;
    }
  }

  /// Unpublish a deck by public deck ID (used from library screen)
  Future<bool> unpublishByPublicId(String publicDeckId) async {
    _state = PublishState.loading;
    _error = null;
    notifyListeners();

    try {
      await _repository.unpublishByPublicId(publicDeckId);

      // Refresh published decks list
      await loadMyPublishedDecks();

      _state = PublishState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Unpublish error: $e');
      _error = e.toString();
      _state = PublishState.error;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
