import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../../models/sync_queue_item.dart';
import '../../auth/alpha_auth_session.dart';

class SyncQueueDao {
  final AppDatabase _appDatabase;
  final Database? _database;

  SyncQueueDao({AppDatabase? appDatabase, Database? database})
      : _appDatabase = appDatabase ?? AppDatabase(),
        _database = database;

  Future<Database> get _db async => _database ?? await _appDatabase.database;

  static const ownerKey = '_sync_owner_user_id';

  /// Metadata stays in the existing queue payload, including durable ownership
  /// markers after delivery. Legacy/guest entities remain quarantined.
  Future<void> writeEntities(
      List<SyncQueueItem> items, Future<void> Function(Transaction txn) mutate,
      {required String? ownerUserId}) async {
    final db = await _db;
    await db.transaction((txn) async {
      await mutate(txn);
      for (final item in items) {
        await _enqueue(txn, item, ownerUserId);
      }
    });
  }

  Future<void> _enqueue(
      DatabaseExecutor db, SyncQueueItem item, String? origin) async {
    final data = item.payload == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(item.payload!) as Map);
    final markerId = 'owner:${item.entityType}:${item.entityId}';
    final markers =
        await db.query('sync_queue', where: 'id = ?', whereArgs: [markerId]);
    String? owner;
    if (markers.isNotEmpty) {
      owner = (jsonDecode(markers.first['payload'] as String) as Map)[ownerKey]
          as String?;
      if (owner != origin) owner = null;
    } else if (item.operation == 'CREATE') {
      owner = origin;
      if (item.entityType == 'flashcard') {
        final parents = await db.query('sync_queue',
            where: 'id = ?', whereArgs: ['owner:deck:${data['deck_id']}']);
        owner = parents.isEmpty
            ? null
            : (jsonDecode(parents.first['payload'] as String) as Map)[ownerKey]
                as String?;
        if (owner != origin) owner = null;
      }
    }
    data[ownerKey] = owner;
    final row = {...item.toMap(), 'payload': jsonEncode(data)};
    await db.insert(
        'sync_queue',
        {
          ...row,
          'id': markerId,
          'operation': 'OWNER',
          'payload': jsonEncode({ownerKey: owner})
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('sync_queue', row,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> insert(SyncQueueItem item) async {
    if (kIsWeb) return 0;
    final owner = AlphaAuthSession().userId;
    final db = await _db;
    await db.transaction((txn) => _enqueue(txn, item, owner));
    return 1;
  }

  Future<List<SyncQueueItem>> getPendingItems({int limit = 100}) async {
    if (kIsWeb) return [];

    final db = await _db;
    final maps = await db.query(
      'sync_queue',
      where: 'operation != ?',
      whereArgs: ['OWNER'],
      orderBy: 'created_at ASC, rowid ASC',
    );
    final owner = AlphaAuthSession().userId;
    if (owner == null) return [];
    return maps
        .map(SyncQueueItem.fromMap)
        .where((item) {
          try {
            return (jsonDecode(item.payload ?? '{}') as Map)[ownerKey] == owner;
          } catch (_) {
            return false;
          }
        })
        .take(limit)
        .toList();
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
