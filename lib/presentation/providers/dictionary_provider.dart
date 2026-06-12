import 'package:flutter/foundation.dart';
import '../../data/models/dictionary_result.dart';
import '../../data/repositories/dictionary_repository.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../core/constants/supported_languages.dart';

class DictionaryProvider extends ChangeNotifier {
  final DictionaryRepository _repository;
  final AppPreferences _prefs;

  List<DictionaryResult> _results = [];
  bool _isLoading = false;
  String? _error;
  SupportedLanguage _selectedLanguage = SupportedLanguage.english;
  String _filterMode = 'exact_first';
  String _fetchMode = 'both';
  bool _fallbackToEnglish = true;
  bool _usedFallback = false;
  String? _fallbackSource;

  DictionaryProvider({
    DictionaryRepository? repository,
    required AppPreferences prefs,
  })  : _repository = repository ?? DictionaryRepository(),
        _prefs = prefs {
    _loadSavedSettings();
  }

  void _loadSavedSettings() {
    _selectedLanguage = SupportedLanguage.fromCode(_prefs.dictionarySourceLanguage);
    _filterMode = _prefs.dictionaryFilterMode;
    _fetchMode = _prefs.dictionaryFetchMode;
    _fallbackToEnglish = _prefs.dictionaryFallbackToEnglish;
  }

  List<DictionaryResult> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SupportedLanguage get selectedLanguage => _selectedLanguage;
  String get filterMode => _filterMode;
  String get fetchMode => _fetchMode;
  bool get fallbackToEnglish => _fallbackToEnglish;
  bool get usedFallback => _usedFallback;
  String? get fallbackSource => _fallbackSource;

  void setLanguage(SupportedLanguage language) {
    _selectedLanguage = language;
    _prefs.setDictionarySourceLanguage(language.code);
    notifyListeners();
  }

  void setFilterMode(String mode) {
    _filterMode = mode;
    _prefs.setDictionaryFilterMode(mode);
    notifyListeners();
  }

  void setFetchMode(String mode) {
    _fetchMode = mode;
    _prefs.setDictionaryFetchMode(mode);
    notifyListeners();
  }

  void setFallbackToEnglish(bool value) {
    _fallbackToEnglish = value;
    _prefs.setDictionaryFallbackToEnglish(value);
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
    _results = [];
    _usedFallback = false;
    _fallbackSource = null;
    notifyListeners();

    try {
      final lookupResult = await _repository.lookupAll(
        word.trim(),
        _selectedLanguage,
        fallbackToEnglish: _fallbackToEnglish,
        fetchMode: _fetchMode,
      );
      _results = lookupResult.results;
      _usedFallback = lookupResult.usedFallback;
      _fallbackSource = lookupResult.fallbackSource;
      if (_results.isEmpty) {
        _error = 'No results found for "$word"';
      }
    } catch (e) {
      _error = 'Failed to lookup word: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _results = [];
    _error = null;
    _usedFallback = false;
    _fallbackSource = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Search for Kanji suggestions based on hiragana/katakana input
  Future<List<String>> searchKanjiSuggestions(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return [];

    try {
      final results = await _repository.searchKanjiSuggestions(query.trim(), limit: limit);
      return results;
    } catch (e) {
      debugPrint('Kanji suggestion error: $e');
      return [];
    }
  }
}
