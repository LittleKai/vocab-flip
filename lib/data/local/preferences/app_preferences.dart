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
  static const String _keyDictionaryFetchMode = 'dictionary_fetch_mode';
  static const String _keyDictionaryFallbackToEnglish = 'dictionary_fallback_to_english';
  static const String _keyFlashcardMainFontSize = 'flashcard_main_font_size';
  static const String _keyFlashcardPhoneticFontSize = 'flashcard_phonetic_font_size';
  static const String _keyFlashcardDetailFontSize = 'flashcard_detail_font_size';
  static const String _keyHideTtsWarning = 'hide_tts_warning';
  static const String _keyLastUpdateCheck = 'last_update_check';
  static const String _keySkippedVersion = 'skipped_version';
  static const String _keyAutoCheckUpdates = 'auto_check_updates';
  static const String _keyAdvancedLearningScience = 'advanced_learning_science';
  static const String _keyLastSyncCursor = 'last_sync_cursor';

  // Deck list filter
  static const String _keyDeckFilterCategory = 'deck_filter_category';
  static const String _keyDeckFilterLanguage = 'deck_filter_language';
  static const String _keyDeckFilterSortBy = 'deck_filter_sort_by';

  static const String _keyTtsVolume = 'tts_volume';

  // Library filter
  static const String _keyLibFilterCategory = 'lib_filter_category';
  static const String _keyLibFilterSourceLang = 'lib_filter_source_lang';
  static const String _keyLibFilterSortBy = 'lib_filter_sort_by';

  // User profile
  static const String _keyProfileNickname = 'profile_nickname';
  static const String _keyProfileGender = 'profile_gender';
  static const String _keyProfileAvatarIndex = 'profile_avatar_index';
  static const String _keyProfileCustomAvatarPath = 'profile_custom_avatar_path';
  static const String _keyProfileBio = 'profile_bio';
  static const String _keyProfileUpdatedAt = 'profile_updated_at';
  static const String _keyProfileCloudAvatarUrl = 'profile_cloud_avatar_url';
  static const String _keyAdminFeedbackLastRead = 'admin_feedback_last_read_at';

  // Default font sizes
  static int get defaultMainFontSize {
    if (kIsWeb) return 48;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return 48;
    return 32;
  }
  
  static int get defaultPhoneticFontSize {
    if (kIsWeb) return 28;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return 28;
    return 20;
  }
  
  static int get defaultDetailFontSize {
    if (kIsWeb) return 20;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return 20;
    return 16;
  }

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

  // Dictionary fetch mode: 'offline', 'online', 'both'
  // 1 = offline, 2 = both, 3 = online (or string values)
  String get dictionaryFetchMode =>
      _prefs.getString(_keyDictionaryFetchMode) ?? 'both';
  Future<bool> setDictionaryFetchMode(String value) =>
      _prefs.setString(_keyDictionaryFetchMode, value);

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

  // TTS Volume
  double get ttsVolume => _prefs.getDouble(_keyTtsVolume) ?? 1.0;
  Future<bool> setTtsVolume(double value) =>
      _prefs.setDouble(_keyTtsVolume, value);

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

  bool get advancedLearningScience => _prefs.getBool(_keyAdvancedLearningScience) ?? false;
  Future<bool> setAdvancedLearningScience(bool value) =>
      _prefs.setBool(_keyAdvancedLearningScience, value);

  // Last sync cursor
  DateTime? get lastSyncCursor {
    final timestamp = _prefs.getString(_keyLastSyncCursor);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  Future<bool> setLastSyncCursor(DateTime value) =>
      _prefs.setString(_keyLastSyncCursor, value.toIso8601String());

  // Deck list filter
  String? get deckFilterCategory => _prefs.getString(_keyDeckFilterCategory);
  Future<bool> setDeckFilterCategory(String? value) {
    if (value == null) return _prefs.remove(_keyDeckFilterCategory);
    return _prefs.setString(_keyDeckFilterCategory, value);
  }

  String? get deckFilterLanguage => _prefs.getString(_keyDeckFilterLanguage);
  Future<bool> setDeckFilterLanguage(String? value) {
    if (value == null) return _prefs.remove(_keyDeckFilterLanguage);
    return _prefs.setString(_keyDeckFilterLanguage, value);
  }

  String get deckFilterSortBy => _prefs.getString(_keyDeckFilterSortBy) ?? 'recentlyUpdated';
  Future<bool> setDeckFilterSortBy(String value) =>
      _prefs.setString(_keyDeckFilterSortBy, value);

  // Library filter
  String? get libFilterCategory => _prefs.getString(_keyLibFilterCategory);
  Future<bool> setLibFilterCategory(String? value) {
    if (value == null) return _prefs.remove(_keyLibFilterCategory);
    return _prefs.setString(_keyLibFilterCategory, value);
  }

  String? get libFilterSourceLang => _prefs.getString(_keyLibFilterSourceLang);
  Future<bool> setLibFilterSourceLang(String? value) {
    if (value == null) return _prefs.remove(_keyLibFilterSourceLang);
    return _prefs.setString(_keyLibFilterSourceLang, value);
  }

  String get libFilterSortBy => _prefs.getString(_keyLibFilterSortBy) ?? 'popular';
  Future<bool> setLibFilterSortBy(String value) =>
      _prefs.setString(_keyLibFilterSortBy, value);

  // User profile - nickname
  String? get profileNickname => _prefs.getString(_keyProfileNickname);
  Future<bool> setProfileNickname(String? value) {
    if (value == null || value.isEmpty) {
      return _prefs.remove(_keyProfileNickname);
    }
    return _prefs.setString(_keyProfileNickname, value);
  }

  // User profile - gender (stored as string)
  String get profileGender => _prefs.getString(_keyProfileGender) ?? 'preferNotToSay';
  Future<bool> setProfileGender(String value) =>
      _prefs.setString(_keyProfileGender, value);

  // User profile - avatar index
  int get profileAvatarIndex => _prefs.getInt(_keyProfileAvatarIndex) ?? 0;
  Future<bool> setProfileAvatarIndex(int value) =>
      _prefs.setInt(_keyProfileAvatarIndex, value);

  // User profile - custom avatar image path
  String? get profileCustomAvatarPath => _prefs.getString(_keyProfileCustomAvatarPath);
  Future<bool> setProfileCustomAvatarPath(String? value) {
    if (value == null || value.isEmpty) {
      return _prefs.remove(_keyProfileCustomAvatarPath);
    }
    return _prefs.setString(_keyProfileCustomAvatarPath, value);
  }

  // User profile - bio
  String? get profileBio => _prefs.getString(_keyProfileBio);
  Future<bool> setProfileBio(String? value) {
    if (value == null || value.isEmpty) {
      return _prefs.remove(_keyProfileBio);
    }
    return _prefs.setString(_keyProfileBio, value);
  }

  // User profile - cloud avatar URL (Cloudinary)
  String? get profileCloudAvatarUrl => _prefs.getString(_keyProfileCloudAvatarUrl);
  Future<bool> setProfileCloudAvatarUrl(String? value) {
    if (value == null || value.isEmpty) {
      return _prefs.remove(_keyProfileCloudAvatarUrl);
    }
    return _prefs.setString(_keyProfileCloudAvatarUrl, value);
  }

  // User profile - updated at
  DateTime? get profileUpdatedAt {
    final timestamp = _prefs.getString(_keyProfileUpdatedAt);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  Future<bool> setProfileUpdatedAt(DateTime value) =>
      _prefs.setString(_keyProfileUpdatedAt, value.toIso8601String());

  // Admin feedback last read
  DateTime? get adminFeedbackLastReadAt {
    final timestamp = _prefs.getString(_keyAdminFeedbackLastRead);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  Future<bool> setAdminFeedbackLastReadAt(DateTime value) =>
      _prefs.setString(_keyAdminFeedbackLastRead, value.toIso8601String());

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
