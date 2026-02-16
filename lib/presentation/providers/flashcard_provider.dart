import 'package:flutter/foundation.dart';
import '../../data/models/flashcard.dart';
import '../../data/repositories/flashcard_repository.dart';
import '../../core/utils/spaced_repetition.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardRepository _repository;

  List<Flashcard> _flashcards = [];
  List<Flashcard> _dueFlashcards = [];
  Flashcard? _selectedFlashcard;
  bool _isLoading = false;
  String? _error;
  String? _currentDeckId;

  FlashcardProvider({FlashcardRepository? repository})
      : _repository = repository ?? FlashcardRepository();

  List<Flashcard> get flashcards => _flashcards;
  List<Flashcard> get dueFlashcards => _dueFlashcards;
  Flashcard? get selectedFlashcard => _selectedFlashcard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentDeckId => _currentDeckId;

  int get totalCards => _flashcards.length;
  int get newCards => _flashcards.where((c) => c.isNew).length;
  int get learningCards => _flashcards.where((c) => c.isLearning).length;
  int get graduatedCards => _flashcards.where((c) => c.isGraduated).length;
  int get dueCount => _dueFlashcards.length;

  Future<void> loadFlashcards(String deckId) async {
    _isLoading = true;
    _error = null;
    _currentDeckId = deckId;
    notifyListeners();

    try {
      _flashcards = await _repository.getFlashcardsByDeckId(deckId);
      _dueFlashcards = await _repository.getDueFlashcards(deckId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDueFlashcards(String deckId, {int? limit}) async {
    try {
      _dueFlashcards = await _repository.getDueFlashcards(deckId, limit: limit);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void selectFlashcard(Flashcard flashcard) {
    _selectedFlashcard = flashcard;
    notifyListeners();
  }

  void clearSelectedFlashcard() {
    _selectedFlashcard = null;
    notifyListeners();
  }

  Future<void> createFlashcard(Flashcard flashcard) async {
    try {
      await _repository.createFlashcard(flashcard);
      if (_currentDeckId != null) {
        await loadFlashcards(_currentDeckId!);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    try {
      await _repository.updateFlashcard(flashcard);
      if (_currentDeckId != null) {
        await loadFlashcards(_currentDeckId!);
      }
      if (_selectedFlashcard?.id == flashcard.id) {
        _selectedFlashcard = flashcard;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteFlashcard(String id) async {
    try {
      await _repository.deleteFlashcard(id);
      if (_selectedFlashcard?.id == id) {
        _selectedFlashcard = null;
      }
      if (_currentDeckId != null) {
        await loadFlashcards(_currentDeckId!);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Flashcard> reviewFlashcard(Flashcard flashcard, ReviewRating rating) async {
    final updated = await _repository.reviewFlashcard(flashcard, rating);

    // Update local lists
    final index = _flashcards.indexWhere((c) => c.id == flashcard.id);
    if (index != -1) {
      _flashcards[index] = updated;
    }

    _dueFlashcards.removeWhere((c) => c.id == flashcard.id);

    notifyListeners();
    return updated;
  }

  Future<List<Flashcard>> searchFlashcards(String query, {String? deckId}) async {
    return await _repository.searchFlashcards(query, deckId: deckId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set flashcards directly (for online browsing without DB)
  void setFlashcards(List<Flashcard> cards, {String? deckId}) {
    _flashcards = cards;
    _dueFlashcards = [];
    _currentDeckId = deckId;
    notifyListeners();
  }

  /// Reorder flashcards in the list (local only, UI ordering)
  void reorderFlashcards(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _flashcards.removeAt(oldIndex);
    _flashcards.insert(newIndex, item);
    notifyListeners();
  }

  /// Shuffle flashcards randomly (local only, UI ordering)
  void shuffleFlashcards() {
    _flashcards.shuffle();
    notifyListeners();
  }

  void reset() {
    _flashcards = [];
    _dueFlashcards = [];
    _selectedFlashcard = null;
    _currentDeckId = null;
    _error = null;
    notifyListeners();
  }
}
