import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'VocabFlip'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @decks.
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get decks;

  /// No description provided for @study.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get study;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @createDeck.
  ///
  /// In en, this message translates to:
  /// **'Create Deck'**
  String get createDeck;

  /// No description provided for @editDeck.
  ///
  /// In en, this message translates to:
  /// **'Edit Deck'**
  String get editDeck;

  /// No description provided for @deleteDeck.
  ///
  /// In en, this message translates to:
  /// **'Delete Deck'**
  String get deleteDeck;

  /// No description provided for @deckName.
  ///
  /// In en, this message translates to:
  /// **'Deck Name'**
  String get deckName;

  /// No description provided for @deckDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get deckDescription;

  /// No description provided for @sourceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Source Language'**
  String get sourceLanguage;

  /// No description provided for @targetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Target Language'**
  String get targetLanguage;

  /// No description provided for @createFlashcard.
  ///
  /// In en, this message translates to:
  /// **'Create Flashcard'**
  String get createFlashcard;

  /// No description provided for @editFlashcard.
  ///
  /// In en, this message translates to:
  /// **'Edit Flashcard'**
  String get editFlashcard;

  /// No description provided for @deleteFlashcard.
  ///
  /// In en, this message translates to:
  /// **'Delete Flashcard'**
  String get deleteFlashcard;

  /// No description provided for @front.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get front;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @phonetic.
  ///
  /// In en, this message translates to:
  /// **'Phonetic'**
  String get phonetic;

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get example;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchDictionary.
  ///
  /// In en, this message translates to:
  /// **'Search Dictionary'**
  String get searchDictionary;

  /// No description provided for @autoFill.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill'**
  String get autoFill;

  /// No description provided for @startStudy.
  ///
  /// In en, this message translates to:
  /// **'Start Study'**
  String get startStudy;

  /// No description provided for @continueStudy.
  ///
  /// In en, this message translates to:
  /// **'Continue Study'**
  String get continueStudy;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @again.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get again;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @cardsToReview.
  ///
  /// In en, this message translates to:
  /// **'Cards to Review'**
  String get cardsToReview;

  /// No description provided for @cardsLearned.
  ///
  /// In en, this message translates to:
  /// **'Cards Learned'**
  String get cardsLearned;

  /// No description provided for @totalCards.
  ///
  /// In en, this message translates to:
  /// **'Total Cards'**
  String get totalCards;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @studyTime.
  ///
  /// In en, this message translates to:
  /// **'Study Time'**
  String get studyTime;

  /// No description provided for @importDeck.
  ///
  /// In en, this message translates to:
  /// **'Import Deck'**
  String get importDeck;

  /// No description provided for @exportDeck.
  ///
  /// In en, this message translates to:
  /// **'Export Deck'**
  String get exportDeck;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @noDecks.
  ///
  /// In en, this message translates to:
  /// **'No decks yet. Create your first deck!'**
  String get noDecks;

  /// No description provided for @noCards.
  ///
  /// In en, this message translates to:
  /// **'No cards in this deck. Add some flashcards!'**
  String get noCards;

  /// No description provided for @noCardsToReview.
  ///
  /// In en, this message translates to:
  /// **'No cards to review today. Great job!'**
  String get noCardsToReview;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @displayMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get displayMode;

  /// No description provided for @displayModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which side of the card to show first'**
  String get displayModeDesc;

  /// No description provided for @frontFirst.
  ///
  /// In en, this message translates to:
  /// **'Front First'**
  String get frontFirst;

  /// No description provided for @backFirst.
  ///
  /// In en, this message translates to:
  /// **'Back First'**
  String get backFirst;

  /// No description provided for @exampleSentence.
  ///
  /// In en, this message translates to:
  /// **'Example sentence (optional)'**
  String get exampleSentence;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get confirmDelete;

  /// No description provided for @flipCard.
  ///
  /// In en, this message translates to:
  /// **'Tap to flip'**
  String get flipCard;

  /// No description provided for @showAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show Answer'**
  String get showAnswer;

  /// No description provided for @nextCard.
  ///
  /// In en, this message translates to:
  /// **'Next Card'**
  String get nextCard;

  /// No description provided for @previousCard.
  ///
  /// In en, this message translates to:
  /// **'Previous Card'**
  String get previousCard;

  /// No description provided for @finishStudy.
  ///
  /// In en, this message translates to:
  /// **'Finish Study'**
  String get finishStudy;

  /// No description provided for @studyComplete.
  ///
  /// In en, this message translates to:
  /// **'Study Complete!'**
  String get studyComplete;

  /// No description provided for @cardsReviewed.
  ///
  /// In en, this message translates to:
  /// **'Cards Reviewed'**
  String get cardsReviewed;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @dictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get dictionary;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// No description provided for @newDecks.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newDecks;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get goodEvening;

  /// No description provided for @readyToLearn.
  ///
  /// In en, this message translates to:
  /// **'Ready to learn some new words?'**
  String get readyToLearn;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noCardsToReviewToday.
  ///
  /// In en, this message translates to:
  /// **'No cards to review today'**
  String get noCardsToReviewToday;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get dueToday;

  /// No description provided for @recentDecks.
  ///
  /// In en, this message translates to:
  /// **'Recent Decks'**
  String get recentDecks;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreak(int count);

  /// No description provided for @cardsDue.
  ///
  /// In en, this message translates to:
  /// **'{count} cards due'**
  String cardsDue(int count);

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cards;

  /// No description provided for @myDecks.
  ///
  /// In en, this message translates to:
  /// **'My Decks'**
  String get myDecks;

  /// No description provided for @noDecksYet.
  ///
  /// In en, this message translates to:
  /// **'No decks yet'**
  String get noDecksYet;

  /// No description provided for @createFirstDeck.
  ///
  /// In en, this message translates to:
  /// **'Create your first deck to start learning!'**
  String get createFirstDeck;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @importCards.
  ///
  /// In en, this message translates to:
  /// **'Import Cards'**
  String get importCards;

  /// No description provided for @publishToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Publish to Library'**
  String get publishToLibrary;

  /// No description provided for @unlinkFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Unlink from Library'**
  String get unlinkFromLibrary;

  /// No description provided for @managePublished.
  ///
  /// In en, this message translates to:
  /// **'Manage Published'**
  String get managePublished;

  /// No description provided for @loadingDecks.
  ///
  /// In en, this message translates to:
  /// **'Loading decks...'**
  String get loadingDecks;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @newCards.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newCards;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learning;

  /// No description provided for @reviewCards.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewCards;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @nCards.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String nCards(int count);

  /// No description provided for @nNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String nNew(int count);

  /// No description provided for @nReview.
  ///
  /// In en, this message translates to:
  /// **'{count} review'**
  String nReview(int count);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @anError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anError;

  /// No description provided for @cardsStudied.
  ///
  /// In en, this message translates to:
  /// **'Cards Studied'**
  String get cardsStudied;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @studyAgain.
  ///
  /// In en, this message translates to:
  /// **'Study Again'**
  String get studyAgain;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// No description provided for @continueSession.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueSession;

  /// No description provided for @progressSaved.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be saved.'**
  String get progressSaved;

  /// No description provided for @studyN.
  ///
  /// In en, this message translates to:
  /// **'Study ({count})'**
  String studyN(int count);

  /// No description provided for @wordFront.
  ///
  /// In en, this message translates to:
  /// **'Word / Front'**
  String get wordFront;

  /// No description provided for @enterWord.
  ///
  /// In en, this message translates to:
  /// **'Enter the word to learn'**
  String get enterWord;

  /// No description provided for @lookUp.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get lookUp;

  /// No description provided for @phoneticReading.
  ///
  /// In en, this message translates to:
  /// **'Phonetic / Reading (optional)'**
  String get phoneticReading;

  /// No description provided for @phoneticHint.
  ///
  /// In en, this message translates to:
  /// **'IPA, Pinyin, Hiragana, etc.'**
  String get phoneticHint;

  /// No description provided for @meaningBack.
  ///
  /// In en, this message translates to:
  /// **'Meaning / Back'**
  String get meaningBack;

  /// No description provided for @enterMeaning.
  ///
  /// In en, this message translates to:
  /// **'Enter the meaning in Vietnamese'**
  String get enterMeaning;

  /// No description provided for @addExample.
  ///
  /// In en, this message translates to:
  /// **'Add an example sentence'**
  String get addExample;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Add any notes or hints'**
  String get addNotes;

  /// No description provided for @tagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get tagsOptional;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'verb, N5, food (comma-separated)'**
  String get tagsHint;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @addFlashcard.
  ///
  /// In en, this message translates to:
  /// **'Add Flashcard'**
  String get addFlashcard;

  /// No description provided for @addAndCreateAnother.
  ///
  /// In en, this message translates to:
  /// **'Add & Create Another'**
  String get addAndCreateAnother;

  /// No description provided for @autoFilled.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled from dictionary'**
  String get autoFilled;

  /// No description provided for @wordNotFound.
  ///
  /// In en, this message translates to:
  /// **'Word not found'**
  String get wordNotFound;

  /// No description provided for @pleaseEnterWord.
  ///
  /// In en, this message translates to:
  /// **'Please enter a word'**
  String get pleaseEnterWord;

  /// No description provided for @pleaseEnterMeaning.
  ///
  /// In en, this message translates to:
  /// **'Please enter the meaning'**
  String get pleaseEnterMeaning;

  /// No description provided for @pleaseEnterWordFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter a word first'**
  String get pleaseEnterWordFirst;

  /// No description provided for @flashcardAdded.
  ///
  /// In en, this message translates to:
  /// **'Flashcard added!'**
  String get flashcardAdded;

  /// No description provided for @autoFillFromDictionary.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill from dictionary'**
  String get autoFillFromDictionary;

  /// No description provided for @viewCards.
  ///
  /// In en, this message translates to:
  /// **'View Cards'**
  String get viewCards;

  /// No description provided for @noFlashcards.
  ///
  /// In en, this message translates to:
  /// **'No flashcards'**
  String get noFlashcards;

  /// No description provided for @sourceLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Source Language:'**
  String get sourceLanguageLabel;

  /// No description provided for @searchForWord.
  ///
  /// In en, this message translates to:
  /// **'Search for a word...'**
  String get searchForWord;

  /// No description provided for @lookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up...'**
  String get lookingUp;

  /// No description provided for @enterWordToLookUp.
  ///
  /// In en, this message translates to:
  /// **'Enter a word to look up'**
  String get enterWordToLookUp;

  /// No description provided for @addToDeck.
  ///
  /// In en, this message translates to:
  /// **'Add to Deck'**
  String get addToDeck;

  /// No description provided for @synonyms.
  ///
  /// In en, this message translates to:
  /// **'Synonyms'**
  String get synonyms;

  /// No description provided for @antonyms.
  ///
  /// In en, this message translates to:
  /// **'Antonyms'**
  String get antonyms;

  /// No description provided for @resultLimit.
  ///
  /// In en, this message translates to:
  /// **'Result Limit'**
  String get resultLimit;

  /// No description provided for @dictionarySettings.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get dictionarySettings;

  /// No description provided for @filterMode.
  ///
  /// In en, this message translates to:
  /// **'Filter Mode'**
  String get filterMode;

  /// No description provided for @filterExactFirst.
  ///
  /// In en, this message translates to:
  /// **'Exact match first'**
  String get filterExactFirst;

  /// No description provided for @filterExactFirstDesc.
  ///
  /// In en, this message translates to:
  /// **'Prioritize exact match, then results with meanings'**
  String get filterExactFirstDesc;

  /// No description provided for @filterWithMeanings.
  ///
  /// In en, this message translates to:
  /// **'With meanings only'**
  String get filterWithMeanings;

  /// No description provided for @filterWithMeaningsDesc.
  ///
  /// In en, this message translates to:
  /// **'Only show results that have definitions'**
  String get filterWithMeaningsDesc;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get filterAll;

  /// No description provided for @filterAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Show all results without filtering'**
  String get filterAllDesc;

  /// No description provided for @fallbackToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Fallback to English'**
  String get fallbackToEnglish;

  /// No description provided for @fallbackToEnglishDesc.
  ///
  /// In en, this message translates to:
  /// **'Use English dictionary if Vietnamese not found'**
  String get fallbackToEnglishDesc;

  /// No description provided for @selectDeck.
  ///
  /// In en, this message translates to:
  /// **'Select Deck'**
  String get selectDeck;

  /// No description provided for @addedToDeck.
  ///
  /// In en, this message translates to:
  /// **'Added to deck'**
  String get addedToDeck;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get useDarkTheme;

  /// No description provided for @studySettings.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get studySettings;

  /// No description provided for @newCardsPerDay.
  ///
  /// In en, this message translates to:
  /// **'New cards per day'**
  String get newCardsPerDay;

  /// No description provided for @reviewCardsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Review cards per day'**
  String get reviewCardsPerDay;

  /// No description provided for @showPhonetic.
  ///
  /// In en, this message translates to:
  /// **'Show phonetic'**
  String get showPhonetic;

  /// No description provided for @displayPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Display pronunciation on cards'**
  String get displayPronunciation;

  /// No description provided for @autoPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Auto-play audio'**
  String get autoPlayAudio;

  /// No description provided for @automaticallyPlayPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Automatically play pronunciation'**
  String get automaticallyPlayPronunciation;

  /// No description provided for @backupSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get backupSync;

  /// No description provided for @backupToCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup to Cloud'**
  String get backupToCloud;

  /// No description provided for @saveDataToCloud.
  ///
  /// In en, this message translates to:
  /// **'Save your data to the cloud'**
  String get saveDataToCloud;

  /// No description provided for @restoreFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get restoreFromCloud;

  /// No description provided for @restoreDataFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore your data from the cloud'**
  String get restoreDataFromCloud;

  /// No description provided for @firebaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase not configured'**
  String get firebaseNotConfigured;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync'**
  String get autoSync;

  /// No description provided for @autoSyncWhenOnline.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync when online'**
  String get autoSyncWhenOnline;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import & Export'**
  String get importExport;

  /// No description provided for @importFromJson.
  ///
  /// In en, this message translates to:
  /// **'Import from JSON file'**
  String get importFromJson;

  /// No description provided for @exportAllDecks.
  ///
  /// In en, this message translates to:
  /// **'Export All Decks'**
  String get exportAllDecks;

  /// No description provided for @exportToJson.
  ///
  /// In en, this message translates to:
  /// **'Export to JSON file'**
  String get exportToJson;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @resetAllData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get resetAllData;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all decks and cards'**
  String get deleteAllData;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data?'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your decks, flashcards, and study progress. This action cannot be undone.'**
  String get resetConfirmMessage;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @dataReset.
  ///
  /// In en, this message translates to:
  /// **'All data has been reset'**
  String get dataReset;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @numberOfCards.
  ///
  /// In en, this message translates to:
  /// **'Number of cards'**
  String get numberOfCards;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'created'**
  String get created;

  /// No description provided for @weeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weeklyActivity;

  /// No description provided for @deckProgress.
  ///
  /// In en, this message translates to:
  /// **'Deck Progress'**
  String get deckProgress;

  /// No description provided for @cardsLearnedCount.
  ///
  /// In en, this message translates to:
  /// **'{learned} / {total} cards learned'**
  String cardsLearnedCount(int learned, int total);

  /// No description provided for @dueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} due'**
  String dueCount(int count);

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noFeaturedDecks.
  ///
  /// In en, this message translates to:
  /// **'No featured decks yet'**
  String get noFeaturedDecks;

  /// No description provided for @noRatedDecks.
  ///
  /// In en, this message translates to:
  /// **'No rated decks yet'**
  String get noRatedDecks;

  /// No description provided for @noDecksYetSimple.
  ///
  /// In en, this message translates to:
  /// **'No decks yet'**
  String get noDecksYetSimple;

  /// No description provided for @noDecksFound.
  ///
  /// In en, this message translates to:
  /// **'No decks found'**
  String get noDecksFound;

  /// No description provided for @unableToConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to library'**
  String get unableToConnect;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @searchDecks.
  ///
  /// In en, this message translates to:
  /// **'Search decks...'**
  String get searchDecks;

  /// No description provided for @popularSearches.
  ///
  /// In en, this message translates to:
  /// **'Popular Searches'**
  String get popularSearches;

  /// No description provided for @browseByCategory.
  ///
  /// In en, this message translates to:
  /// **'Browse by Category'**
  String get browseByCategory;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or browse categories'**
  String get tryDifferentKeywords;

  /// No description provided for @decksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} decks'**
  String decksCount(int count);

  /// No description provided for @resultsFor.
  ///
  /// In en, this message translates to:
  /// **'{count} results for \"{query}\"'**
  String resultsFor(int count, String query);

  /// No description provided for @deckDetails.
  ///
  /// In en, this message translates to:
  /// **'Deck Details'**
  String get deckDetails;

  /// No description provided for @ratingsReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get ratingsReviews;

  /// No description provided for @previewCards.
  ///
  /// In en, this message translates to:
  /// **'Preview Cards'**
  String get previewCards;

  /// No description provided for @editReview.
  ///
  /// In en, this message translates to:
  /// **'Edit Review'**
  String get editReview;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating: '**
  String get yourRating;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @noCardsPreview.
  ///
  /// In en, this message translates to:
  /// **'No cards to preview'**
  String get noCardsPreview;

  /// No description provided for @alreadyImported.
  ///
  /// In en, this message translates to:
  /// **'Already Imported'**
  String get alreadyImported;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load deck'**
  String get failedToLoad;

  /// No description provided for @shareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share feature coming soon'**
  String get shareComingSoon;

  /// No description provided for @successfullyImported.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported \"{name}\"'**
  String successfullyImported(String name);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @failedToImport.
  ///
  /// In en, this message translates to:
  /// **'Failed to import: {error}'**
  String failedToImport(String error);

  /// No description provided for @downloadsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} downloads'**
  String downloadsCount(int count);

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @cardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String cardsCount(int count);

  /// No description provided for @publishDeck.
  ///
  /// In en, this message translates to:
  /// **'Publish Deck'**
  String get publishDeck;

  /// No description provided for @deckNotFound.
  ///
  /// In en, this message translates to:
  /// **'Deck not found'**
  String get deckNotFound;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @addTagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Add tags to help users find your deck'**
  String get addTagsHelp;

  /// No description provided for @publishingGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Publishing Guidelines'**
  String get publishingGuidelines;

  /// No description provided for @qualityContent.
  ///
  /// In en, this message translates to:
  /// **'Make sure your deck has quality content'**
  String get qualityContent;

  /// No description provided for @appropriateCategories.
  ///
  /// In en, this message translates to:
  /// **'Use appropriate categories and tags'**
  String get appropriateCategories;

  /// No description provided for @avoidCopyrighted.
  ///
  /// In en, this message translates to:
  /// **'Avoid copyrighted material'**
  String get avoidCopyrighted;

  /// No description provided for @canUpdateAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can update or unpublish anytime'**
  String get canUpdateAnytime;

  /// No description provided for @deckPublished.
  ///
  /// In en, this message translates to:
  /// **'Deck published successfully!'**
  String get deckPublished;

  /// No description provided for @myPublishedDecks.
  ///
  /// In en, this message translates to:
  /// **'My Published Decks'**
  String get myPublishedDecks;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @noPublishedDecks.
  ///
  /// In en, this message translates to:
  /// **'No Published Decks'**
  String get noPublishedDecks;

  /// No description provided for @shareWithCommunity.
  ///
  /// In en, this message translates to:
  /// **'Share your decks with the community'**
  String get shareWithCommunity;

  /// No description provided for @pushUpdate.
  ///
  /// In en, this message translates to:
  /// **'Push Update'**
  String get pushUpdate;

  /// No description provided for @syncChanges.
  ///
  /// In en, this message translates to:
  /// **'Sync changes from local deck'**
  String get syncChanges;

  /// No description provided for @unpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublish;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from public library'**
  String get removeFromLibrary;

  /// No description provided for @viewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get viewAnalytics;

  /// No description provided for @analyticsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Analytics coming soon'**
  String get analyticsComingSoon;

  /// No description provided for @updatingDeck.
  ///
  /// In en, this message translates to:
  /// **'Updating published deck...'**
  String get updatingDeck;

  /// No description provided for @unpublishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unpublish Deck?'**
  String get unpublishConfirm;

  /// No description provided for @unpublishDescription.
  ///
  /// In en, this message translates to:
  /// **'This will remove the deck from the public library. Users who already imported it will still have their copies.'**
  String get unpublishDescription;

  /// No description provided for @deckUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Deck unpublished'**
  String get deckUnpublished;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @availableUpdates.
  ///
  /// In en, this message translates to:
  /// **'Available Updates'**
  String get availableUpdates;

  /// No description provided for @decksHaveUpdates.
  ///
  /// In en, this message translates to:
  /// **'{count} decks have updates'**
  String decksHaveUpdates(int count);

  /// No description provided for @syncAll.
  ///
  /// In en, this message translates to:
  /// **'Sync All'**
  String get syncAll;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @updatedToVersion.
  ///
  /// In en, this message translates to:
  /// **'Updated to v{version}'**
  String updatedToVersion(int version);

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @noUpdatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No updates available'**
  String get noUpdatesAvailable;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteConfirmTitle(String name);

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteConfirmMessage(String name);

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get actionCannotBeUndone;

  /// No description provided for @unlinkDeck.
  ///
  /// In en, this message translates to:
  /// **'Unlink Deck'**
  String get unlinkDeck;

  /// No description provided for @unlinkDeckMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the connection to the original deck. You will no longer receive updates from the author.'**
  String get unlinkDeckMessage;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @deckUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Deck unlinked'**
  String get deckUnlinked;

  /// No description provided for @noFlashcardsYet.
  ///
  /// In en, this message translates to:
  /// **'No flashcards yet'**
  String get noFlashcardsYet;

  /// No description provided for @addFlashcardsToStart.
  ///
  /// In en, this message translates to:
  /// **'Add flashcards to start learning!'**
  String get addFlashcardsToStart;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @describeWhatDeckAbout.
  ///
  /// In en, this message translates to:
  /// **'Describe what this deck is about'**
  String get describeWhatDeckAbout;

  /// No description provided for @pleaseEnterDeckName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a deck name'**
  String get pleaseEnterDeckName;

  /// No description provided for @deckNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Japanese N5 Vocabulary'**
  String get deckNameHint;

  /// No description provided for @languageOfWordsToLearn.
  ///
  /// In en, this message translates to:
  /// **'The language of the words you want to learn'**
  String get languageOfWordsToLearn;

  /// No description provided for @updateDeck.
  ///
  /// In en, this message translates to:
  /// **'Update Deck'**
  String get updateDeck;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @imageOptional.
  ///
  /// In en, this message translates to:
  /// **'Image (optional)'**
  String get imageOptional;

  /// No description provided for @localFile.
  ///
  /// In en, this message translates to:
  /// **'Local File'**
  String get localFile;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @enterImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter image URL'**
  String get enterImageUrl;

  /// No description provided for @invalidImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid image URL'**
  String get invalidImageUrl;

  /// No description provided for @tapToAddImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to add image'**
  String get tapToAddImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get changeImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @frontImage.
  ///
  /// In en, this message translates to:
  /// **'Front Image'**
  String get frontImage;

  /// No description provided for @backImage.
  ///
  /// In en, this message translates to:
  /// **'Back Image'**
  String get backImage;

  /// No description provided for @shareImageOnBothSides.
  ///
  /// In en, this message translates to:
  /// **'Share image on both sides'**
  String get shareImageOnBothSides;

  /// No description provided for @shareImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the front image on the back side as well'**
  String get shareImageDescription;

  /// No description provided for @flashcardImageSize.
  ///
  /// In en, this message translates to:
  /// **'Flashcard Image Size'**
  String get flashcardImageSize;

  /// No description provided for @recommendedForMobile.
  ///
  /// In en, this message translates to:
  /// **'Recommended for mobile'**
  String get recommendedForMobile;

  /// No description provided for @recommendedForDesktop.
  ///
  /// In en, this message translates to:
  /// **'Recommended for desktop'**
  String get recommendedForDesktop;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @flashcardFontSize.
  ///
  /// In en, this message translates to:
  /// **'Flashcard Font Size'**
  String get flashcardFontSize;

  /// No description provided for @mainTextSize.
  ///
  /// In en, this message translates to:
  /// **'Main Text'**
  String get mainTextSize;

  /// No description provided for @phoneticTextSize.
  ///
  /// In en, this message translates to:
  /// **'Phonetic Text'**
  String get phoneticTextSize;

  /// No description provided for @detailTextSize.
  ///
  /// In en, this message translates to:
  /// **'Example & Note'**
  String get detailTextSize;

  /// No description provided for @fontSizePixels.
  ///
  /// In en, this message translates to:
  /// **'{size}px'**
  String fontSizePixels(int size);

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @extraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get extraLarge;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get signInWithEmail;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInGoogle;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get signInFailed;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signUpFailed;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get resetPasswordSent;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @cardStructure.
  ///
  /// In en, this message translates to:
  /// **'Card Structure'**
  String get cardStructure;

  /// No description provided for @cardStructureDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure which fields appear on front and back of cards'**
  String get cardStructureDesc;

  /// No description provided for @frontSide.
  ///
  /// In en, this message translates to:
  /// **'Front Side'**
  String get frontSide;

  /// No description provided for @backSide.
  ///
  /// In en, this message translates to:
  /// **'Back Side'**
  String get backSide;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'• Drag handle (≡): reorder within section\n• Drag entire field: move to other section'**
  String get dragToReorder;

  /// No description provided for @imageDisplay.
  ///
  /// In en, this message translates to:
  /// **'Image Display'**
  String get imageDisplay;

  /// No description provided for @imageDisplayDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose how images are displayed on cards'**
  String get imageDisplayDesc;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No Image'**
  String get noImage;

  /// No description provided for @bothSides.
  ///
  /// In en, this message translates to:
  /// **'Both Sides'**
  String get bothSides;

  /// No description provided for @frontOnly.
  ///
  /// In en, this message translates to:
  /// **'Front Only'**
  String get frontOnly;

  /// No description provided for @backOnly.
  ///
  /// In en, this message translates to:
  /// **'Back Only'**
  String get backOnly;

  /// No description provided for @fieldWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get fieldWord;

  /// No description provided for @fieldPhonetic.
  ///
  /// In en, this message translates to:
  /// **'Phonetic'**
  String get fieldPhonetic;

  /// No description provided for @fieldMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get fieldMeaning;

  /// No description provided for @fieldExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get fieldExample;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// No description provided for @lockedField.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedField;

  /// No description provided for @autoPlayTts.
  ///
  /// In en, this message translates to:
  /// **'Auto-play Pronunciation'**
  String get autoPlayTts;

  /// No description provided for @autoPlayTtsDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically play pronunciation when flipping cards'**
  String get autoPlayTtsDesc;

  /// No description provided for @ttsHelp.
  ///
  /// In en, this message translates to:
  /// **'TTS Installation Guide'**
  String get ttsHelp;

  /// No description provided for @ttsLanguagesMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing TTS Languages'**
  String get ttsLanguagesMissing;

  /// No description provided for @ttsLanguagesMissingDesc.
  ///
  /// In en, this message translates to:
  /// **'The following languages are not available for text-to-speech:'**
  String get ttsLanguagesMissingDesc;

  /// No description provided for @ttsInstallInstructions.
  ///
  /// In en, this message translates to:
  /// **'How to install TTS voices (Windows):'**
  String get ttsInstallInstructions;

  /// No description provided for @ttsStepOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Windows Settings'**
  String get ttsStepOpenSettings;

  /// No description provided for @ttsStepTimeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Go to Time & Language → Language'**
  String get ttsStepTimeLanguage;

  /// No description provided for @ttsStepAddLanguage.
  ///
  /// In en, this message translates to:
  /// **'Click \"Add a language\"'**
  String get ttsStepAddLanguage;

  /// No description provided for @ttsStepSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Search and add the language (e.g., Japanese, Chinese)'**
  String get ttsStepSelectLanguage;

  /// No description provided for @ttsStepDownloadSpeech.
  ///
  /// In en, this message translates to:
  /// **'Click on the language → Options → Download \"Speech\"'**
  String get ttsStepDownloadSpeech;

  /// No description provided for @ttsStepRestartApp.
  ///
  /// In en, this message translates to:
  /// **'Restart VocabFlip'**
  String get ttsStepRestartApp;

  /// No description provided for @ttsGenericInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please install TTS voices for your desired languages in your system settings.'**
  String get ttsGenericInstructions;

  /// No description provided for @dontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get dontShowAgain;

  /// No description provided for @ttsSettings.
  ///
  /// In en, this message translates to:
  /// **'TTS Settings'**
  String get ttsSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
