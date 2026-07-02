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
  bool _advancedLearningScience = false;
  int _streak = 0;
  int _totalStudyTime = 0;
  int _flashcardImageMaxWidth = AppPreferences.defaultFlashcardImageMaxWidth;
  int _flashcardMainFontSize = AppPreferences.defaultMainFontSize;
  int _flashcardPhoneticFontSize = AppPreferences.defaultPhoneticFontSize;
  int _flashcardDetailFontSize = AppPreferences.defaultDetailFontSize;
  String _deckClickAction = 'detail';
  String _appFontFamily = 'System';
  double _appTextScaleFactor = 1.0;
  double _ttsSpeechRate = AppPreferences.defaultTtsSpeechRate;

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
  bool get advancedLearningScience => _advancedLearningScience;
  int get streak => _streak;
  int get totalStudyTime => _totalStudyTime;
  int get flashcardImageMaxWidth => _flashcardImageMaxWidth;
  int get flashcardMainFontSize => _flashcardMainFontSize;
  int get flashcardPhoneticFontSize => _flashcardPhoneticFontSize;
  int get flashcardDetailFontSize => _flashcardDetailFontSize;
  String get deckClickAction => _deckClickAction;
  String get appFontFamily {
    if (_appFontFamily == 'Monospace') return 'Consolas';
    if (_appFontFamily == 'Serif') return 'Georgia';
    if (_appFontFamily == 'Sans-Serif') return 'Segoe UI';
    return _appFontFamily;
  }
  double get appTextScaleFactor => _appTextScaleFactor;
  double get ttsSpeechRate => _ttsSpeechRate;

  String getAppFontFamilyDisplayName(String localeCode) {
    final isVi = localeCode == 'vi';
    switch (_appFontFamily) {
      case 'System':
        return isVi ? 'Mặc định hệ thống' : 'System Default';
      case 'Segoe UI':
        return 'Segoe UI';
      case 'Arial':
        return 'Arial';
      case 'Trebuchet MS':
        return 'Trebuchet MS';
      case 'Georgia':
        return 'Georgia';
      case 'Times New Roman':
        return 'Times New Roman';
      case 'Consolas':
        return 'Consolas';
      case 'Courier New':
        return 'Courier New';
      case 'Comic Sans MS':
        return 'Comic Sans MS';
      case 'Impact':
        return 'Impact';
      // Fallbacks
      case 'Sans-Serif':
        return 'Segoe UI';
      case 'Serif':
        return 'Georgia';
      case 'Monospace':
        return 'Consolas';
      default:
        return _appFontFamily;
    }
  }

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
    _advancedLearningScience = _preferences.advancedLearningScience;
    _streak = _preferences.streak;
    _totalStudyTime = _preferences.totalStudyTime;
    _flashcardImageMaxWidth = _preferences.flashcardImageMaxWidth;
    _flashcardMainFontSize = _preferences.flashcardMainFontSize;
    _flashcardPhoneticFontSize = _preferences.flashcardPhoneticFontSize;
    _flashcardDetailFontSize = _preferences.flashcardDetailFontSize;
    _deckClickAction = _preferences.deckClickAction;
    final savedFont = _preferences.appFontFamily;
    if (savedFont == 'Monospace') {
      _appFontFamily = 'Consolas';
    } else if (savedFont == 'Serif') {
      _appFontFamily = 'Georgia';
    } else if (savedFont == 'Sans-Serif') {
      _appFontFamily = 'Segoe UI';
    } else {
      _appFontFamily = savedFont;
    }
    _appTextScaleFactor = _preferences.appTextScaleFactor;
    _ttsSpeechRate = _preferences.ttsSpeechRate;

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

  Future<void> setAdvancedLearningScience(bool value) async {
    _advancedLearningScience = value;
    await _preferences.setAdvancedLearningScience(value);
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

  Future<void> setDeckClickAction(String value) async {
    _deckClickAction = value;
    await _preferences.setDeckClickAction(value);
    notifyListeners();
  }

  Future<void> setAppFontFamily(String value) async {
    _appFontFamily = value;
    await _preferences.setAppFontFamily(value);
    notifyListeners();
  }

  Future<void> setAppTextScaleFactor(double value) async {
    _appTextScaleFactor = value;
    await _preferences.setAppTextScaleFactor(value);
    notifyListeners();
  }

  Future<void> setTtsSpeechRate(double value) async {
    _ttsSpeechRate = value;
    await _preferences.setTtsSpeechRate(value);
    notifyListeners();
  }

  void refreshStats() {
    _streak = _preferences.streak;
    _totalStudyTime = _preferences.totalStudyTime;
    notifyListeners();
  }
}
