import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabflip/core/utils/spaced_repetition.dart';
import 'package:vocabflip/data/local/preferences/app_preferences.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/models/study_session.dart';
import 'package:vocabflip/data/repositories/flashcard_repository.dart';
import 'package:vocabflip/data/repositories/study_analytics_repository.dart';
import 'package:vocabflip/presentation/providers/study_provider.dart';

class MemoryCards extends FlashcardRepository {
  final Map<String, Flashcard> cards;
  Completer<void>? reviewGate;
  int reviewCount = 0;

  MemoryCards(List<Flashcard> items) : cards = {for (final c in items) c.id: c};

  @override
  Future<List<Flashcard>> getDueFlashcards(String deckId, {int? limit}) async =>
      cards.values.toList();

  @override
  Future<List<Flashcard>> getFlashcardsByDeckId(String deckId) async =>
      cards.values.toList();

  @override
  Future<Flashcard> reviewFlashcard(Flashcard card, ReviewRating rating) async {
    reviewCount++;
    await reviewGate?.future;
    final updated = card.copyWith(repetitions: card.repetitions + 1);
    cards[card.id] = updated;
    return updated;
  }
}

class MemoryAnalytics extends StudyAnalyticsRepository {
  final List<(String, String, String)> reviews = [];
  final List<StudySession> completions = [];
  Completer<void>? completionGate;
  Object? completionError;

  @override
  Future<void> startSession(StudySession session) async {}

  @override
  Future<void> completeSession(StudySession session) async {
    completions.add(session);
    await completionGate?.future;
    if (completionError != null) throw completionError!;
  }

  @override
  Future<void> logReview({
    required Flashcard before,
    required Flashcard after,
    required ReviewRating rating,
    required String sessionId,
    required int responseTimeMs,
    DateTime? reviewedAt,
  }) async =>
      reviews.add((before.id, after.id, sessionId));
}

