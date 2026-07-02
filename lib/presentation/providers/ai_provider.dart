import 'package:flutter/foundation.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/models/flashcard.dart';

enum AiState { idle, generating, success, error }

class AiProvider extends ChangeNotifier {
  final AiRepository _repository;

  AiProvider({AiRepository? repository})
      : _repository = repository ?? AiRepository();

  AiState _state = AiState.idle;
  AiState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Flashcard> _draftCards = [];
  List<Flashcard> get draftCards => _draftCards;

  int _freeUsesRemaining = 1;
  int get freeUsesRemaining => _freeUsesRemaining;

  int _creditBalance = 0;
  int get creditBalance => _creditBalance;

  bool _usageLoaded = false;

  String? _currentDeckId;
  String? get currentDeckId => _currentDeckId;

  Future<String?> generateMnemonic(String word, String language) async {
    _state = AiState.generating;
    _errorMessage = null;
    notifyListeners();

    try {
      final mnemonic = await _repository.generateMnemonic(word, language);
      _state = AiState.success;
      notifyListeners();
      return mnemonic;
    } catch (e) {
      _state = AiState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Load AI usage info (daily free use remaining + credit balance).
  Future<void> loadUsageInfo() async {
    if (_usageLoaded) return;
    try {
      final info = await _repository.getAiUsageInfo();
      _freeUsesRemaining = info['freeUsesRemaining'] as int;
      _creditBalance = info['creditBalance'] as int;
      _usageLoaded = true;
      notifyListeners();
    } catch (_) {
      // Keep defaults
    }
  }

  /// Force refresh usage info.
  Future<void> refreshUsageInfo() async {
    _usageLoaded = false;
    await loadUsageInfo();
  }

  /// Check if the user can generate with the default Gemini 3 Flash model.
  bool get canGenerate => _freeUsesRemaining > 0 || _creditBalance >= 5;

  /// Whether the default Gemini 3 Flash generation will cost credits.
  bool get willCostCredit => _freeUsesRemaining <= 0;

  /// Generate flashcards via AI with full options.
  Future<void> generateCards({
    required String prompt,
    required String sourceLanguage,
    required String targetLanguage,
    required int count,
    bool includeExamples = true,
    bool includeNotes = false,
    String? noteInstructions,
    String model = 'gemini-3-flash',
    String? deckId,
  }) async {
    _state = AiState.generating;
    _errorMessage = null;
    _draftCards = [];
    _currentDeckId = deckId;
    notifyListeners();

    try {
      final result = await _repository.generateCards(
        prompt: prompt,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        count: count,
        includeExamples: includeExamples,
        includeNotes: includeNotes,
        noteInstructions: noteInstructions,
        model: model,
      );

      _draftCards = result['cards'] as List<Flashcard>;
      _freeUsesRemaining = result['freeUsesRemaining'] as int;
      _creditBalance = result['creditBalance'] as int;
      _state = AiState.success;
      notifyListeners();
    } catch (e) {
      _state = AiState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void approveCard(Flashcard card) {
    _draftCards.remove(card);
    notifyListeners();
  }

  void rejectCard(Flashcard card) {
    _draftCards.remove(card);
    notifyListeners();
  }

  void reset() {
    _state = AiState.idle;
    _errorMessage = null;
    _draftCards = [];
    _currentDeckId = null;
    notifyListeners();
  }
}
