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
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;
  int _generation = 0;
  int _attempt = 0;
  int get attempt => _attempt;

  int _cardsStudied = 0;
  int _cardsCorrect = 0;
  int _cardsIncorrect = 0;

  final AdvancedLearningScience _advancedLearning = AdvancedLearningScience();
  bool _isFatigued = false;
  bool get isFatigued => _isFatigued;

  bool _isShuffleMode = true;
  bool get isShuffleMode => _isShuffleMode;

  void toggleShuffleMode() {
    if (_isSubmitting) return;
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
    if (_isSubmitting) return;
    final generation = ++_generation;
    final previousIds = _studyQueue.map((card) => card.id).toSet();
    _attempt++;
    _state = StudyState.loading;
    notifyListeners();

    try {
      List<Flashcard> queue;
      if (forceReload && previousIds.isNotEmpty) {
        final fresh = await _flashcardRepository.getFlashcardsByDeckId(deckId);
        queue = fresh.where((card) => previousIds.contains(card.id)).toList();
      } else {
        queue = await _flashcardRepository.getDueFlashcards(
          deckId,
          limit: _preferences.newCardsPerDay + _preferences.reviewCardsPerDay,
        );

        // If no due cards, load random cards for practice/cramming
        if (queue.isEmpty) {
          final allCards =
              await _flashcardRepository.getFlashcardsByDeckId(deckId);
          if (allCards.isNotEmpty) {
            allCards.shuffle();
            queue = allCards
                .take(_preferences.newCardsPerDay +
                    _preferences.reviewCardsPerDay)
                .toList();
          }
        }
      }
      if (generation != _generation) return;
      queue = {for (final card in queue) card.id: card}.values.toList();

      if (_preferences.advancedLearningScience) {
        queue = _advancedLearning.applySemanticShuffle(queue);
      } else if (_isShuffleMode) {
        queue.shuffle();
      }
      _studyQueue = queue;
      _currentIndex = 0;
      _cardsStudied = 0;
      _cardsCorrect = 0;
      _cardsIncorrect = 0;
      _isFatigued = false;
      _advancedLearning.resetFatigue();
      _currentSession = null;
      _cardStartTime = null;

      if (_studyQueue.isEmpty) {
        _state = StudyState.completed;
        notifyListeners();
        return;
      }

      final session = StudySession(deckId: deckId);
      _currentSession = session;
      await _studyAnalyticsRepository.startSession(session);
      if (generation != _generation) return;
      _cardStartTime = DateTime.now();

      _state = StudyState.studying;
      notifyListeners();
    } catch (e) {
      if (generation != _generation) return;
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

  Future<void> rateCard(ReviewRating rating, {int? attempt}) async {
    final card = currentCard;
    final session = _currentSession;
    if (_isSubmitting ||
        card == null ||
        session == null ||
        (attempt != null && attempt != _attempt) ||
        (_state != StudyState.studying && _state != StudyState.showingAnswer)) {
      return;
    }
    final generation = _generation;
    _isSubmitting = true;
    notifyListeners();

    try {
      final responseTime = _cardStartTime != null
          ? DateTime.now().difference(_cardStartTime!).inMilliseconds
          : 0;

      final updatedCard = await _flashcardRepository.reviewFlashcard(
        card,
        rating,
      );
      if (generation != _generation) return;
      await _studyAnalyticsRepository.logReview(
        before: card,
        after: updatedCard,
        rating: rating,
        sessionId: session.id,
        responseTimeMs: responseTime,
      );
      if (generation != _generation) return;
      _studyQueue = _studyQueue
          .map((item) => item.id == card.id ? updatedCard : item)
          .toList();

      if (_preferences.advancedLearningScience) {
        final isCorrect =
            rating != ReviewRating.again && rating != ReviewRating.hard;
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
      _attempt++;

      if (_currentIndex >= _studyQueue.length) {
        await _completeSession();
      } else {
        _cardStartTime = DateTime.now();
        _state = StudyState.studying;
        notifyListeners();
      }
    } catch (e) {
      if (generation != _generation) return;
      _state = StudyState.error;
    } finally {
      _isSubmitting = false;
      if (generation == _generation) notifyListeners();
    }
  }

  Future<void> _completeSession() async {
    final generation = _generation;
    final session = _currentSession;
    _state = StudyState.completed;

    if (session != null && !session.isComplete) {
      final endedSession = session.copyWith(
        endedAt: DateTime.now(),
        cardsStudied: _cardsStudied,
        cardsCorrect: _cardsCorrect,
        cardsIncorrect: _cardsIncorrect,
        totalTimeSeconds:
            DateTime.now().difference(session.startedAt).inSeconds,
      );
      await _studyAnalyticsRepository.completeSession(endedSession);
      if (generation != _generation) return;

      // Update streak
      await _preferences.updateStreak();
      if (generation != _generation) return;

      // Add study time
      await _preferences.addStudyTime(endedSession.totalTimeSeconds);
      if (generation != _generation) return;
      _currentSession = endedSession;
    }

    if (generation == _generation) notifyListeners();
  }

  Map<ReviewRating, int> getIntervalPreviews() {
    if (currentCard == null) return {};
    return FSRSScheduler().getIntervalPreviews(
      currentCard!.srsState,
      DateTime.now(),
    );
  }

  void skipCard() {
    if (_isSubmitting ||
        (_state != StudyState.studying && _state != StudyState.showingAnswer)) {
      return;
    }
    if (currentCard != null && _currentIndex < _studyQueue.length) {
      // Move current card to end of queue
      final card = _studyQueue.removeAt(_currentIndex);
      _studyQueue.add(card);
      _attempt++;
      _cardStartTime = DateTime.now();
      _state = StudyState.studying;
      notifyListeners();
    }
  }

  /// Shuffle remaining cards in the queue (preserving the current card)
  void shuffleCards() {
    if (_isSubmitting) return;
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
    if (_isSubmitting) return;
    final generation = _generation;
    _isSubmitting = true;
    notifyListeners();
    var saved = false;
    try {
      if (_currentSession != null && _cardsStudied > 0) {
        await _completeSession();
      }
      saved = true;
    } finally {
      _isSubmitting = false;
      if (generation == _generation) {
        if (saved) {
          reset();
        } else {
          notifyListeners();
        }
      }
    }
  }

  void reset() {
    if (_isSubmitting) return;
    _generation++;
    _attempt++;
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

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
