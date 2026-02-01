import 'package:flutter/foundation.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/study_session.dart';
import '../../data/repositories/flashcard_repository.dart';
import '../../data/local/preferences/app_preferences.dart';
import '../../core/utils/spaced_repetition.dart';

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
  final AppPreferences _preferences;

  StudyState _state = StudyState.idle;
  List<Flashcard> _studyQueue = [];
  int _currentIndex = 0;
  StudySession? _currentSession;
  DateTime? _cardStartTime;

  int _cardsStudied = 0;
  int _cardsCorrect = 0;
  int _cardsIncorrect = 0;

  StudyProvider({
    FlashcardRepository? flashcardRepository,
    AppPreferences? preferences,
  })  : _flashcardRepository = flashcardRepository ?? FlashcardRepository(),
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

  Future<void> startStudySession(String deckId, {bool forceReload = false}) async {
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

      _currentSession = StudySession(deckId: deckId);
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
      // TODO: Use responseTime for analytics
      // final responseTime = _cardStartTime != null
      //     ? DateTime.now().difference(_cardStartTime!).inMilliseconds
      //     : 0;

      final updatedCard = await _flashcardRepository.reviewFlashcard(
        currentCard!,
        rating,
      );

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
        totalTimeSeconds: DateTime.now()
            .difference(_currentSession!.startedAt)
            .inSeconds,
      );
      _currentSession = endedSession;

      // Update streak
      await _preferences.updateStreak();

      // Add study time
      await _preferences.addStudyTime(endedSession.totalTimeSeconds);
    }

    notifyListeners();
  }

  Map<ReviewRating, int> getIntervalPreviews() {
    if (currentCard == null) return {};
    return SM2Algorithm.getIntervalPreviews(
      repetitions: currentCard!.repetitions,
      easinessFactor: currentCard!.easinessFactor,
      interval: currentCard!.interval,
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

  /// Shuffle remaining cards in the queue
  void shuffleCards() {
    if (_currentIndex >= _studyQueue.length) return;

    // Get remaining cards (from current index to end)
    final remainingCards = _studyQueue.sublist(_currentIndex);
    remainingCards.shuffle();

    // Replace remaining portion with shuffled cards
    _studyQueue = [
      ..._studyQueue.sublist(0, _currentIndex),
      ...remainingCards,
    ];

    _state = StudyState.studying;
    notifyListeners();
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
