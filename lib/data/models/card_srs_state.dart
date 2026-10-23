import '../../core/constants/app_constants.dart';

const _unchangedStep = Object();

class CardSrsState {
  final double easinessFactor;
  final int interval;
  final int repetitions;
  final int lapses;
  final double? stability;
  final double? difficulty;
  final int? fsrsState;
  final int? fsrsStep;
  final DateTime? nextReviewDate;
  final DateTime? lastReviewDate;

  const CardSrsState({
    this.easinessFactor = AppConstants.defaultEasinessFactor,
    this.interval = 0,
    this.repetitions = 0,
    this.lapses = 0,
    this.stability,
    this.difficulty,
    this.fsrsState,
    this.fsrsStep,
    this.nextReviewDate,
    this.lastReviewDate,
  });

  CardSrsState copyWith({
    double? easinessFactor,
    int? interval,
    int? repetitions,
    int? lapses,
    double? stability,
    double? difficulty,
    int? fsrsState,
    Object? fsrsStep = _unchangedStep,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    bool clearNextReviewDate = false,
  }) {
    return CardSrsState(
      easinessFactor: easinessFactor ?? this.easinessFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      fsrsState: fsrsState ?? this.fsrsState,
      fsrsStep: identical(fsrsStep, _unchangedStep)
          ? this.fsrsStep
          : fsrsStep as int?,
      nextReviewDate:
          clearNextReviewDate ? null : (nextReviewDate ?? this.nextReviewDate),
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
    );
  }
}
