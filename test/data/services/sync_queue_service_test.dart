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
