import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      'account switch during dispatch preserves queue and stops subsequent requests',
      () async {
    AlphaAuthSession().setUser(userId: 'A');
    final queue = _Queue([_item('one', owner: 'A'), _item('two', owner: 'A')]);
    final adapter =
        _Adapter(onRequest: () => AlphaAuthSession().setUser(userId: 'B'));
    await SyncQueueService(
            syncQueueDao: queue, dio: Dio()..httpClientAdapter = adapter)
        .syncPendingItems();
    expect(adapter.requests.length, 1);
    expect(queue.deleted, isEmpty);
    expect(AppPreferences().lastSyncCursor, isNull);
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
  Future<List<SyncQueueItem>> getPendingItems({int limit = 100}) async => items;
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

class _ThrowingSyncQueueDao extends SyncQueueDao {
  bool wasTouched = false;

  @override
  Future<List<SyncQueueItem>> getPendingItems({int limit = 100}) async {
    wasTouched = true;
    throw StateError('SQLite queue should not be read');
  }
}
