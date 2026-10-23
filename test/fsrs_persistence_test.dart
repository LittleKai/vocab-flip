import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/core/utils/fsrs_scheduler.dart';
import 'package:vocabflip/core/utils/spaced_repetition.dart';
import 'package:vocabflip/data/models/card_srs_state.dart';
import 'package:vocabflip/data/models/flashcard.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);

  test('review state survives copy, SQLite/API map and backup JSON', () {
    final result =
        FSRSScheduler().review(const CardSrsState(), ReviewRating.good, now);
    final card =
        Flashcard(deckId: 'deck', front: 'one', back: 'mot', notes: 'note')
            .copyWith(
      repetitions: result.repetitions,
      stability: result.stability,
      difficulty: result.difficulty,
      fsrsState: result.fsrsState,
      fsrsStep: result.fsrsStep,
      nextReviewDate: result.nextReviewDate,
      lastReviewDate: now,
    );
    for (final restored in [
      card,
      Flashcard.fromMap(jsonDecode(jsonEncode(card.toMap()))),
      Flashcard.fromJson(jsonDecode(jsonEncode(card.toJson())), 'deck'),
    ]) {
      expect(restored.fsrsState, result.fsrsState);
      expect(restored.fsrsStep, 1);
      expect(restored.stability, result.stability);
      expect(restored.difficulty, result.difficulty);
      expect(restored.nextReviewDate, result.nextReviewDate);
      expect(restored.repetitions, result.repetitions);
      expect(restored.notes, 'note');
      expect(restored.lastReviewDate, now);
    }
  });

  test('learning step one graduates on Good', () {
    final result = FSRSScheduler().review(
        CardSrsState(
          fsrsState: 0,
          fsrsStep: 1,
          stability: 3.2,
          difficulty: 5,
          lastReviewDate: now.subtract(const Duration(minutes: 10)),
        ),
        ReviewRating.good,
        now);
    expect(result.fsrsState, 1);
    expect(result.fsrsStep, isNull);
    final learning = Flashcard(
        deckId: 'deck', front: 'one', back: 'mot', fsrsState: 0, fsrsStep: 1);
    expect(learning.copyWith(front: 'two').fsrsStep, 1);
    final graduated = learning.copyWith(
        fsrsState: result.fsrsState, fsrsStep: result.fsrsStep);
    expect(graduated.fsrsStep, isNull);
    expect(Flashcard.fromMap(graduated.toMap()).fsrsStep, isNull);
    expect(Flashcard.fromJson(graduated.toJson(), 'deck').fsrsStep, isNull);
    expect(learning.srsState.copyWith(fsrsStep: null).fsrsStep, isNull);
  });

  test(
      'relearning resumes stored step and missing legacy step defaults to zero',
      () {
    for (final step in [0, null]) {
      final result = FSRSScheduler().review(
          CardSrsState(
            fsrsState: 2,
            fsrsStep: step,
            stability: 3.2,
            difficulty: 5,
            lastReviewDate: now.subtract(const Duration(minutes: 10)),
          ),
          ReviewRating.hard,
          now);
      expect(result.fsrsState, 2);
      expect(result.fsrsStep, 0);
    }
  });

  test('old backup without notes or last review remains readable', () {
    final card = Flashcard.fromJson({'front': 'one', 'back': 'mot'}, 'deck');
    expect(card.notes, isNull);
    expect(card.lastReviewDate, isNull);
    expect(card.fsrsState, isNull);
  });
}
