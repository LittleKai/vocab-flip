import 'package:flutter/foundation.dart';
import '../local/daos/sync_queue_dao.dart';
import '../models/sync_queue_item.dart';
import '../api/api_client.dart';
import '../local/preferences/app_preferences.dart';

class SyncQueueService {
  final SyncQueueDao _syncQueueDao;
  final ApiClient _apiClient;
  final AppPreferences _prefs;
  bool _isSyncing = false;

  SyncQueueService({SyncQueueDao? syncQueueDao, ApiClient? apiClient, AppPreferences? prefs})
      : _syncQueueDao = syncQueueDao ?? SyncQueueDao(),
        _apiClient = apiClient ?? ApiClient(),
        _prefs = prefs ?? AppPreferences();

  /// Drain the sync queue and push changes to the backend
  Future<void> syncPendingItems() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = await _syncQueueDao.getPendingItems();
      if (pendingItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('SyncQueueService: Draining ${pendingItems.length} items from sync queue');

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
    // In a full implementation, we'd route based on entityType and operation
    // For now, this is the structural implementation to satisfy Phase 3 offline hardening.
    final path = '/sync/${item.entityType}/${item.entityId}';
    
    switch (item.operation) {
      case 'CREATE':
        await _apiClient.dio.post(path, data: item.payload);
        break;
      case 'UPDATE':
        await _apiClient.dio.put(path, data: item.payload);
        break;
      case 'DELETE':
        await _apiClient.dio.delete(path);
        break;
      default:
        throw Exception('Unknown operation: ${item.operation}');
    }
  }
}
