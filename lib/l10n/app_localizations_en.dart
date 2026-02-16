// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VocabFlip';

  @override
  String get home => 'Home';

  @override
  String get decks => 'Decks';

  @override
  String get study => 'Study';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String get createDeck => 'Create Deck';

  @override
  String get editDeck => 'Edit Deck';

  @override
  String get deleteDeck => 'Delete Deck';

  @override
  String get deckName => 'Deck Name';

  @override
  String get deckDescription => 'Description';

  @override
  String get sourceLanguage => 'Source Language';

  @override
  String get targetLanguage => 'Target Language';

  @override
  String get createFlashcard => 'Create Flashcard';

  @override
  String get editFlashcard => 'Edit Flashcard';

  @override
  String get deleteFlashcard => 'Delete Flashcard';

  @override
  String get front => 'Front';

  @override
  String get back => 'Back';

  @override
  String get phonetic => 'Phonetic';

  @override
  String get example => 'Example';

  @override
  String get notes => 'Notes';

  @override
  String get tags => 'Tags';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get go => 'Go';

  @override
  String get delete => 'Delete';

  @override
  String get search => 'Search';

  @override
  String get searchDictionary => 'Search Dictionary';

  @override
  String get autoFill => 'Auto-fill';

  @override
  String get startStudy => 'Start Study';

  @override
  String get continueStudy => 'Continue Study';

  @override
  String get review => 'Review';

  @override
  String get quiz => 'Quiz';

  @override
  String get again => 'Again';

  @override
  String get hard => 'Hard';

  @override
  String get good => 'Good';

  @override
  String get easy => 'Easy';

  @override
  String get cardsToReview => 'Cards to Review';

  @override
  String get cardsLearned => 'Cards Learned';

  @override
  String get totalCards => 'Total Cards';

  @override
  String get streak => 'Streak';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get studyTime => 'Study Time';

  @override
  String get importDeck => 'Import Deck';

  @override
  String get exportDeck => 'Export Deck';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get noDecks => 'No decks yet. Create your first deck!';

  @override
  String get noCards => 'No cards in this deck. Add some flashcards!';

  @override
  String get noCardsToReview => 'No cards to review today. Great job!';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get japanese => 'Japanese';

  @override
  String get chinese => 'Chinese';

  @override
  String get displayMode => 'Display Mode';

  @override
  String get displayModeDesc => 'Choose which side of the card to show first';

  @override
  String get frontFirst => 'Front First';

  @override
  String get backFirst => 'Back First';

  @override
  String get exampleSentence => 'Example sentence (optional)';

  @override
  String get noteLabel => 'Note';

  @override
  String get confirmDelete => 'Are you sure you want to delete this?';

  @override
  String get flipCard => 'Tap to flip';

  @override
  String get showAnswer => 'Show Answer';

  @override
  String get nextCard => 'Next Card';

  @override
  String get previousCard => 'Previous Card';

  @override
  String get finishStudy => 'Finish Study';

  @override
  String get studyComplete => 'Study Complete!';

  @override
  String get cardsReviewed => 'Cards Reviewed';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get allTime => 'All Time';

  @override
  String get library => 'Library';

  @override
  String get dictionary => 'Dictionary';

  @override
  String get stats => 'Stats';

  @override
  String get featured => 'Featured';

  @override
  String get topRated => 'Top Rated';

  @override
  String get newDecks => 'New';

  @override
  String get browse => 'Browse';

  @override
  String get goodMorning => 'Good morning!';

  @override
  String get goodAfternoon => 'Good afternoon!';

  @override
  String get goodEvening => 'Good evening!';

  @override
  String get readyToLearn => 'Ready to learn some new words?';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get noCardsToReviewToday => 'No cards to review today';

  @override
  String get due => 'Due';

  @override
  String get dueToday => 'Due Today';

  @override
  String get recentDecks => 'Recent Decks';

  @override
  String dayStreak(int count) {
    return '$count day streak';
  }

  @override
  String cardsDue(int count) {
    return '$count cards due';
  }

  @override
  String get cards => 'Cards';

  @override
  String get myDecks => 'My Decks';

  @override
  String get noDecksYet => 'No decks yet';

  @override
  String get createFirstDeck => 'Create your first deck to start learning!';

  @override
  String get edit => 'Edit';

  @override
  String get export => 'Export';

  @override
  String get importCards => 'Import Cards';

  @override
  String get publishToLibrary => 'Publish to Library';

  @override
  String get displayNameRequired =>
      'Please set your display name before publishing';

  @override
  String get displayNameHint => 'Enter your display name';

  @override
  String get setDisplayName => 'Set Display Name';

  @override
  String get unlinkFromLibrary => 'Unlink from Library';

  @override
  String get managePublished => 'Manage Published';

  @override
  String get loadingDecks => 'Loading decks...';

  @override
  String get total => 'Total';

  @override
  String get newCards => 'New';

  @override
  String get learning => 'Learning';

  @override
  String get reviewCards => 'Review';

  @override
  String get published => 'Published';

  @override
  String nCards(int count) {
    return '$count cards';
  }

  @override
  String nNew(int count) {
    return '$count new';
  }

  @override
  String nReview(int count) {
    return '$count review';
  }

  @override
  String get skip => 'Skip';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get anError => 'An error occurred';

  @override
  String get cardsStudied => 'Cards Studied';

  @override
  String get time => 'Time';

  @override
  String get done => 'Done';

  @override
  String get studyAgain => 'Study Again';

  @override
  String get endSession => 'End Session';

  @override
  String get continueSession => 'Continue';

  @override
  String get progressSaved => 'Your progress will be saved.';

  @override
  String studyN(int count) {
    return 'Study ($count)';
  }

  @override
  String get wordFront => 'Word / Front';

  @override
  String get enterWord => 'Enter the word to learn';

  @override
  String get lookUp => 'Look up';

  @override
  String get phoneticReading => 'Phonetic / Reading (optional)';

  @override
  String get phoneticHint => 'IPA, Pinyin, Hiragana, etc.';

  @override
  String get meaningBack => 'Meaning / Back';

  @override
  String get enterMeaning => 'Enter the meaning in Vietnamese';

  @override
  String get addExample => 'Add an example sentence';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get addNotes => 'Add any notes or hints';

  @override
  String get tagsOptional => 'Tags (optional)';

  @override
  String get tagsHint => 'verb, N5, food (comma-separated)';

  @override
  String get update => 'Update';

  @override
  String get addFlashcard => 'Add Flashcard';

  @override
  String get addAndCreateAnother => 'Add & Create Another';

  @override
  String get autoFilled => 'Auto-filled from dictionary';

  @override
  String get wordNotFound => 'Word not found';

  @override
  String get pleaseEnterWord => 'Please enter a word';

  @override
  String get pleaseEnterMeaning => 'Please enter the meaning';

  @override
  String get pleaseEnterWordFirst => 'Please enter a word first';

  @override
  String get flashcardAdded => 'Flashcard added!';

  @override
  String get autoFillFromDictionary => 'Auto-fill from dictionary';

  @override
  String get viewCards => 'View Cards';

  @override
  String get noFlashcards => 'No flashcards';

  @override
  String get sourceLanguageLabel => 'Source Language:';

  @override
  String get searchForWord => 'Search for a word...';

  @override
  String get lookingUp => 'Looking up...';

  @override
  String get enterWordToLookUp => 'Enter a word to look up';

  @override
  String get addToDeck => 'Add to Deck';

  @override
  String get synonyms => 'Synonyms';

  @override
  String get antonyms => 'Antonyms';

  @override
  String get resultLimit => 'Result Limit';

  @override
  String get dictionarySettings => 'Dictionary';

  @override
  String get filterMode => 'Filter Mode';

  @override
  String get filterExactFirst => 'Exact match first';

  @override
  String get filterExactFirstDesc =>
      'Prioritize exact match, then results with meanings';

  @override
  String get filterWithMeanings => 'With meanings only';

  @override
  String get filterWithMeaningsDesc =>
      'Only show results that have definitions';

  @override
  String get filterAll => 'Show all';

  @override
  String get filterAllDesc => 'Show all results without filtering';

  @override
  String get fallbackToEnglish => 'Fallback to English';

  @override
  String get fallbackToEnglishDesc =>
      'Use English dictionary if Vietnamese not found';

  @override
  String get selectDeck => 'Select Deck';

  @override
  String get addedToDeck => 'Added to deck';

  @override
  String get appearance => 'Appearance';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get studySettings => 'Study';

  @override
  String get newCardsPerDay => 'New cards per day';

  @override
  String get reviewCardsPerDay => 'Review cards per day';

  @override
  String get showPhonetic => 'Show phonetic';

  @override
  String get displayPronunciation => 'Display pronunciation on cards';

  @override
  String get autoPlayAudio => 'Auto-play audio';

  @override
  String get automaticallyPlayPronunciation =>
      'Automatically play pronunciation';

  @override
  String get backupSync => 'Backup & Sync';

  @override
  String get backupToCloud => 'Backup to Cloud';

  @override
  String get saveDataToCloud => 'Save your data to the cloud';

  @override
  String get restoreFromCloud => 'Restore from Cloud';

  @override
  String get restoreDataFromCloud => 'Restore your data from the cloud';

  @override
  String get firebaseNotConfigured => 'Firebase not configured';

  @override
  String get autoSync => 'Auto-sync';

  @override
  String get autoSyncWhenOnline => 'Automatically sync when online';

  @override
  String get importExport => 'Import & Export';

  @override
  String get importFromJson => 'Import from JSON file';

  @override
  String get exportAllDecks => 'Export All Decks';

  @override
  String get exportToJson => 'Export to JSON file';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get rateApp => 'Rate App';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get deleteAllData => 'Delete all decks and cards';

  @override
  String get resetConfirmTitle => 'Reset All Data?';

  @override
  String get resetConfirmMessage =>
      'This will permanently delete all your decks, flashcards, and study progress. This action cannot be undone.';

  @override
  String get reset => 'Reset';

  @override
  String get dataReset => 'All data has been reset';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get numberOfCards => 'Number of cards';

  @override
  String get overview => 'Overview';

  @override
  String get days => 'days';

  @override
  String get created => 'created';

  @override
  String get weeklyActivity => 'Weekly Activity';

  @override
  String get deckProgress => 'Deck Progress';

  @override
  String cardsLearnedCount(int learned, int total) {
    return '$learned / $total cards learned';
  }

  @override
  String dueCount(int count) {
    return '$count due';
  }

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get noFeaturedDecks => 'No featured decks yet';

  @override
  String get noRatedDecks => 'No rated decks yet';

  @override
  String get noDecksYetSimple => 'No decks yet';

  @override
  String get noDecksFound => 'No decks found';

  @override
  String get unableToConnect => 'Unable to connect to library';

  @override
  String get retry => 'Retry';

  @override
  String get searchDecks => 'Search by name or tag...';

  @override
  String get popularSearches => 'Popular Searches';

  @override
  String get browseByCategory => 'Browse by Category';

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get tryDifferentKeywords =>
      'Try different keywords or browse categories';

  @override
  String decksCount(int count) {
    return '$count decks';
  }

  @override
  String resultsFor(int count, String query) {
    return '$count results for \"$query\"';
  }

  @override
  String get deckDetails => 'Deck Details';

  @override
  String get ratingsReviews => 'Ratings & Reviews';

  @override
  String get previewCards => 'Preview Cards';

  @override
  String get editReview => 'Edit Review';

  @override
  String get rate => 'Rate';

  @override
  String get signInToRate => 'Sign in to rate this deck';

  @override
  String get yourRating => 'Your rating: ';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get noCardsPreview => 'No cards to preview';

  @override
  String get alreadyImported => 'Already Imported';

  @override
  String get failedToLoad => 'Failed to load deck';

  @override
  String get shareComingSoon => 'Share feature coming soon';

  @override
  String successfullyImported(String name) {
    return 'Successfully imported \"$name\"';
  }

  @override
  String get view => 'View';

  @override
  String failedToImport(String error) {
    return 'Failed to import: $error';
  }

  @override
  String downloadsCount(int count) {
    return '$count downloads';
  }

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String cardsCount(int count) {
    return '$count cards';
  }

  @override
  String get publishDeck => 'Publish Deck';

  @override
  String get deckNotFound => 'Deck not found';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get addTagsHelp => 'Add tags to help users find your deck';

  @override
  String get publishingGuidelines => 'Publishing Guidelines';

  @override
  String get qualityContent => 'Make sure your deck has quality content';

  @override
  String get appropriateCategories => 'Use appropriate categories and tags';

  @override
  String get avoidCopyrighted => 'Avoid copyrighted material';

  @override
  String get canUpdateAnytime => 'You can update or unpublish anytime';

  @override
  String get deckPublished => 'Deck published successfully!';

  @override
  String get deckUpdated => 'Deck updated successfully!';

  @override
  String get myPublishedDecks => 'My Published Decks';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get noPublishedDecks => 'No Published Decks';

  @override
  String get shareWithCommunity => 'Share your decks with the community';

  @override
  String get pushUpdate => 'Push Update';

  @override
  String get syncChanges => 'Sync changes from local deck';

  @override
  String get unpublish => 'Unpublish';

  @override
  String get removeFromLibrary => 'Remove from public library';

  @override
  String get viewAnalytics => 'View Analytics';

  @override
  String get analyticsComingSoon => 'Analytics coming soon';

  @override
  String get updatingDeck => 'Updating published deck...';

  @override
  String get unpublishConfirm => 'Unpublish Deck?';

  @override
  String get unpublishDescription =>
      'This will remove the deck from the public library. Users who already imported it will still have their copies.';

  @override
  String get deckUnpublished => 'Deck unpublished';

  @override
  String get updates => 'Updates';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get availableUpdates => 'Available Updates';

  @override
  String decksHaveUpdates(int count) {
    return '$count decks have updates';
  }

  @override
  String get syncAll => 'Sync All';

  @override
  String get sync => 'Sync';

  @override
  String get history => 'History';

  @override
  String updatedToVersion(int version) {
    return 'Updated to v$version';
  }

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get noUpdatesAvailable => 'No updates available';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get confirm => 'Confirm';

  @override
  String deleteConfirmTitle(String name) {
    return 'Delete $name';
  }

  @override
  String deleteConfirmMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get actionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get unlinkDeck => 'Unlink Deck';

  @override
  String get unlinkDeckMessage =>
      'This will remove the connection to the original deck. You will no longer receive updates from the author.';

  @override
  String get unlink => 'Unlink';

  @override
  String get deckUnlinked => 'Deck unlinked';

  @override
  String get noFlashcardsYet => 'No flashcards yet';

  @override
  String get addFlashcardsToStart => 'Add flashcards to start learning!';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get describeWhatDeckAbout => 'Describe what this deck is about';

  @override
  String get pleaseEnterDeckName => 'Please enter a deck name';

  @override
  String get deckNameHint => 'e.g., Japanese N5 Vocabulary';

  @override
  String get languageOfWordsToLearn =>
      'The language of the words you want to learn';

  @override
  String get updateDeck => 'Update Deck';

  @override
  String get image => 'Image';

  @override
  String get imageOptional => 'Image (optional)';

  @override
  String get localFile => 'Local File';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get enterImageUrl => 'Enter image URL';

  @override
  String get invalidImageUrl => 'Invalid image URL';

  @override
  String get tapToAddImage => 'Tap to add image';

  @override
  String get changeImage => 'Change image';

  @override
  String get removeImage => 'Remove image';

  @override
  String get uploadImage => 'Upload image';

  @override
  String get frontImage => 'Front Image';

  @override
  String get backImage => 'Back Image';

  @override
  String get shareImageOnBothSides => 'Share image on both sides';

  @override
  String get shareImageDescription =>
      'Show the front image on the back side as well';

  @override
  String get flashcardImageSize => 'Flashcard Image Size';

  @override
  String get recommendedForMobile => 'Recommended for mobile';

  @override
  String get recommendedForDesktop => 'Recommended for desktop';

  @override
  String get balanced => 'Balanced';

  @override
  String get flashcardFontSize => 'Flashcard Font Size';

  @override
  String get mainTextSize => 'Main Text';

  @override
  String get phoneticTextSize => 'Phonetic Text';

  @override
  String get detailTextSize => 'Example & Note';

  @override
  String fontSizePixels(int size) {
    return '${size}px';
  }

  @override
  String get small => 'Small';

  @override
  String get medium => 'Medium';

  @override
  String get large => 'Large';

  @override
  String get extraLarge => 'Extra Large';

  @override
  String get account => 'Account';

  @override
  String get signInWithEmail => 'Sign in with Email';

  @override
  String get createAccount => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get signInFailed => 'Sign in failed';

  @override
  String get signUpFailed => 'Sign up failed';

  @override
  String get resetPasswordSent => 'Password reset email sent';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get cardStructure => 'Card Structure';

  @override
  String get cardStructureDesc =>
      'Configure which fields appear on front and back of cards';

  @override
  String get frontSide => 'Front Side';

  @override
  String get backSide => 'Back Side';

  @override
  String get dragToReorder =>
      '• Drag handle (≡): reorder within section\n• Drag entire field: move to other section';

  @override
  String get imageDisplay => 'Image Display';

  @override
  String get imageDisplayDesc => 'Choose how images are displayed on cards';

  @override
  String get noImage => 'No Image';

  @override
  String get bothSides => 'Both Sides';

  @override
  String get frontOnly => 'Front Only';

  @override
  String get backOnly => 'Back Only';

  @override
  String get fieldWord => 'Word';

  @override
  String get fieldPhonetic => 'Phonetic';

  @override
  String get fieldMeaning => 'Meaning';

  @override
  String get fieldExample => 'Example';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get lockedField => 'Locked';

  @override
  String get autoPlayTts => 'Auto-play Pronunciation';

  @override
  String get autoPlayTtsDesc =>
      'Automatically play pronunciation when flipping cards';

  @override
  String get ttsHelp => 'TTS Installation Guide';

  @override
  String get ttsLanguagesMissing => 'Missing TTS Languages';

  @override
  String get ttsLanguagesMissingDesc =>
      'The following languages are not available for text-to-speech:';

  @override
  String get ttsInstallInstructions => 'How to install TTS voices (Windows):';

  @override
  String get ttsStepOpenSettings => 'Open Windows Settings';

  @override
  String get ttsStepTimeLanguage => 'Go to Time & Language → Language';

  @override
  String get ttsStepAddLanguage => 'Click \"Add a language\"';

  @override
  String get ttsStepSelectLanguage =>
      'Search and add the language (e.g., Japanese, Chinese)';

  @override
  String get ttsStepDownloadSpeech =>
      'Click on the language → Options → Download \"Speech\"';

  @override
  String get ttsStepRestartApp => 'Restart VocabFlip';

  @override
  String get ttsGenericInstructions =>
      'Please install TTS voices for your desired languages in your system settings.';

  @override
  String get dontShowAgain => 'Don\'t show again';

  @override
  String get ttsSettings => 'TTS Settings';

  @override
  String get helper => 'Help & Guides';

  @override
  String get resetTtsWarning => 'Reset TTS Warning';

  @override
  String get resetTtsWarningDesc =>
      'Show TTS installation warning again when entering decks';

  @override
  String get ttsWarningReset => 'TTS warning has been reset';

  @override
  String get close => 'Close';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateRequired =>
      'This update is required to continue using the app.';

  @override
  String get autoCheckUpdates => 'Auto-check for updates';

  @override
  String get autoCheckUpdatesDesc =>
      'Automatically check for updates when app starts';

  @override
  String get downloadUpdate => 'Download Update';

  @override
  String get downloadingUpdate => 'Downloading Update...';

  @override
  String get extractingUpdate => 'Extracting Update...';

  @override
  String get installing => 'Installing...';

  @override
  String get restartToApply =>
      'The update is ready. Restart the app to apply changes.';

  @override
  String get restartNow => 'Restart Now';

  @override
  String get currentVersion => 'Current';

  @override
  String get newVersion => 'New';

  @override
  String get newLabel => 'NEW';

  @override
  String get whatsNew => 'What\'s New';

  @override
  String get updateLater => 'Later';

  @override
  String get skipVersion => 'Skip This Version';

  @override
  String get checkingForUpdates => 'Tap to check for updates';

  @override
  String get updateFailed => 'Update Failed';

  @override
  String updateAvailableVersion(String version) {
    return 'Version $version available';
  }

  @override
  String get support => 'Support';

  @override
  String get donate => 'Donate';

  @override
  String get donateDesc => 'Support the developer';

  @override
  String get donateMessage =>
      'If you find this app helpful, consider buying me a coffee! Your support helps keep this project alive.';

  @override
  String get donateBank => 'Vietcombank - Scan QR to donate';

  @override
  String get saveQrImage => 'Save QR Image';

  @override
  String get qrSaved => 'QR image saved';

  @override
  String get qrSaveFailed => 'Failed to save QR image';

  @override
  String get importFromExcel => 'Import from Excel';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String get errorExportingExcel => 'Error exporting to Excel';

  @override
  String get excelFileInUse =>
      'The file is currently open in another program. Please close it and try again.';

  @override
  String get noCardsToImport => 'No cards to import';

  @override
  String get importSummary => 'Import Summary:';

  @override
  String get newCardsToAdd => 'New cards to add';

  @override
  String get cardsToUpdate => 'Cards to update';

  @override
  String get errorsFound => 'Errors found';

  @override
  String importN(int count) {
    return 'Import $count cards';
  }

  @override
  String get importingCards => 'Importing cards...';

  @override
  String get excelExportedSuccess => 'Excel file exported and folder opened';

  @override
  String excelFromDifferentDeck(String deckName) {
    return 'This file was exported from a different deck: \"$deckName\". Do you want to continue?';
  }

  @override
  String get continueImport => 'Continue';

  @override
  String get warning => 'Warning';

  @override
  String importCompleted(int added, int updated) {
    return 'Import completed: $added added, $updated updated';
  }

  @override
  String get googleDriveBackup => 'Google Drive Backup';

  @override
  String get notConnectedToGoogleDrive => 'Not Connected to Google Drive';

  @override
  String get connectToBackupData =>
      'Connect to backup and restore your flashcard data';

  @override
  String get connectGoogleDrive => 'Connect to Google Drive';

  @override
  String get connectedAs => 'Connected as';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get availableBackups => 'Available Backups';

  @override
  String get noBackupsYet => 'No Backups Yet';

  @override
  String get createFirstBackup =>
      'Create your first backup to protect your data';

  @override
  String get creatingBackup => 'Creating Backup';

  @override
  String get restoringBackup => 'Restoring Backup';

  @override
  String get backupComplete => 'Backup Complete';

  @override
  String get backupFailed => 'Backup Failed';

  @override
  String get restoreComplete => 'Restore Complete';

  @override
  String get restoreFailed => 'Restore Failed';

  @override
  String backupSuccessMessage(int deckCount, int cardCount) {
    return 'Successfully backed up $deckCount decks with $cardCount cards';
  }

  @override
  String restoreSuccessMessage(int deckCount, int cardCount) {
    return 'Restored $deckCount decks with $cardCount cards';
  }

  @override
  String decksSkipped(int count) {
    return '$count existing decks were skipped';
  }

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String backupInfo(String date, int deckCount, int cardCount) {
    return 'Backup from $date\n$deckCount decks, $cardCount cards';
  }

  @override
  String get selectRestoreMode => 'Select restore mode:';

  @override
  String get restoreModeMerge => 'Merge with existing';

  @override
  String get restoreModeMergeDesc => 'Keep existing decks, add new ones';

  @override
  String get restoreModeReplace => 'Replace existing';

  @override
  String get restoreModeReplaceDesc => 'Delete and replace matching decks';

  @override
  String get deleteBackup => 'Delete Backup';

  @override
  String deleteBackupConfirm(String date) {
    return 'Are you sure you want to delete the backup from $date?';
  }

  @override
  String get backupDeleted => 'Backup deleted';

  @override
  String backupSummary(int deckCount, int cardCount, String size) {
    return '$deckCount decks, $cardCount cards ($size)';
  }

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get nicknameTaken => 'This nickname is already taken';

  @override
  String get selectAvatar => 'Select Avatar';

  @override
  String get nickname => 'Nickname';

  @override
  String get enterNickname => 'Enter your nickname';

  @override
  String get gender => 'Gender';

  @override
  String get bio => 'Bio';

  @override
  String get enterBio => 'Write something about yourself';

  @override
  String get manageAccount => 'Manage Account';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get genderPreferNotToSay => 'Prefer not to say';

  @override
  String get enterDeckId => 'Enter deck ID...';

  @override
  String get importById => 'Import by ID';

  @override
  String uploadingImages(int completed, int total) {
    return 'Uploading images $completed/$total...';
  }

  @override
  String downloadingImages(int completed, int total) {
    return 'Downloading images $completed/$total...';
  }

  @override
  String imageUploadFailed(int count) {
    return '$count image(s) failed to upload';
  }

  @override
  String get shareDeckId => 'Share Deck ID';

  @override
  String get copyDeckIdToShare => 'Copy deck ID so others can import it';

  @override
  String get deckIdCopied => 'Deck ID copied to clipboard';

  @override
  String get deckImage => 'Deck Image';

  @override
  String get selectDeckToPublish => 'Select a deck to publish';

  @override
  String get allDecksPublished => 'All your decks are already published';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortNameAZ => 'Name (A-Z)';

  @override
  String get sortNameZA => 'Name (Z-A)';

  @override
  String get sortMostCards => 'Most Cards';

  @override
  String get sortMostDue => 'Most Due';

  @override
  String get sortRecentlyUpdated => 'Recently Updated';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get noMatchingDecks => 'No matching decks';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get reimportDeck => 'Re-import to local';

  @override
  String get reimportDescription =>
      'Local deck was deleted. Re-import from published version.';

  @override
  String get reimportSuccess => 'Deck re-imported successfully';

  @override
  String get viewReviews => 'View Reviews';

  @override
  String get filterByRating => 'Filter by rating';

  @override
  String get allRatings => 'All';

  @override
  String get flashcards => 'Flashcards';

  @override
  String get enterYourNickname => 'Your nickname (optional)';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String nStarRating(int count) {
    return '$count★';
  }

  @override
  String get feedbackTitle => 'Send Feedback';

  @override
  String get feedbackCategoryLabel => 'Category';

  @override
  String get feedbackCategoryBug => 'Bug Report';

  @override
  String get feedbackCategoryFeature => 'Feature Request';

  @override
  String get feedbackCategoryGeneral => 'General Feedback';

  @override
  String get feedbackCategoryOther => 'Other';

  @override
  String get feedbackMessageHint => 'Your feedback';

  @override
  String get feedbackEmailHint => 'Email (optional)';

  @override
  String get feedbackEmailHelper => 'Only if you\'d like a reply';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackSuccess => 'Thank you for your feedback!';

  @override
  String get feedbackError => 'Failed to send feedback. Please try again.';

  @override
  String get feedbackMessageRequired => 'Please enter your feedback';

  @override
  String get adminSection => 'Admin';

  @override
  String get adminFeedback => 'User Feedback';

  @override
  String get noFeedbackYet => 'No feedback received yet';

  @override
  String nNewFeedback(int count) {
    return '$count new';
  }
}
