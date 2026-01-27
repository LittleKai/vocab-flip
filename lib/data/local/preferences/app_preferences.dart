import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLocale = 'locale';
  static const String _keyAutoSync = 'auto_sync';
  static const String _keyNewCardsPerDay = 'new_cards_per_day';
  static const String _keyReviewCardsPerDay = 'review_cards_per_day';
  static const String _keyShowPhonetic = 'show_phonetic';
  static const String _keyAutoPlayAudio = 'auto_play_audio';
  static const String _keyLastBackup = 'last_backup';
  static const String _keyStreak = 'streak';
  static const String _keyLastStudyDate = 'last_study_date';
  static const String _keyTotalStudyTime = 'total_study_time';
  static const String _keyUserId = 'user_id';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Dark mode
  bool get isDarkMode => _prefs.getBool(_keyDarkMode) ?? false;
  Future<bool> setDarkMode(bool value) => _prefs.setBool(_keyDarkMode, value);

  // Locale
  String get locale => _prefs.getString(_keyLocale) ?? 'vi';
  Future<bool> setLocale(String value) => _prefs.setString(_keyLocale, value);

  // Auto sync
  bool get autoSync => _prefs.getBool(_keyAutoSync) ?? false;
  Future<bool> setAutoSync(bool value) => _prefs.setBool(_keyAutoSync, value);

  // New cards per day
  int get newCardsPerDay => _prefs.getInt(_keyNewCardsPerDay) ?? 20;
  Future<bool> setNewCardsPerDay(int value) => _prefs.setInt(_keyNewCardsPerDay, value);

  // Review cards per day
  int get reviewCardsPerDay => _prefs.getInt(_keyReviewCardsPerDay) ?? 100;
  Future<bool> setReviewCardsPerDay(int value) => _prefs.setInt(_keyReviewCardsPerDay, value);

  // Show phonetic
  bool get showPhonetic => _prefs.getBool(_keyShowPhonetic) ?? true;
  Future<bool> setShowPhonetic(bool value) => _prefs.setBool(_keyShowPhonetic, value);

  // Auto play audio
  bool get autoPlayAudio => _prefs.getBool(_keyAutoPlayAudio) ?? false;
  Future<bool> setAutoPlayAudio(bool value) => _prefs.setBool(_keyAutoPlayAudio, value);

  // Last backup
  DateTime? get lastBackup {
    final timestamp = _prefs.getString(_keyLastBackup);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  Future<bool> setLastBackup(DateTime value) =>
      _prefs.setString(_keyLastBackup, value.toIso8601String());

  // Streak
  int get streak => _prefs.getInt(_keyStreak) ?? 0;
  Future<bool> setStreak(int value) => _prefs.setInt(_keyStreak, value);

  // Last study date
  String? get lastStudyDate => _prefs.getString(_keyLastStudyDate);
  Future<bool> setLastStudyDate(String value) => _prefs.setString(_keyLastStudyDate, value);

  // Total study time in seconds
  int get totalStudyTime => _prefs.getInt(_keyTotalStudyTime) ?? 0;
  Future<bool> setTotalStudyTime(int value) => _prefs.setInt(_keyTotalStudyTime, value);
  Future<bool> addStudyTime(int seconds) => setTotalStudyTime(totalStudyTime + seconds);

  // User ID
  String? get userId => _prefs.getString(_keyUserId);
  Future<bool> setUserId(String? value) {
    if (value == null) {
      return _prefs.remove(_keyUserId);
    }
    return _prefs.setString(_keyUserId, value);
  }

  // Update streak
  Future<void> updateStreak() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final lastDate = lastStudyDate;

    if (lastDate == today) {
      // Already studied today
      return;
    }

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;

    if (lastDate == yesterday) {
      // Studied yesterday, increment streak
      await setStreak(streak + 1);
    } else {
      // Streak broken, reset to 1
      await setStreak(1);
    }

    await setLastStudyDate(today);
  }

  // Clear all preferences
  Future<bool> clear() => _prefs.clear();
}
