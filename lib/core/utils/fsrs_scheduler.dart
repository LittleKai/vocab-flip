import 'package:fsrs/fsrs.dart' as fsrs;
import 'spaced_repetition.dart';
import '../../data/models/card_srs_state.dart';

class FSRSScheduler implements SchedulerEngine {
  final fsrs.Scheduler _scheduler;

  FSRSScheduler() : _scheduler = fsrs.Scheduler(
    desiredRetention: 0.9,
  );

  @override
  ReviewResult review(CardSrsState state, ReviewRating rating, DateTime now) {
    // 1. Convert CardSrsState to fsrs.Card
    var fCard = _stateToFsrsCard(state, now);

    // 2. Map ReviewRating to fsrs.Rating
    final fRating = _mapRating(rating);

    // 3. Process review
    final result = _scheduler.reviewCard(fCard, fRating, reviewDateTime: now.toUtc());
    final newCard = result.card;

    // 4. Determine interval from due date (FSRS sets `due`)
    final nextReviewDateLocal = newCard.due.toLocal();
    final startOfNow = DateTime(now.year, now.month, now.day);
    final startOfNext = DateTime(nextReviewDateLocal.year, nextReviewDateLocal.month, nextReviewDateLocal.day);
    final newInterval = startOfNext.difference(startOfNow).inDays;
    
    // 5. Build ReviewResult
    // FSRS handles intervals and dates directly
    return ReviewResult(
      interval: newInterval > 0 ? newInterval : 0,
      repetitions: state.repetitions + 1,
      lapses: fRating == fsrs.Rating.again ? state.lapses + 1 : state.lapses,
      easinessFactor: state.easinessFactor, // Keep existing for backwards compatibility
      stability: newCard.stability,
      difficulty: newCard.difficulty,
      fsrsState: newCard.state.index,
      fsrsStep: 0, // In dart fsrs package 1.0.0, step is typically handled internally or not exposed. We set it to 0 or use elapsed days? Wait, fsrs.Card does not expose `step`.
      nextReviewDate: nextReviewDateLocal,
    );
  }

  fsrs.Card _stateToFsrsCard(CardSrsState state, DateTime now) {
    // If we have persisted FSRS state, use it directly!
    fsrs.State fState;
    if (state.fsrsState != null) {
      // Map integer to enum (0=new, 1=learning, 2=review, 3=relearning)
      final index = state.fsrsState!.clamp(0, 3);
      fState = fsrs.State.values[index];
    } else {
      // Fallback for migrated SM-2 cards
      if (state.stability == null || state.stability == 0) {
        fState = fsrs.State.learning;
      } else {
        fState = fsrs.State.review;
      }
    }

    // Fix FSRS Crash on Null Difficulty: if difficulty is null but state is review, reset state to learning to prevent Null check operator error.
    if (fState == fsrs.State.review && state.difficulty == null) {
      fState = fsrs.State.learning;
    }

    return fsrs.Card(
      cardId: DateTime.now().millisecondsSinceEpoch,
      state: fState,
      stability: state.stability,
      difficulty: state.difficulty,
      due: state.nextReviewDate?.toUtc() ?? now.toUtc(),
      lastReview: state.lastReviewDate?.toUtc(),
    );
  }

  fsrs.Rating _mapRating(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.again:
        return fsrs.Rating.again;
      case ReviewRating.hard:
        return fsrs.Rating.hard;
      case ReviewRating.good:
        return fsrs.Rating.good;
      case ReviewRating.easy:
        return fsrs.Rating.easy;
    }
  }

  /// Get preview of next review intervals for each rating option
  Map<ReviewRating, int> getIntervalPreviews(CardSrsState state, DateTime now) {
    final Map<ReviewRating, int> previews = {};
    
    for (final rating in ReviewRating.values) {
      final fCard = _stateToFsrsCard(state, now);
      final fRating = _mapRating(rating);
      final result = _scheduler.reviewCard(fCard, fRating, reviewDateTime: now.toUtc());
      final nextDateLocal = result.card.due.toLocal();
      final startOfNow = DateTime(now.year, now.month, now.day);
      final startOfNext = DateTime(nextDateLocal.year, nextDateLocal.month, nextDateLocal.day);
      final intervalDays = startOfNext.difference(startOfNow).inDays;
      previews[rating] = intervalDays > 0 ? intervalDays : 0;
    }
    
    return previews;
  }
}
