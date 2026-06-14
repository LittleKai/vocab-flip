import 'package:flutter/foundation.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/study_session.dart';
import '../../data/repositories/flashcard_repository.dart';
import '../../data/repositories/study_analytics_repository.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../core/utils/spaced_repetition.dart';
import '../../core/utils/fsrs_scheduler.dart';
import '../../data/services/advanced_learning_science.dart';

enum StudyState {
  idle,
  loading,
  studying,
  showingAnswer,
  completed,
  error,
}

class StudyProvider extends ChangeNotifier {
  final FlashcardRepository _flashcardRepository;
  final StudyAnalyticsRepository _studyAnalyticsRepository;
  final AppPreferences _preferences;

  StudyState _state = StudyState.idle;
  List<Flashcard> _studyQueue = [];
  int _currentIndex = 0;
  StudySession? _currentSession;
  DateTime? _cardStartTime;

  int _cardsStudied = 0;
  int _cardsCorrect = 0;
  int _cardsIncorrect = 0;
  
  final AdvancedLearningScience _advancedLearning = AdvancedLearningScience();
  bool _isFatigued = false;
  bool get isFatigued => _isFatigued;

  bool _isShuffleMode = true;
  bool get isShuffleMode => _isShuffleMode;

  void toggleShuffleMode() {
    _isShuffleMode = !_isShuffleMode;
    if (_isShuffleMode) {
      shuffleCards();
    } else {
      if (_currentIndex + 1 < _studyQueue.length) {
        final remainingCards = _studyQueue.sublist(_currentIndex + 1);
        remainingCards.sort((a, b) => a.id.compareTo(b.id));
        _studyQueue = [
          ..._studyQueue.sublist(0, _currentIndex + 1),
          ...remainingCards,
        ];
      }
    }
    notifyListeners();
  }

  void resetFatigue() {
    _isFatigued = false;
    _advancedLearning.resetFatigue();
    notifyListeners();
  }

  StudyProvider({
    FlashcardRepository? flashcardRepository,
    StudyAnalyticsRepository? studyAnalyticsRepository,
    AppPreferences? preferences,
  })  : _flashcardRepository = flashcardRepository ?? FlashcardRepository(),
        _studyAnalyticsRepository =
            studyAnalyticsRepository ?? StudyAnalyticsRepository(),
        _preferences = preferences ?? AppPreferences();

  StudyState get state => _state;
  List<Flashcard> get studyQueue => _studyQueue;
  int get currentIndex => _currentIndex;
  Flashcard? get currentCard =>
      _studyQueue.isNotEmpty && _currentIndex < _studyQueue.length
          ? _studyQueue[_currentIndex]
          : null;
  StudySession? get currentSession => _currentSession;
  int get cardsStudied => _cardsStudied;
  int get cardsCorrect => _cardsCorrect;
  int get cardsIncorrect => _cardsIncorrect;
  int get cardsRemaining => _studyQueue.length - _currentIndex;

  double get progress {
    if (_studyQueue.isEmpty) return 0;
    return _currentIndex / _studyQueue.length;
  }

  double get accuracy {
    if (_cardsStudied == 0) return 0;
    return (_cardsCorrect / _cardsStudied) * 100;
  }

  Future<void> startStudySession(String deckId,
      {bool forceReload = false}) async {
    _state = StudyState.loading;
    notifyListeners();

    try {
      if (forceReload && _studyQueue.isNotEmpty) {
        // For "Study Again" - reshuffle the same cards
        _studyQueue.shuffle();
      } else {
        _studyQueue = await _flashcardRepository.getDueFlashcards(
          deckId,
          limit: _preferences.newCardsPerDay + _preferences.reviewCardsPerDay,
        );

        // If no due cards, load random cards for practice/cramming
        if (_studyQueue.isEmpty) {
          final allCards = await _flashcardRepository.getFlashcardsByDeckId(deckId);
          if (allCards.isNotEmpty) {
            allCards.shuffle();
            _studyQueue = allCards.take(_preferences.newCardsPerDay + _preferences.reviewCardsPerDay).toList();
          }
        }
      }

      if (_preferences.advancedLearningScience) {
        _studyQueue = _advancedLearning.applySemanticShuffle(_studyQueue);
      } else if (_isShuffleMode) {
        _studyQueue.shuffle();
      }

      if (_studyQueue.isEmpty) {
        _state = StudyState.completed;
        notifyListeners();
        return;
      }

      _currentIndex = 0;
      _cardsStudied = 0;
      _cardsCorrect = 0;
      _cardsIncorrect = 0;
      _isFatigued = false;
      _advancedLearning.resetFatigue();

      _currentSession = StudySession(deckId: deckId);
      await _studyAnalyticsRepository.startSession(_currentSession!);
      _cardStartTime = DateTime.now();

      _state = StudyState.studying;
      notifyListeners();
    } catch (e) {
      _state = StudyState.error;
      notifyListeners();
    }
  }

