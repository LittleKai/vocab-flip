import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabflip/data/api/api_client.dart';
import 'package:vocabflip/data/auth/alpha_auth_session.dart';
import 'package:vocabflip/data/local/preferences/app_preferences.dart';
import 'package:vocabflip/data/local/daos/sync_queue_dao.dart';
import 'package:vocabflip/data/models/sync_queue_item.dart';
import 'package:vocabflip/data/models/deck.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/services/sync_queue_service.dart';
import 'package:vocabflip/presentation/providers/sync_provider.dart';

void main() {
  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=https://example.test/api');
    SharedPreferences.setMockInitialValues({});
    await AppPreferences().init();
    AlphaAuthSession().clear();
  });
  tearDown(() => AlphaAuthSession().clear());
  test(
      'syncPendingItems does not read the SQLite queue when local queue is disabled',
      () async {
    final dao = _ThrowingSyncQueueDao();
    final service = SyncQueueService(
      syncQueueDao: dao,
      disableLocalQueue: true,
    );

    await service.syncPendingItems();

    expect(dao.wasTouched, isFalse);
  });

  test('guest legacy and foreign queue entries are never dispatched or removed',
      () async {
    final queue = _Queue([
      _item('legacy'),
      _item('guest', owner: null),
      _item('foreign', owner: 'A'),
      _item('mine', owner: 'B'),
    ]);
    final adapter = _Adapter();
    final service = SyncQueueService(
        syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter);
    await service.syncPendingItems();
    expect(adapter.requests, isEmpty);
    AlphaAuthSession().setUser(userId: 'B');
    await service.syncPendingItems();
    expect(adapter.requests.map((request) => request.data['id']), ['mine']);
    expect(adapter.requests.single.data.containsKey(SyncQueueDao.ownerKey),
        isFalse);
    expect(queue.deleted, ['mine']);
  });

  test(
      'account switch after success acknowledges delivery and stops subsequent requests',
      () async {
    AlphaAuthSession().setUser(userId: 'A');
    final queue = _Queue([_item('one', owner: 'A'), _item('two', owner: 'A')]);
    final adapter =
        _Adapter(onRequest: () => AlphaAuthSession().setUser(userId: 'B'));
    await SyncQueueService(
            syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter)
        .syncPendingItems();
    expect(adapter.requests.length, 1);
    expect(queue.deleted, ['one']);
    expect(AppPreferences().lastSyncCursor, isNull);
  });

  test(
      'returning account drains remaining work without replaying successful CREATE',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = ApiClient();
    final previousAdapter = client.dio.httpClientAdapter;
    addTearDown(() async {
      await client.clearToken();
      client.dio.httpClientAdapter = previousAdapter;
    });
    await client.setToken('dummy-A');
    AlphaAuthSession().setUser(userId: 'A');
    final queue = _Queue([
      SyncQueueItem(
          id: 'create-deck-A',
          entityType: 'deck',
          entityId: 'deck-A',
          operation: 'CREATE',
          payload: jsonEncode({'id': 'deck-A', SyncQueueDao.ownerKey: 'A'})),
      SyncQueueItem(
          id: 'create-card-A',
          entityType: 'flashcard',
          entityId: 'card-A',
          operation: 'CREATE',
          payload: jsonEncode({
            'id': 'card-A',
            'deck_id': 'deck-A',
            SyncQueueDao.ownerKey: 'A'
          })),
    ]);
    final adapter = _DuplicateRejectingAdapter(onFirstCreate: () async {
      await client.setToken('dummy-B');
      AlphaAuthSession().setUser(userId: 'B');
    });
    client.dio.httpClientAdapter = adapter;
    final service = SyncQueueService(syncQueueDao: queue, apiClient: client);

    await service.syncPendingItems();

    expect(queue.deleted, ['create-deck-A']);
    expect((await queue.getPendingItems()).map((item) => item.id),
        ['create-card-A']);
    expect(adapter.created, {'/vocab/my-decks:deck-A'});
    expect(adapter.requests.length, 1);
    expect(AppPreferences().lastSyncCursor, isNull);
    await service.syncPendingItems();
    expect(adapter.requests.length, 1);
    expect(queue.deleted, ['create-deck-A']);

    await client.setToken('dummy-A');
    AlphaAuthSession().setUser(userId: 'A');
    await service.syncPendingItems();

    expect(queue.deleted, ['create-deck-A', 'create-card-A']);
    expect(await queue.getPendingItems(), isEmpty);
    expect(adapter.requests.map((request) => request.data['id']),
        ['deck-A', 'card-A']);
    expect(adapter.created,
        {'/vocab/my-decks:deck-A', '/vocab/my-decks/deck-A/cards:card-A'});
    expect(adapter.requests.map((request) => request.headers['Authorization']),
        ['Bearer dummy-A', 'Bearer dummy-A']);
    expect(adapter.requests.map((request) => request.extra['syncOwnerUserId']),
        ['A', 'A']);
    expect(AppPreferences().lastSyncCursor, isNotNull);
  });

  test(
      'failed prerequisite stops queue without advancing successful sync cursor',
      () async {
    AlphaAuthSession().setUser(userId: 'A');
    final queue = _Queue([_item('one', owner: 'A'), _item('two', owner: 'A')]);
    final adapter = _Adapter(status: 503);
    await SyncQueueService(
            syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter)
        .syncPendingItems();
    expect(adapter.requests.length, 1);
    expect(queue.deleted, isEmpty);
    expect(AppPreferences().lastSyncCursor, isNull);
  });

  for (final type in ['deck', 'flashcard']) {
    test(
        '$type CREATE with lost response reconciles before draining later work',
        () async {
      AlphaAuthSession().setUser(userId: 'A');
      final item = _createItem(type);
      final queue = _Queue([item, _item('later', owner: 'A')]);
      final adapter = _LostResponseAdapter();
      final service = SyncQueueService(
          syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter);

      await service.syncPendingItems();
      expect(queue.deleted, isEmpty);
      expect(AppPreferences().lastSyncCursor, isNull);
      await service.syncPendingItems();

      expect(queue.deleted, [item.id, 'later']);
      expect(adapter.creates, 2); // One entity plus the subsequent deck.
      expect(adapter.requests.map((r) => r.method),
          ['POST', 'POST', 'GET', 'POST']);
      expect(
          adapter.requests[2].path,
          type == 'deck'
              ? '/vocab/my-decks/deck'
              : '/vocab/my-decks/cards/card');
      expect(adapter.requests.every((r) => r.extra['syncOwnerUserId'] == 'A'),
          isTrue);
      expect(AppPreferences().lastSyncCursor, isNotNull);
    });
  }

  for (final mismatch in [
    {'id': 'other'},
    {'deck_id': 'other'},
    {'back': 'different'},
    {'fsrs_step': 1},
    {'share_image': 1},
    {'notes': 'different'},
    {'last_review_date': '2025-01-02T00:00:00Z'},
  ]) {
    test('conflicting CREATE retains queue when remote differs: $mismatch',
        () async {
      AlphaAuthSession().setUser(userId: 'A');
      final queue =
          _Queue([_createItem('flashcard'), _item('later', owner: 'A')]);
      final adapter = _LostResponseAdapter(remoteChanges: mismatch);
      final service = SyncQueueService(
          syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter);
      await service.syncPendingItems();
      await service.syncPendingItems();
      expect(queue.deleted, isEmpty);
      expect(adapter.creates, 1);
      expect(AppPreferences().lastSyncCursor, isNull);
    });
  }

  for (final status in [404, 503]) {
    test('failed CREATE reconciliation ($status) retains prerequisite',
        () async {
      AlphaAuthSession().setUser(userId: 'A');
      final queue = _Queue([_createItem('deck'), _item('later', owner: 'A')]);
      final adapter = _LostResponseAdapter(getStatus: status);
      final service = SyncQueueService(
          syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter);
      await service.syncPendingItems();
      await service.syncPendingItems();
      expect(queue.deleted, isEmpty);
      expect(adapter.creates, 1);
      expect(AppPreferences().lastSyncCursor, isNull);
    });
  }

  test('account change during reconciliation does not acknowledge or continue',
      () async {
    AlphaAuthSession().setUser(userId: 'A');
    final queue = _Queue([_createItem('deck'), _item('later', owner: 'A')]);
    final adapter = _LostResponseAdapter(
        onGet: () => AlphaAuthSession().setUser(userId: 'B'));
    final service = SyncQueueService(
        syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter);
    await service.syncPendingItems();
    await service.syncPendingItems();
    expect(queue.deleted, isEmpty);
    expect(adapter.creates, 1);
    expect(AppPreferences().lastSyncCursor, isNull);
  });

  test('same-account token replacement invalidates in-flight reconciliation',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = ApiClient();
    await client.setToken('dummy-A');
    AlphaAuthSession().setUser(userId: 'A');
    addTearDown(client.clearToken);
    Future<void>? rotating;
    final queue = _Queue([_createItem('deck'), _item('later', owner: 'A')]);
    final adapter = _LostResponseAdapter(onGet: () {
      rotating = client.setToken('dummy-new-A');
      AlphaAuthSession().setUser(userId: 'A');
    });
    final service = SyncQueueService(
        syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter);
    await service.syncPendingItems();
    await service.syncPendingItems();
    await rotating;
    expect(queue.deleted, isEmpty);
    expect(adapter.creates, 1);
    expect(AppPreferences().lastSyncCursor, isNull);
  });

  test('SyncProvider.syncAll never stamps successful cursor after failed drain',
      () async {
    AlphaAuthSession().setUser(userId: 'A');
    final previous = DateTime.utc(2025, 1, 1);
    await AppPreferences().setLastSyncCursor(previous);
    final queue = _Queue([_item('one', owner: 'A')]);
    final adapter = _Adapter(status: 503);
    final provider = SyncProvider(
        syncQueueService: SyncQueueService(
            syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter));
    await provider.syncAll();
    expect(AppPreferences().lastSyncCursor, previous);
    expect(queue.deleted, isEmpty);
    provider.dispose();
  });
}

