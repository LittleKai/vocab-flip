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