  void showAnswer() {
    if (_state == StudyState.studying) {
      _state = StudyState.showingAnswer;
      notifyListeners();
    }
  }

  Future<void> rateCard(ReviewRating rating) async {
    if (currentCard == null) return;

    try {
      final responseTime = _cardStartTime != null
          ? DateTime.now().difference(_cardStartTime!).inMilliseconds
          : 0;

      final updatedCard = await _flashcardRepository.reviewFlashcard(
        currentCard!,
        rating,
      );
      if (_currentSession != null) {
        await _studyAnalyticsRepository.logReview(
          before: currentCard!,
          after: updatedCard,
          rating: rating,
          sessionId: _currentSession!.id,
          responseTimeMs: responseTime,
        );
      }

      if (_preferences.advancedLearningScience) {
        final isCorrect = rating != ReviewRating.again && rating != ReviewRating.hard;
        _isFatigued = _advancedLearning.checkFatigue(isCorrect, responseTime);
      }

      _cardsStudied++;
      if (rating == ReviewRating.again) {
        _cardsIncorrect++;
        // Add card back to queue for review later
        _studyQueue.add(updatedCard);
      } else {
        _cardsCorrect++;
      }

      _currentIndex++;

      if (_currentIndex >= _studyQueue.length) {
        await _completeSession();
      } else {
        _cardStartTime = DateTime.now();
        _state = StudyState.studying;
        notifyListeners();
      }
    } catch (e) {
      _state = StudyState.error;
      notifyListeners();
    }
  }

  Future<void> _completeSession() async {
    _state = StudyState.completed;

    if (_currentSession != null) {
      final endedSession = _currentSession!.copyWith(
        endedAt: DateTime.now(),
        cardsStudied: _cardsStudied,
        cardsCorrect: _cardsCorrect,
        cardsIncorrect: _cardsIncorrect,
        totalTimeSeconds:
            DateTime.now().difference(_currentSession!.startedAt).inSeconds,
      );
      _currentSession = endedSession;
      await _studyAnalyticsRepository.completeSession(endedSession);

      // Update streak
      await _preferences.updateStreak();

      // Add study time
      await _preferences.addStudyTime(endedSession.totalTimeSeconds);
    }

    notifyListeners();
  }

  Map<ReviewRating, int> getIntervalPreviews() {
    if (currentCard == null) return {};
    return FSRSScheduler().getIntervalPreviews(
      currentCard!.srsState,
      DateTime.now(),
    );
  }

  void skipCard() {
    if (currentCard != null && _currentIndex < _studyQueue.length) {
      // Move current card to end of queue
      final card = _studyQueue.removeAt(_currentIndex);
      _studyQueue.add(card);
      _cardStartTime = DateTime.now();
      _state = StudyState.studying;
      notifyListeners();
    }
  }

  /// Shuffle remaining cards in the queue (preserving the current card)
  void shuffleCards() {
    if (_currentIndex + 1 >= _studyQueue.length) return;

    // Get remaining cards (after current index)
    final remainingCards = _studyQueue.sublist(_currentIndex + 1);
    remainingCards.shuffle();

    // Replace remaining portion with shuffled cards
    _studyQueue = [
      ..._studyQueue.sublist(0, _currentIndex + 1),
      ...remainingCards,
    ];

    _state = StudyState.studying;
    notifyListeners();
  }

  Future<void> saveAndCompleteSession() async {
    if (_currentSession != null && _cardsStudied > 0) {
      await _completeSession();
    }
    reset();
  }

  void reset() {
    _state = StudyState.idle;
    _studyQueue = [];
    _currentIndex = 0;
    _currentSession = null;
    _cardStartTime = null;
    _cardsStudied = 0;
    _cardsCorrect = 0;
    _cardsIncorrect = 0;
    notifyListeners();
  }
}