SyncQueueItem _item(String id, {String? owner}) => SyncQueueItem(
    id: id,
    entityType: 'deck',
    entityId: id,
    operation: 'CREATE',
    payload: jsonEncode(
        {'id': id, if (id != 'legacy') SyncQueueDao.ownerKey: owner}));

SyncQueueItem _createItem(String type) => SyncQueueItem(
    id: 'create-$type',
    entityType: type,
    entityId: type == 'deck' ? 'deck' : 'card',
    operation: 'CREATE',
    payload: jsonEncode({
      ...(type == 'deck'
          ? Deck(
                  id: 'deck',
                  name: ' Deck ',
                  sourceLanguage: 'en',
                  tags: [' alpha ', 'beta'],
                  autoPlayTtsOnFlip: false)
              .toMap()
          : Flashcard(
                  id: 'card',
                  deckId: 'deck',
                  front: 'word',
                  back: 'meaning',
                  shareImage: false,
                  notes: '',
                  tags: [' alpha ', 'beta'],
                  fsrsState: 2,
                  fsrsStep: null,
                  lastReviewDate: DateTime.parse('2025-01-01T07:00:00+07:00'))
              .toMap()),
      SyncQueueDao.ownerKey: 'A',
    }));

/// Stores POST before losing its response, like a server-side committed timeout.
class _LostResponseAdapter implements HttpClientAdapter {
  final Map<String, dynamic> remoteChanges;
  final int getStatus;
  final void Function()? onGet;
  final requests = <RequestOptions>[];
  Map<String, dynamic>? stored;
  int creates = 0;
  _LostResponseAdapter(
      {this.remoteChanges = const {}, this.getStatus = 200, this.onGet});
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests.add(options);
    if (options.method == 'GET') {
      onGet?.call();
      return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              ...stored!,
              ...remoteChanges,
            }
          }),
          getStatus,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    final body = Map<String, dynamic>.from(options.data as Map);
    if (stored != null &&
        body['id'] == stored!['id'].toString().toLowerCase()) {
      return ResponseBody.fromString('{}', 409);
    }
    creates++;
    if (stored == null) {
      stored = {
        ...body,
        if (body.containsKey('name')) 'name': body['name'].toString().trim(),
        'tags':
            body['tags'].toString().split(',').map((t) => t.trim()).join(','),
        if (body['notes'] == '') 'notes': null,
        'id': body.containsKey('deck_id')
            ? body['id']
            : body['id'].toString().toUpperCase(),
        if (body.containsKey('deck_id'))
          'deck_id': body['deck_id'].toString().toUpperCase(),
        // Backend assigns timestamps and serializes dates in UTC milliseconds.
        'created_at': '2026-10-23T00:00:00.000Z',
        'updated_at': '2026-10-23T00:00:00.000Z',
        if (body.containsKey('last_review_date'))
          'last_review_date': '2025-01-01T00:00:00.000Z',
        if (body.containsKey('share_image'))
          'share_image': body['share_image'] == false ? 0 : 1,
        if (body.containsKey('auto_play_tts_on_flip'))
          'auto_play_tts_on_flip':
              body['auto_play_tts_on_flip'] == false ? 0 : 1,
      };
      throw DioException(
          requestOptions: options, type: DioExceptionType.receiveTimeout);
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

class _Queue extends SyncQueueDao {
  final List<SyncQueueItem> items;
  final deleted = <String>[];
  _Queue(this.items);
  @override
  Future<List<SyncQueueItem>> getPendingItems({int limit = 100}) async =>
      items.where((item) => !deleted.contains(item.id)).toList();
  @override
  Future<int> delete(String id) async {
    deleted.add(id);
    return 1;
  }
}

class _Adapter implements HttpClientAdapter {
  final void Function()? onRequest;
  final int status;
  final requests = <RequestOptions>[];
  _Adapter({this.onRequest, this.status = 200});
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests.add(options);
    onRequest?.call();
    return ResponseBody.fromString('{}', status);
  }

  @override
  void close({bool force = false}) {}
}

class _DuplicateRejectingAdapter implements HttpClientAdapter {
  final Future<void> Function() onFirstCreate;
  final created = <String>{};
  final requests = <RequestOptions>[];
  _DuplicateRejectingAdapter({required this.onFirstCreate});

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests.add(options);
    final key = '${options.path}:${options.data['id']}';
    if (!created.add(key)) return ResponseBody.fromString('{}', 409);
    if (created.length == 1) await onFirstCreate();
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingSyncQueueDao extends SyncQueueDao {
  bool wasTouched = false;

  @override
  Future<List<SyncQueueItem>> getPendingItems({int limit = 100}) async {
    wasTouched = true;
    throw StateError('SQLite queue should not be read');
  }
}
