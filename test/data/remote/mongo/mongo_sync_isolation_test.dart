import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vocabflip/core/constants/app_constants.dart';
import 'package:vocabflip/data/auth/alpha_auth_session.dart';
import 'package:vocabflip/data/models/imported_deck_link.dart';
import 'package:vocabflip/data/remote/mongo/mongo_sync_service.dart';

void main() {
  late Database db;
  late _Adapter adapter;
  late MongoSyncService service;
  final link = ImportedDeckLink(
      id: 'link-A',
      publicDeckId: 'public',
      localDeckId: 'local-A',
      userId: 'A',
      importedVersion: 1);
  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=https://example.test/api');
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
        'CREATE TABLE ${AppConstants.tableImportedDeckLinks} (${link.toMap().keys.map((key) => '$key ${key == 'id' ? 'TEXT PRIMARY KEY' : ''}').join(',')})');
    await db.insert(AppConstants.tableImportedDeckLinks, link.toMap());
    adapter = _Adapter();
    service =
        MongoSyncService(dio: Dio()..httpClientAdapter = adapter, database: db);
    AlphaAuthSession().setUser(userId: 'B');
  });
  tearDown(() async {
    AlphaAuthSession().clear();
    await db.close();
  });

  test('local import links are scoped to current owner across all queries',
      () async {
    expect(await service.getImportLink('local-A'), isNull);
    expect(await service.getImportLinkByPublicDeck('public'), isNull);
    expect(await service.getAllImportLinks(), isEmpty);
    AlphaAuthSession().setUser(userId: 'A');
    expect((await service.getImportLink('local-A'))!.userId, 'A');
  });

  test('another account cannot update or delete existing local import link',
      () async {
    await service.updateImportLink(linkId: 'link-A', newVersion: 5);
    expect(
        (await db.query(AppConstants.tableImportedDeckLinks))
            .single['imported_version'],
        1);
    await service.deleteImportLink('link-A');
    expect((await db.query(AppConstants.tableImportedDeckLinks)).length, 1);
  });

  test('recordImport aborts local write when account changes during request',
      () async {
    AlphaAuthSession().setUser(userId: 'A');
    adapter.response =
        jsonEncode({'data': link.copyWith(id: 'new-link').toMap()});
    adapter.onRequest = () => AlphaAuthSession().setUser(userId: 'B');
    await expectLater(
        service.recordImport(
            publicDeckId: 'public',
            localDeckId: 'new-local',
            importedVersion: 1),
        throwsA(isA<StateError>()));
    expect((await db.query(AppConstants.tableImportedDeckLinks)).length, 1);
    expect(adapter.requests.single.extra['syncOwnerUserId'], 'A');
    expect(adapter.requests.single.extra['sessionVersion'], isA<int>());
  });

  test('account switch while loading cached link never returns old metadata',
      () async {
    AlphaAuthSession().setUser(userId: 'A');
    final loading = service.getImportLink('local-A');
    AlphaAuthSession().setUser(userId: 'B');
    await expectLater(loading, throwsA(isA<StateError>()));
  });

  test('account switch during update or delete prevents local mutation',
      () async {
    adapter.onRequest = () => AlphaAuthSession().setUser(userId: 'B');
    AlphaAuthSession().setUser(userId: 'A');
    await expectLater(service.updateImportLink(linkId: 'link-A', newVersion: 5),
        throwsA(isA<StateError>()));
    expect(
        (await db.query(AppConstants.tableImportedDeckLinks))
            .single['imported_version'],
        1);
    AlphaAuthSession().setUser(userId: 'A');
    await expectLater(
        service.deleteImportLink('link-A'), throwsA(isA<StateError>()));
    expect((await db.query(AppConstants.tableImportedDeckLinks)).length, 1);
  });
}

class _Adapter implements HttpClientAdapter {
  String response = '[]';
  void Function()? onRequest;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests.add(options);
    onRequest?.call();
    return ResponseBody.fromString(response, 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}
