import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../../models/sync_queue_item.dart';

class SyncQueueDao {
  final AppDatabase _appDatabase;

  SyncQueueDao({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase();

  Future<Database> get _db => _appDatabase.database;

  Future<int> insert(SyncQueueItem item) async {
    if (kIsWeb) return 0;

    final db = await _db;
    return await db.insert(
      'sync_queue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueItem>> getPendingItems({int limit = 100}) async {
    if (kIsWeb) return [];

    final db = await _db;
    final maps = await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  Future<int> delete(String id) async {
    if (kIsWeb) return 0;

    final db = await _db;
    return await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    if (kIsWeb) return;

    final db = await _db;
    await db.delete('sync_queue');
  }
}
