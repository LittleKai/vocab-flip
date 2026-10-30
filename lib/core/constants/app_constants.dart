class AppConstants {
  AppConstants._();

  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'vocabflip.db';
  static const int databaseVersion = 13;

  // Tables
  static const String tableDecks = 'decks';
  static const String tableFlashcards = 'flashcards';
  static const String tableStudySessions = 'study_sessions';
  static const String tableReviewLogs = 'review_logs';
  static const String tableImportedDeckLinks = 'imported_deck_links';

  // SM-2 Algorithm defaults
  static const double defaultEasinessFactor = 2.5;
  static const double minEasinessFactor = 1.3;
  static const int initialInterval = 1;
  static const int secondInterval = 6;

  // Rating thresholds
  static const int ratingAgain = 0;
  static const int ratingHard = 3;
  static const int ratingGood = 4;
  static const int ratingEasy = 5;

  // Animation durations
  static const Duration flipDuration = Duration(milliseconds: 400);

  // Export/Import
  static const String exportVersion = '1.0';
}
