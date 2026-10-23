import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../local/daos/sync_queue_dao.dart';
import '../models/sync_queue_item.dart';
import '../api/api_client.dart';
import '../local/preferences/app_preferences.dart';
import '../auth/alpha_auth_session.dart';

class SyncQueueService {
  final SyncQueueDao _syncQueueDao;
  final ApiClient? _apiClient;
  final AppPreferences _prefs;
  final bool _disableLocalQueue;
  final Dio? _dio;
  bool _isSyncing = false;

  SyncQueueService({
    SyncQueueDao? syncQueueDao,
    ApiClient? apiClient,
    AppPreferences? prefs,
    bool disableLocalQueue = kIsWeb,
    Dio? dio,
  })  : _syncQueueDao = syncQueueDao ?? SyncQueueDao(),
        _apiClient = disableLocalQueue || dio != null
            ? apiClient
            : (apiClient ?? ApiClient()),
        _dio = dio,
        _prefs = prefs ?? AppPreferences(),
        _disableLocalQueue = disableLocalQueue;

  /// Drain the sync queue and push changes to the backend
  Future<void> syncPendingItems() async {
    if (_disableLocalQueue) return;
    if (_isSyncing) return;
    final owner = AlphaAuthSession().userId;
    if (owner == null || owner.isEmpty) return;
    _isSyncing = true;

    try {
      final pendingItems = await _syncQueueDao.getPendingItems();
      if (AlphaAuthSession().userId != owner) return;
      if (pendingItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint(
          'SyncQueueService: Draining ${pendingItems.length} items from sync queue');

      for (final item in pendingItems) {
        if (AlphaAuthSession().userId != owner) return;
        try {
          final payload = jsonDecode(item.payload ?? '{}');
          if (payload is! Map || payload[SyncQueueDao.ownerKey] != owner) {
            continue;
          }
          await _processItem(item, owner);
          if (AlphaAuthSession().userId != owner) return;
          // Ownership markers survive delivery; remove only the delivered operation.
          await _syncQueueDao.delete(item.id);
        } catch (e) {
          debugPrint('SyncQueueService: Failed to process item ${item.id}: $e');
          // Break immediately to preserve strict queue ordering.
          // We cannot process subsequent items if a prerequisite (like a parent deck creation) fails.
          return;
        }
      }

      // Update cursor after successful sync
      if (AlphaAuthSession().userId == owner) {
        await _prefs.setLastSyncCursor(DateTime.now());
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processItem(SyncQueueItem item, String owner) async {
    String path = '';
    dynamic dataMap;

    if (item.payload != null && item.payload!.isNotEmpty) {
      try {
        dataMap = jsonDecode(item.payload!);
      } catch (e) {
        debugPrint(
            'SyncQueueService: Failed to decode payload for item ${item.id}: $e');
      }
    }
    if (dataMap is Map) dataMap.remove(SyncQueueDao.ownerKey);

    if (item.entityType == 'deck') {
      if (item.operation == 'CREATE') {
        path = '/vocab/my-decks';
      } else {
        path = '/vocab/my-decks/${item.entityId}';
      }
    } else if (item.entityType == 'flashcard') {
      if (item.operation == 'CREATE') {
        final deckId = dataMap != null ? dataMap['deck_id'] : null;
        if (deckId == null) {
          throw Exception(
              'Cannot create flashcard: deck_id is missing from payload');
        }
        path = '/vocab/my-decks/$deckId/cards';
      } else if (item.operation == 'UPDATE') {
        final deckId = dataMap != null ? dataMap['deck_id'] : null;
        if (deckId == null) {
          throw Exception(
              'Cannot update flashcard: deck_id is missing from payload');
        }
        path = '/vocab/my-decks/$deckId/cards/${item.entityId}';
      } else if (item.operation == 'DELETE') {
        path = '/vocab/my-decks/any/cards/${item.entityId}';
      }
    } else {
      throw Exception('Unknown entityType: ${item.entityType}');
    }

    if (AlphaAuthSession().userId != owner) {
      throw StateError('Sync account changed');
    }
    final options = Options(extra: {'syncOwnerUserId': owner});
    final dio = _dio ?? _apiClient!.dio;
    switch (item.operation) {
      case 'CREATE':
        await dio.post(path, data: dataMap, options: options);
        break;
      case 'UPDATE':
        await dio.put(path, data: dataMap, options: options);
        break;
      case 'DELETE':
        await dio.delete(path, options: options);
        break;
      default:
        throw Exception('Unknown operation: ${item.operation}');
    }
  }
}
