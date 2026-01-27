import 'package:flutter/foundation.dart';
import '../../data/models/dictionary_result.dart';
import '../../data/repositories/dictionary_repository.dart';
import '../../core/constants/supported_languages.dart';

class DictionaryProvider extends ChangeNotifier {
  final DictionaryRepository _repository;

  DictionaryResult? _result;
  List<DictionaryResult> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  SupportedLanguage _selectedLanguage = SupportedLanguage.english;

  DictionaryProvider({DictionaryRepository? repository})
      : _repository = repository ?? DictionaryRepository();

  DictionaryResult? get result => _result;
  List<DictionaryResult> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SupportedLanguage get selectedLanguage => _selectedLanguage;

  void setLanguage(SupportedLanguage language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  Future<void> lookup(String word) async {
    if (word.trim().isEmpty) {
      _error = 'Please enter a word';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.lookup(word.trim(), _selectedLanguage);
      if (_result == null) {
        _error = 'No results found for "$word"';
      }
    } catch (e) {
      _error = 'Failed to lookup word: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _repository.search(query.trim(), _selectedLanguage);
    } catch (e) {
      _error = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _result = null;
    _searchResults = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
