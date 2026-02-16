class AppConstants {
  AppConstants._();

  static const String appName = 'VocabFlip';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'vocabflip.db';
  static const int databaseVersion = 10;

  // Tables
  static const String tableDecks = 'decks';
  static const String tableFlashcards = 'flashcards';
  static const String tableStudySessions = 'study_sessions';
  static const String tableReviewLogs = 'review_logs';
  static const String tableImportedDeckLinks = 'imported_deck_links';

  // Firestore Collections
  static const String collectionPublicDecks = 'public_decks';
  static const String collectionPublicFlashcards = 'flashcards';
  static const String collectionRatings = 'ratings';
  static const String collectionCategories = 'categories';
  static const String collectionImportedDecks = 'imported_decks';
  static const String collectionSyncNotifications = 'sync_notifications';
  static const String collectionPublicProfiles = 'public_profiles';

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

  // Pagination
  static const int defaultPageSize = 20;

  // Animation durations
  static const Duration flipDuration = Duration(milliseconds: 400);
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);

  // Export/Import
  static const String exportFileExtension = '.json';
  static const String exportVersion = '1.0';
}
