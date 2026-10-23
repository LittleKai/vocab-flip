import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../local/daos/sync_queue_dao.dart';
import '../models/sync_queue_item.dart';
import '../api/api_client.dart';
import '../local/preferences/app_preferences.dart';
import '../auth/alpha_auth_session.dart';
import '../remote/mongo/vocab_api_helpers.dart';

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
          // A known success acknowledges only this UUID, even after an account switch.
          await _syncQueueDao.delete(item.id);
          if (AlphaAuthSession().userId != owner) return;
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
    final version = ApiClient().sessionVersion;
    final options = Options(extra: {
      'syncOwnerUserId': owner,
      'sessionVersion': version,
    });
    final dio = _dio ?? _apiClient!.dio;
    switch (item.operation) {
      case 'CREATE':
        // These API fields test against false, whereas SQLite stores 0/1.
        for (final key in ['share_image', 'auto_play_tts_on_flip']) {
          if (dataMap is Map && dataMap[key] is num) {
            dataMap[key] = dataMap[key] != 0;
          }
        }
        try {
          await dio.post(path, data: dataMap, options: options);
        } on DioException catch (e) {
          if (e.response?.statusCode != 409) rethrow;
          if (AlphaAuthSession().userId != owner ||
              ApiClient().sessionVersion != version) {
            rethrow;
          }
          final lookup = item.entityType == 'deck'
              ? '/vocab/my-decks/${item.entityId}'
              : '/vocab/my-decks/cards/${item.entityId}';
          final response = await dio.get(lookup, options: options);
          final remote = unwrapApiMap(response.data);
          // ponytail: only identical persisted creates are acknowledged; actual
          // conflicts stay queued until a server idempotency contract exists.
          if (AlphaAuthSession().userId != owner ||
              ApiClient().sessionVersion != version ||
              remote == null ||
              !_matchesCreate(item, dataMap as Map, remote)) {
            rethrow;
          }
        }
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

  bool _matchesCreate(SyncQueueItem item, Map payload, Map remote) {
    Object? comparable(String key, Object? value) {
      if (key == 'name' && item.entityType == 'deck') {
        return (value as String?)?.trim();
      }
      if (key == 'tags' && value is String && value.isNotEmpty) {
        return value.split(',').map((tag) => tag.trim()).join(',');
      }
      if (key == 'deck_id' || (key == 'id' && item.entityType == 'deck')) {
        return (value as String?)?.toUpperCase();
      }
      if (key == 'next_review_date' || key == 'last_review_date') {
        return value == null
            ? null
            : DateTime.parse(value as String).millisecondsSinceEpoch;
      }
      if (value is bool) return value ? 1 : 0;
      // Optional strings are persisted as null by the CREATE endpoints.
      if (value == '' &&
          const {
            'description',
            'front_phonetic',
            'example',
            'notes',
            'image_url',
            'front_image_url',
            'back_image_url',
            'image_path',
            'category',
            'tags',
            'linked_public_deck_id',
            'published_deck_id',
            'front_fields',
            'back_fields',
          }.contains(key)) {
        return null;
      }
      return value;
    }

    if (payload['id'] != item.entityId || remote['id'] == null) return false;
    return payload.entries.every((entry) {
      final key = entry.key as String;
      if (key == 'created_at' || key == 'updated_at') return true;
      return remote.containsKey(key) &&
          comparable(key, entry.value) == comparable(key, remote[key]);
    });
  }
}
