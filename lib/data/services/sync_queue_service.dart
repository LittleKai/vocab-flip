import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../local/daos/sync_queue_dao.dart';
import '../models/sync_queue_item.dart';
import '../api/api_client.dart';
import '../local/preferences/app_preferences.dart';

class SyncQueueService {
  final SyncQueueDao _syncQueueDao;
  final ApiClient? _apiClient;
  final AppPreferences _prefs;
  final bool _disableLocalQueue;
  bool _isSyncing = false;

  SyncQueueService({
    SyncQueueDao? syncQueueDao,
    ApiClient? apiClient,
    AppPreferences? prefs,
    bool disableLocalQueue = kIsWeb,
  })  : _syncQueueDao = syncQueueDao ?? SyncQueueDao(),
        _apiClient = disableLocalQueue ? apiClient : (apiClient ?? ApiClient()),
        _prefs = prefs ?? AppPreferences(),
        _disableLocalQueue = disableLocalQueue;

  /// Drain the sync queue and push changes to the backend
  Future<void> syncPendingItems() async {
    if (_disableLocalQueue) return;
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = await _syncQueueDao.getPendingItems();
      if (pendingItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint(
          'SyncQueueService: Draining ${pendingItems.length} items from sync queue');

      for (final item in pendingItems) {
        try {
          await _processItem(item);
          // Only remove if successful or it's a non-retriable error
          await _syncQueueDao.delete(item.id);
        } catch (e) {
          debugPrint('SyncQueueService: Failed to process item ${item.id}: $e');
          // Break immediately to preserve strict queue ordering.
          // We cannot process subsequent items if a prerequisite (like a parent deck creation) fails.
          break;
        }
      }

      // Update cursor after successful sync
      await _prefs.setLastSyncCursor(DateTime.now());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processItem(SyncQueueItem item) async {
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

    switch (item.operation) {
      case 'CREATE':
        await _apiClient!.dio.post(path, data: dataMap);
        break;
      case 'UPDATE':
        await _apiClient!.dio.put(path, data: dataMap);
        break;
      case 'DELETE':
        await _apiClient!.dio.delete(path);
        break;
      default:
        throw Exception('Unknown operation: ${item.operation}');
    }
  }
}
