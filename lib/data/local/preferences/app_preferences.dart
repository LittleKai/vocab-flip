import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
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
  static const String _keyFlashcardImageMaxWidth = 'flashcard_image_max_width';
  static const String _keyDictionarySourceLanguage = 'dictionary_source_language';
  static const String _keyDictionaryFilterMode = 'dictionary_filter_mode';
  static const String _keyDictionaryFallbackToEnglish = 'dictionary_fallback_to_english';
  static const String _keyFlashcardMainFontSize = 'flashcard_main_font_size';
  static const String _keyFlashcardPhoneticFontSize = 'flashcard_phonetic_font_size';
  static const String _keyFlashcardDetailFontSize = 'flashcard_detail_font_size';
  static const String _keyHideTtsWarning = 'hide_tts_warning';
  static const String _keyLastUpdateCheck = 'last_update_check';
  static const String _keySkippedVersion = 'skipped_version';
  static const String _keyAutoCheckUpdates = 'auto_check_updates';

  // Default font sizes
  static const int defaultMainFontSize = 32;
  static const int defaultPhoneticFontSize = 20;
  static const int defaultDetailFontSize = 16;

  /// Default image max width based on platform
  static int get defaultFlashcardImageMaxWidth {
    if (kIsWeb) return 800;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 1000; // Desktop
    }
    return 600; // Mobile
  }

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

  // Flashcard image max width
  int get flashcardImageMaxWidth =>
      _prefs.getInt(_keyFlashcardImageMaxWidth) ?? defaultFlashcardImageMaxWidth;
  Future<bool> setFlashcardImageMaxWidth(int value) =>
      _prefs.setInt(_keyFlashcardImageMaxWidth, value);

  // Dictionary source language (en, ja, zh)
  String get dictionarySourceLanguage =>
      _prefs.getString(_keyDictionarySourceLanguage) ?? 'en';
  Future<bool> setDictionarySourceLanguage(String value) =>
      _prefs.setString(_keyDictionarySourceLanguage, value);

  // Dictionary filter mode: 'exact_first', 'with_meanings', 'all'
  // - exact_first: Prioritize exact match, then results with meanings
  // - with_meanings: Only show results that have meanings/definitions
  // - all: Show all results without filtering
  String get dictionaryFilterMode =>
      _prefs.getString(_keyDictionaryFilterMode) ?? 'exact_first';
  Future<bool> setDictionaryFilterMode(String value) =>
      _prefs.setString(_keyDictionaryFilterMode, value);

  // Whether to fallback to English dictionary if Vietnamese not found
  bool get dictionaryFallbackToEnglish =>
      _prefs.getBool(_keyDictionaryFallbackToEnglish) ?? true;
  Future<bool> setDictionaryFallbackToEnglish(bool value) =>
      _prefs.setBool(_keyDictionaryFallbackToEnglish, value);

  // Flashcard font sizes
  int get flashcardMainFontSize =>
      _prefs.getInt(_keyFlashcardMainFontSize) ?? defaultMainFontSize;
  Future<bool> setFlashcardMainFontSize(int value) =>
      _prefs.setInt(_keyFlashcardMainFontSize, value);

  int get flashcardPhoneticFontSize =>
      _prefs.getInt(_keyFlashcardPhoneticFontSize) ?? defaultPhoneticFontSize;
  Future<bool> setFlashcardPhoneticFontSize(int value) =>
      _prefs.setInt(_keyFlashcardPhoneticFontSize, value);

  int get flashcardDetailFontSize =>
      _prefs.getInt(_keyFlashcardDetailFontSize) ?? defaultDetailFontSize;
  Future<bool> setFlashcardDetailFontSize(int value) =>
      _prefs.setInt(_keyFlashcardDetailFontSize, value);

  // Hide TTS warning dialog
  bool get hideTtsWarning => _prefs.getBool(_keyHideTtsWarning) ?? false;
  Future<bool> setHideTtsWarning(bool value) =>
      _prefs.setBool(_keyHideTtsWarning, value);

  // Last update check
  DateTime? get lastUpdateCheck {
    final timestamp = _prefs.getString(_keyLastUpdateCheck);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  Future<bool> setLastUpdateCheck(DateTime value) =>
      _prefs.setString(_keyLastUpdateCheck, value.toIso8601String());

  // Skipped version
  String? get skippedVersion => _prefs.getString(_keySkippedVersion);
  Future<bool> setSkippedVersion(String value) =>
      _prefs.setString(_keySkippedVersion, value);

  // Auto check updates
  bool get autoCheckUpdates => _prefs.getBool(_keyAutoCheckUpdates) ?? true;
  Future<bool> setAutoCheckUpdates(bool value) =>
      _prefs.setBool(_keyAutoCheckUpdates, value);

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
