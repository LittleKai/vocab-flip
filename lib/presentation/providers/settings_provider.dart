import 'package:flutter/foundation.dart';
import '../../data/local/preferences/app_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final AppPreferences _preferences;

  bool _isDarkMode = false;
  String _locale = 'vi';
  bool _autoSync = false;
  int _newCardsPerDay = 20;
  int _reviewCardsPerDay = 100;
  bool _showPhonetic = true;
  bool _autoPlayAudio = false;
  int _streak = 0;
  int _totalStudyTime = 0;
  int _flashcardImageMaxWidth = AppPreferences.defaultFlashcardImageMaxWidth;
  int _flashcardMainFontSize = AppPreferences.defaultMainFontSize;
  int _flashcardPhoneticFontSize = AppPreferences.defaultPhoneticFontSize;
  int _flashcardDetailFontSize = AppPreferences.defaultDetailFontSize;

  SettingsProvider({AppPreferences? preferences})
      : _preferences = preferences ?? AppPreferences();

  /// Expose preferences for other providers that need it
  AppPreferences get preferences => _preferences;

  bool get isDarkMode => _isDarkMode;
  String get locale => _locale;
  bool get autoSync => _autoSync;
  int get newCardsPerDay => _newCardsPerDay;
  int get reviewCardsPerDay => _reviewCardsPerDay;
  bool get showPhonetic => _showPhonetic;
  bool get autoPlayAudio => _autoPlayAudio;
  int get streak => _streak;
  int get totalStudyTime => _totalStudyTime;
  int get flashcardImageMaxWidth => _flashcardImageMaxWidth;
  int get flashcardMainFontSize => _flashcardMainFontSize;
  int get flashcardPhoneticFontSize => _flashcardPhoneticFontSize;
  int get flashcardDetailFontSize => _flashcardDetailFontSize;

  String get formattedStudyTime {
    final hours = _totalStudyTime ~/ 3600;
    final minutes = (_totalStudyTime % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Future<void> loadSettings() async {
    await _preferences.init();

    _isDarkMode = _preferences.isDarkMode;
    _locale = _preferences.locale;
    _autoSync = _preferences.autoSync;
    _newCardsPerDay = _preferences.newCardsPerDay;
    _reviewCardsPerDay = _preferences.reviewCardsPerDay;
    _showPhonetic = _preferences.showPhonetic;
    _autoPlayAudio = _preferences.autoPlayAudio;
    _streak = _preferences.streak;
    _totalStudyTime = _preferences.totalStudyTime;
    _flashcardImageMaxWidth = _preferences.flashcardImageMaxWidth;
    _flashcardMainFontSize = _preferences.flashcardMainFontSize;
    _flashcardPhoneticFontSize = _preferences.flashcardPhoneticFontSize;
    _flashcardDetailFontSize = _preferences.flashcardDetailFontSize;

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _preferences.setDarkMode(value);
    notifyListeners();
  }

  Future<void> setLocale(String value) async {
    _locale = value;
    await _preferences.setLocale(value);
    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _preferences.setAutoSync(value);
    notifyListeners();
  }

  Future<void> setNewCardsPerDay(int value) async {
    _newCardsPerDay = value;
    await _preferences.setNewCardsPerDay(value);
    notifyListeners();
  }

  Future<void> setReviewCardsPerDay(int value) async {
    _reviewCardsPerDay = value;
    await _preferences.setReviewCardsPerDay(value);
    notifyListeners();
  }

  Future<void> setShowPhonetic(bool value) async {
    _showPhonetic = value;
    await _preferences.setShowPhonetic(value);
    notifyListeners();
  }

  Future<void> setAutoPlayAudio(bool value) async {
    _autoPlayAudio = value;
    await _preferences.setAutoPlayAudio(value);
    notifyListeners();
  }

  Future<void> setFlashcardImageMaxWidth(int value) async {
    _flashcardImageMaxWidth = value;
    await _preferences.setFlashcardImageMaxWidth(value);
    notifyListeners();
  }

  Future<void> setFlashcardMainFontSize(int value) async {
    _flashcardMainFontSize = value;
    await _preferences.setFlashcardMainFontSize(value);
    notifyListeners();
  }

  Future<void> setFlashcardPhoneticFontSize(int value) async {
    _flashcardPhoneticFontSize = value;
    await _preferences.setFlashcardPhoneticFontSize(value);
    notifyListeners();
  }

  Future<void> setFlashcardDetailFontSize(int value) async {
    _flashcardDetailFontSize = value;
    await _preferences.setFlashcardDetailFontSize(value);
    notifyListeners();
  }

  void refreshStats() {
    _streak = _preferences.streak;
    _totalStudyTime = _preferences.totalStudyTime;
    notifyListeners();
  }
}
