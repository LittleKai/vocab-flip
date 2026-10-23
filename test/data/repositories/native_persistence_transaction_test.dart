import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vocabflip/core/constants/app_constants.dart';
import 'package:vocabflip/data/auth/alpha_auth_session.dart';
import 'package:vocabflip/data/local/daos/sync_queue_dao.dart';
import 'package:vocabflip/data/local/database/deck_dao.dart';
import 'package:vocabflip/data/local/database/flashcard_dao.dart';
import 'package:vocabflip/data/models/deck.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/models/sync_queue_item.dart';
import 'package:vocabflip/data/models/imported_deck_link.dart';
import 'package:vocabflip/data/models/public_deck.dart';
import 'package:vocabflip/data/models/public_flashcard.dart';
import 'package:vocabflip/data/remote/mongo/mongo_public_library_service.dart';
import 'package:vocabflip/data/remote/mongo/mongo_sync_service.dart';
import 'package:vocabflip/data/repositories/deck_repository.dart';
import 'package:vocabflip/data/repositories/flashcard_repository.dart';
import 'package:vocabflip/data/repositories/public_library_repository.dart';

void main() {
  late Database db;
  late SyncQueueDao queue;
  late DeckRepository decks;
  late FlashcardRepository cards;
  final deck = Deck(id: 'deck', name: 'Original', sourceLanguage: 'en');
  final card = Flashcard(id: 'card', deckId: 'deck', front: 'one', back: 'mot');

  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=https://example.test/api');
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    for (final entry in {
      AppConstants.tableDecks: deck.toMap(),
      AppConstants.tableFlashcards: card.toMap(),
      'sync_queue': SyncQueueItem(
              id: 'fixture',
              entityType: 'deck',
              entityId: 'deck',
              operation: 'CREATE')
          .toMap(),
      AppConstants.tableImportedDeckLinks: {'id': '', 'local_deck_id': ''},
    }.entries) {
      // The fixture keeps the actual model columns; production schema is unchanged.
      await db.execute(
          'CREATE TABLE ${entry.key} (${entry.value.keys.map((key) => '$key ${key == 'id' ? 'TEXT PRIMARY KEY' : ''}').join(',')})');
    }
    queue = SyncQueueDao(database: db);
    decks = DeckRepository(syncQueueDao: queue);
    cards = FlashcardRepository(syncQueueDao: queue);
    AlphaAuthSession().setUser(userId: 'A');
  });
  tearDown(() async {
    AlphaAuthSession().clear();
    await db.close();
  });

  test('public import queues deck create before cards and later reviews',
      () async {
    await decks.saveImportedDeck(deck, [card], ownerUserId: 'A');
    await cards.updateFlashcard(card.copyWith(front: 'reviewed'));
    final pending = await queue.getPendingItems();
    expect(pending.map((item) => '${item.entityType}:${item.operation}'),
        ['deck:CREATE', 'flashcard:CREATE', 'flashcard:UPDATE']);
    expect(
        pending.every(
            (item) => jsonDecode(item.payload!)[SyncQueueDao.ownerKey] == 'A'),
        isTrue);
  });

  test(
      'public update new card CREATE precedes its review and keeps existing progress',
      () async {
    final studied = card.copyWith(
        stability: 8, difficulty: 4, repetitions: 3, fsrsState: 2, fsrsStep: 0);
    await decks.saveImportedDeck(deck, [studied], ownerUserId: 'A');
    for (final item in await queue.getPendingItems()) {
      await queue.delete(item.id);
    }
    final links = _PublicSync();
    final repository = PublicLibraryRepository(
        libraryService: _PublicLibrary(),
        syncService: links,
        deckDao: _SqlDecks(db),
        flashcardDao: _SqlCards(db),
        flashcardRepository: cards);
    await repository.syncDeck('deck');
    final existing = Flashcard.fromMap((await db.query(
            AppConstants.tableFlashcards,
            where: 'id = ?',
            whereArgs: ['card']))
        .single);
    expect(existing.stability, 8);
    expect(existing.repetitions, 3);
    expect(existing.back, 'updated meaning');
    final added = Flashcard.fromMap((await db.query(
            AppConstants.tableFlashcards,
            where: 'id != ?',
            whereArgs: ['card']))
        .single);
    await cards.updateFlashcard(added.copyWith(repetitions: 1));
    final pending = await queue.getPendingItems();
    expect(pending.map((item) => item.operation), ['CREATE', 'UPDATE']);
    expect(pending.every((item) => item.entityId == added.id), isTrue);
    expect(
        pending.every(
            (item) => jsonDecode(item.payload!)[SyncQueueDao.ownerKey] == 'A'),
        isTrue);
    expect(links.version, 2);
  });

  test('public update rolls back new card if its CREATE queue insert fails',
      () async {
    await decks.saveImportedDeck(deck, [card], ownerUserId: 'A');
    final links = _PublicSync();
    final repository = PublicLibraryRepository(
        libraryService: _PublicLibrary(),
        syncService: links,
        deckDao: _SqlDecks(db),
        flashcardDao: _SqlCards(db),
        flashcardRepository: cards);
    await db.execute(
        "CREATE TRIGGER fail_queue BEFORE INSERT ON sync_queue WHEN NEW.entity_type = 'flashcard' BEGIN SELECT RAISE(ABORT, 'fixture queue failure'); END");
    await expectLater(repository.syncDeck('deck'), throwsA(anything));
    expect((await db.query(AppConstants.tableFlashcards)).length, 1);
    expect(links.version, 1);
  });

  test('failed queue insert rolls back native card; retry creates only once',
      () async {
    await decks.createDeck(deck);
    await db.execute(
        "CREATE TRIGGER fail_queue BEFORE INSERT ON sync_queue WHEN NEW.entity_type = 'flashcard' BEGIN SELECT RAISE(ABORT, 'fixture queue failure'); END");
    await expectLater(cards.createFlashcard(card), throwsA(anything));
    expect(await db.query(AppConstants.tableFlashcards), isEmpty);
    expect((await queue.getPendingItems()).length, 1);
    await db.execute('DROP TRIGGER fail_queue');
    await cards.createFlashcard(card);
    expect((await db.query(AppConstants.tableFlashcards)).length, 1);
    expect((await queue.getPendingItems()).length, 2);
  });

  test('enqueue retains origin account across database awaits', () async {
    final writing = decks.createDeck(deck);
    AlphaAuthSession().setUser(userId: 'B');
    await writing;
    expect(await queue.getPendingItems(), isEmpty);
    AlphaAuthSession().setUser(userId: 'A');
    expect((await queue.getPendingItems()).single.entityId, 'deck');
  });

  test('failed replacement preserves old deck cards and pending operations',
      () async {
    await decks.saveImportedDeck(deck, [card], ownerUserId: 'A');
    final before = await db.query('sync_queue');
    await db.execute(
        "CREATE TRIGGER fail_card BEFORE INSERT ON ${AppConstants.tableFlashcards} WHEN NEW.front = 'broken' BEGIN SELECT RAISE(ABORT, 'fixture card failure'); END");
    await expectLater(
        decks.saveImportedDeck(
            deck.copyWith(name: 'New'), [card.copyWith(front: 'broken')],
            overwrite: true, ownerUserId: 'A'),
        throwsA(anything));
    expect(
        (await db.query(AppConstants.tableDecks)).single['name'], 'Original');
    expect(
        (await db.query(AppConstants.tableFlashcards)).single['front'], 'one');
    expect(await db.query('sync_queue'), before);
  });

  test('foreign edits cannot be delivered under original owner or new account',
      () async {
    await decks.saveImportedDeck(deck, [card], ownerUserId: 'A');
    for (final item in await queue.getPendingItems()) {
      await queue.delete(item.id);
    }
    AlphaAuthSession().setUser(userId: 'B');
    await decks.updateDeck(deck.copyWith(name: 'B edit'));
    await cards.updateFlashcard(card.copyWith(front: 'B edit'));
    expect(await queue.getPendingItems(), isEmpty);
    AlphaAuthSession().setUser(userId: 'A');
    expect(await queue.getPendingItems(), isEmpty);
    final markers = await db
        .query('sync_queue', where: 'operation = ?', whereArgs: ['OWNER']);
    expect(
        markers.every((row) =>
            jsonDecode(row['payload'] as String)[SyncQueueDao.ownerKey] == 'A'),
        isTrue);
  });

  test('guest legacy and foreign rows stay quarantined and are never deleted',
      () async {
    AlphaAuthSession().clear();
    await decks.saveImportedDeck(deck, [card], ownerUserId: null);
    await db.insert(
        'sync_queue',
        SyncQueueItem(
                id: 'legacy',
                entityType: 'deck',
                entityId: 'legacy',
                operation: 'UPDATE',
                payload: '{}')
            .toMap());
    AlphaAuthSession().setUser(userId: 'B');
    await decks.updateDeck(deck.copyWith(name: 'B edit'));
    expect(await queue.getPendingItems(), isEmpty);
    final rows = await db.query('sync_queue');
    expect(rows.length, 6);
    expect(rows.where((row) => row['id'] == 'legacy').length, 1);
    final owner = rows.singleWhere((row) => row['id'] == 'owner:deck:deck');
    expect(
        jsonDecode(owner['payload'] as String)[SyncQueueDao.ownerKey], isNull);
  });
}

