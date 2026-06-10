import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/review_log.dart';
import '../../models/study_session.dart';
import 'app_database.dart';

class StudyAnalyticsDao {
  final AppDatabase _appDatabase;

  StudyAnalyticsDao({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase();

  Future<Database> get _db => _appDatabase.database;

  Future<void> insertSession(StudySession session) async {
    if (kIsWeb) return;

    final db = await _db;
    await db.insert(
      AppConstants.tableStudySessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSession(StudySession session) async {
    if (kIsWeb) return;

    final db = await _db;
    await db.update(
      AppConstants.tableStudySessions,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> insertReviewLog(ReviewLog log) async {
    if (kIsWeb) return;

    final db = await _db;
    await db.insert(
      AppConstants.tableReviewLogs,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudySession>> getSessionsSince(DateTime start) async {
    if (kIsWeb) return [];

    final db = await _db;
    final maps = await db.query(
      AppConstants.tableStudySessions,
      where: 'started_at >= ?',
      whereArgs: [start.toIso8601String()],
      orderBy: 'started_at ASC',
    );

    return maps.map(StudySession.fromMap).toList();
  }

  Future<List<ReviewLog>> getReviewLogsSince(DateTime start) async {
    if (kIsWeb) return [];

    final db = await _db;
    final maps = await db.query(
      AppConstants.tableReviewLogs,
      where: 'reviewed_at >= ?',
      whereArgs: [start.toIso8601String()],
      orderBy: 'reviewed_at ASC',
    );

    return maps.map(ReviewLog.fromMap).toList();
  }

  Future<Map<DateTime, int>> getHeatmapData(DateTime startDate) async {
    if (kIsWeb) return {};

    final db = await _db;
    final results = await db.rawQuery('''
      SELECT substr(started_at, 1, 10) as date_str, SUM(cards_studied) as total
      FROM ${AppConstants.tableStudySessions}
      WHERE started_at >= ?
      GROUP BY substr(started_at, 1, 10)
    ''', [startDate.toIso8601String()]);

    final Map<DateTime, int> heatmap = {};
    for (final row in results) {
      final dateStr = row['date_str'] as String?;
      if (dateStr == null) continue;
      final total = (row['total'] as num?)?.toInt() ?? 0;
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        heatmap[DateTime(parsedDate.year, parsedDate.month, parsedDate.day)] = total;
      }
    }
    return heatmap;
  }
}