void main() {
  setUp(() async {
    dotenv.testLoad(fileInput: '');
    SharedPreferences.setMockInitialValues({});
    await AppPreferences().init();
  });

  StudyProvider create(MemoryCards cards, MemoryAnalytics analytics) =>
      StudyProvider(
          flashcardRepository: cards, studyAnalyticsRepository: analytics)
        ..toggleShuffleMode();

  test('pending review rejects duplicate rating, skip and reset', () async {
    final cards = MemoryCards([
      Flashcard(id: 'a', deckId: 'deck', front: 'A', back: 'a'),
      Flashcard(id: 'b', deckId: 'deck', front: 'B', back: 'b'),
    ]);
    final analytics = MemoryAnalytics();
    final provider = create(cards, analytics);
    await provider.startStudySession('deck');
    final sessionId = provider.currentSession!.id;
    cards.reviewGate = Completer<void>();
    final review = provider.rateCard(ReviewRating.good);
    final duplicate = provider.rateCard(ReviewRating.easy);
    provider.skipCard();
    provider.reset();
    await provider.startStudySession('deck', forceReload: true);
    expect(provider.currentCard?.id, 'a');
    expect(provider.currentSession!.id, sessionId);
    expect(cards.reviewCount, 1);
    cards.reviewGate!.complete();
    await Future.wait([review, duplicate]);
    expect(provider.currentCard?.id, 'b');
    expect(provider.cardsStudied, 1);
    expect(analytics.reviews, [('a', 'a', sessionId)]);
  });

  test('a delayed rating cannot apply to the next attempt after Skip',
      () async {
    final cards = MemoryCards([
      Flashcard(id: 'a', deckId: 'deck', front: 'A', back: 'a'),
      Flashcard(id: 'b', deckId: 'deck', front: 'B', back: 'b'),
    ]);
    final analytics = MemoryAnalytics();
    final provider = create(cards, analytics);
    await provider.startStudySession('deck');
    final oldAttempt = provider.attempt;
    provider.skipCard();
    await provider.rateCard(ReviewRating.good, attempt: oldAttempt);
    expect(provider.currentCard?.id, 'b');
    expect(cards.reviewCount, 0);
    expect(analytics.reviews, isEmpty);
    await provider.rateCard(ReviewRating.good, attempt: provider.attempt);
    expect(cards.cards['b']!.repetitions, 1);
  });

  test('Study Again reloads unique cards with their latest saved progress',
      () async {
    final cards = MemoryCards([
      Flashcard(id: 'a', deckId: 'deck', front: 'A', back: 'a'),
    ]);
    final provider = create(cards, MemoryAnalytics());
    await provider.startStudySession('deck');
    await provider.rateCard(ReviewRating.again);
    await provider.rateCard(ReviewRating.easy);
    expect(cards.cards['a']!.repetitions, 2);
    await provider.startStudySession('deck', forceReload: true);
    expect(provider.studyQueue.length, 1);
    expect(provider.currentCard!.repetitions, 2);
    await provider.rateCard(ReviewRating.easy);
    expect(cards.cards['a']!.repetitions, 3);
  });

  test('pending exit completion rejects duplicate saves, reset and restart',
      () async {
    final cards = MemoryCards([
      Flashcard(id: 'a', deckId: 'deck', front: 'A', back: 'a'),
      Flashcard(id: 'b', deckId: 'deck', front: 'B', back: 'b'),
    ]);
    final analytics = MemoryAnalytics();
    final provider = create(cards, analytics);
    await provider.startStudySession('deck');
    await provider.rateCard(ReviewRating.good);
    final sessionId = provider.currentSession!.id;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    analytics.completionGate = Completer<void>();
    final exit = provider.saveAndCompleteSession();
    final duplicate = provider.saveAndCompleteSession();
    provider.reset();
    await provider.startStudySession('deck', forceReload: true);
    final wasSubmitting = provider.isSubmitting;
    final retainedSessionId = provider.currentSession?.id;
    analytics.completionGate!.complete();
    await Future.wait([exit, duplicate]);
    expect(wasSubmitting, isTrue);
    expect(retainedSessionId, sessionId);
    expect(analytics.completions.map((session) => session.id), [sessionId]);
    expect(
        analytics.completions.single.totalTimeSeconds, greaterThanOrEqualTo(1));
    expect(AppPreferences().totalStudyTime,
        analytics.completions.single.totalTimeSeconds);
    expect(provider.state, StudyState.idle);
  });

  test('closing an already completed session does not add its study time twice',
      () async {
    final analytics = MemoryAnalytics();
    final provider = create(
        MemoryCards([
          Flashcard(id: 'a', deckId: 'deck', front: 'A', back: 'a'),
        ]),
        analytics);
    await provider.startStudySession('deck');
    await provider.rateCard(ReviewRating.easy);
    await provider.saveAndCompleteSession();
    expect(analytics.completions, hasLength(1));
    expect(provider.state, StudyState.idle);
  });

  test('disposing during exit completion ignores the obsolete continuation',
      () async {
    final analytics = MemoryAnalytics();
    final provider = create(
        MemoryCards([
          Flashcard(id: 'a', deckId: 'deck', front: 'A', back: 'a'),
          Flashcard(id: 'b', deckId: 'deck', front: 'B', back: 'b'),
        ]),
        analytics);
    await provider.startStudySession('deck');
    await provider.rateCard(ReviewRating.good);
    analytics.completionGate = Completer<void>();
    final exit = provider.saveAndCompleteSession();
    provider.dispose();
    analytics.completionGate!.complete();
    await expectLater(exit, completes);
    expect(AppPreferences().totalStudyTime, 0);
  });

  test('failed exit completion releases the lock and retains the session',
      () async {
    final analytics = MemoryAnalytics();
    final provider = create(
        MemoryCards([
          Flashcard(id: 'a', deckId: 'deck', front: 'A', back: 'a'),
          Flashcard(id: 'b', deckId: 'deck', front: 'B', back: 'b'),
        ]),
        analytics);
    await provider.startStudySession('deck');
    await provider.rateCard(ReviewRating.good);
    final sessionId = provider.currentSession!.id;
    analytics.completionError = StateError('fixture completion failure');
    await expectLater(provider.saveAndCompleteSession(), throwsStateError);
    expect(provider.isSubmitting, isFalse);
    expect(provider.currentSession!.id, sessionId);
    expect(provider.currentSession!.isComplete, isFalse);
    analytics.completionError = null;
    await provider.saveAndCompleteSession();
    expect(provider.state, StudyState.idle);
  });
}
