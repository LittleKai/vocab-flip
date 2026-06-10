import '../../core/utils/spaced_repetition.dart';
import '../local/database/study_analytics_dao.dart';
import '../models/flashcard.dart';
import '../models/review_log.dart';
import '../models/study_session.dart';

class DailyStudyActivity {
  final DateTime day;
  final int cardsStudied;
  final int cardsCorrect;
  final int cardsIncorrect;
  final int totalTimeSeconds;

  const DailyStudyActivity({
    required this.day,
    required this.cardsStudied,
    required this.cardsCorrect,
    required this.cardsIncorrect,
    required this.totalTimeSeconds,
  });

  double get accuracy {
    if (cardsStudied == 0) return 0;
    return (cardsCorrect / cardsStudied) * 100;
  }
}

class StudyAnalyticsRepository {
  final StudyAnalyticsDao _dao;

  StudyAnalyticsRepository({StudyAnalyticsDao? dao})
      : _dao = dao ?? StudyAnalyticsDao();

  Future<void> startSession(StudySession session) {
    return _dao.insertSession(session);
  }

  Future<void> completeSession(StudySession session) {
    return _dao.updateSession(session);
  }

  Future<void> logReview({
    required Flashcard before,
    required Flashcard after,
    required ReviewRating rating,
    required String sessionId,
    required int responseTimeMs,
    DateTime? reviewedAt,
  }) {
    return _dao.insertReviewLog(
      ReviewLog(
        flashcardId: before.id,
        sessionId: sessionId,
        reviewedAt: reviewedAt,
        quality: SM2Scheduler.buttonToQuality(rating),
        responseTimeMs: responseTimeMs,
        easinessFactorBefore: before.easinessFactor,
        easinessFactorAfter: after.easinessFactor,
        intervalBefore: before.interval,
        intervalAfter: after.interval,
      ),
    );
  }

  Future<List<DailyStudyActivity>> getWeeklyActivity({DateTime? now}) async {
    final end = _dateOnly(now ?? DateTime.now());
    final start = DateTime(end.year, end.month, end.day - 6);
    final sessions = await _dao.getSessionsSince(start);
    final byDay = {
      for (var offset = 0; offset < 7; offset++)
        DateTime(start.year, start.month, start.day + offset): <StudySession>[],
    };

    for (final session in sessions) {
      final day = _dateOnly(session.startedAt);
      if (byDay.containsKey(day)) {
        byDay[day]!.add(session);
      }
    }

    return byDay.entries.map((entry) {
      final daySessions = entry.value;
      return DailyStudyActivity(
        day: entry.key,
        cardsStudied:
            daySessions.fold(0, (sum, item) => sum + item.cardsStudied),
        cardsCorrect:
            daySessions.fold(0, (sum, item) => sum + item.cardsCorrect),
        cardsIncorrect:
            daySessions.fold(0, (sum, item) => sum + item.cardsIncorrect),
        totalTimeSeconds:
            daySessions.fold(0, (sum, item) => sum + item.totalTimeSeconds),
      );
    }).toList();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
