import 'package:flutter/foundation.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/models/flashcard.dart';

enum AiState { idle, generating, success, error }

class AiProvider extends ChangeNotifier {
  final AiRepository _repository;

  AiProvider({AiRepository? repository}) : _repository = repository ?? AiRepository();

  AiState _state = AiState.idle;
  AiState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Flashcard> _draftCards = [];
  List<Flashcard> get draftCards => _draftCards;

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

  Future<void> generateDeck(String text, String language, String targetLanguage) async {
    _state = AiState.generating;
    _errorMessage = null;
    _draftCards = [];
    notifyListeners();

    try {
      _draftCards = await _repository.generateDeck(text, language, targetLanguage);
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
    notifyListeners();
  }
}