class _SqlCards extends FlashcardDao {
  final Database db;
  _SqlCards(this.db);
  @override
  Future<List<Flashcard>> getByDeckId(String id) async =>
      (await db.query(AppConstants.tableFlashcards,
              where: 'deck_id = ?', whereArgs: [id]))
          .map(Flashcard.fromMap)
          .toList();
  @override
  Future<int> insert(Flashcard card) =>
      db.insert(AppConstants.tableFlashcards, card.toMap());
  @override
  Future<int> update(Flashcard card) =>
      db.update(AppConstants.tableFlashcards, card.toMap(),
          where: 'id = ?', whereArgs: [card.id]);
}

class _SqlDecks extends DeckDao {
  final Database db;
  _SqlDecks(this.db);
  @override
  Future<Deck?> getById(String id) async {
    final rows = await db
        .query(AppConstants.tableDecks, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Deck.fromMap(rows.single);
  }

  @override
  Future<int> update(Deck deck) =>
      db.update(AppConstants.tableDecks, deck.toMap(),
          where: 'id = ?', whereArgs: [deck.id]);
}

class _PublicSync extends MongoSyncService {
  int version = 1;
  @override
  Future<ImportedDeckLink?> getImportLink(String id) async => ImportedDeckLink(
      id: 'link',
      publicDeckId: 'public',
      localDeckId: id,
      userId: 'A',
      importedVersion: version);
  @override
  Future<void> updateImportLink(
      {required String linkId, required int newVersion}) async {
    version = newVersion;
  }
}

class _PublicLibrary extends MongoPublicLibraryService {
  @override
  Future<PublicDeck?> getDeck(String id) async => PublicDeck(
      id: id,
      authorId: 'author',
      authorName: 'Author',
      name: 'Public',
      sourceLanguage: 'en',
      targetLanguage: 'vi',
      categoryId: 'general',
      version: 2);
  @override
  Future<List<PublicFlashcard>> getFlashcards(String id, {int? limit}) async =>
      [
        PublicFlashcard(
            id: 'old', publicDeckId: id, front: 'one', back: 'updated meaning'),
        PublicFlashcard(id: 'new', publicDeckId: id, front: 'two', back: 'hai'),
      ];
}
