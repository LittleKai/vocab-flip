import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/auth/alpha_auth_session.dart';
import 'package:vocabflip/data/local/database/deck_dao.dart';
import 'package:vocabflip/data/local/database/flashcard_dao.dart';
import 'package:vocabflip/data/models/deck.dart';
import 'package:vocabflip/data/repositories/deck_repository.dart';
import 'package:vocabflip/data/repositories/backup_repository.dart';
import 'package:vocabflip/data/services/google_drive_service.dart';

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'API_URL=https://example.test/api'));
  tearDown(() => AlphaAuthSession().clear());

  test('invalid imported card never mutates deck storage', () async {
    final dao = _DeckDao();
    final repo = DeckRepository(deckDao: dao, flashcardDao: FlashcardDao());
    await expectLater(
        repo.importDeck({
          'decks': [
            {
              'id': 'existing',
              'name': 'Replacement',
              'source_language': 'en',
              'cards': [
                {'front': 'one', 'back': 123}
              ]
            }
          ]
        }, overwrite: true),
        throwsA(anything));
    expect(dao.writes, 0);
  });

  test('invalid later replacement is rejected before any deletion/import',
      () async {
    final decks = _DeckRepository();
    final backup =
        BackupRepository(driveService: _Drive(), deckRepository: decks);
    try {
      await backup.restoreBackup('fixture',
          onConflict: () async => RestoreMode.replace);
    } catch (_) {}
    expect(decks.mutations, isEmpty);
  });

  test('card IDs duplicated across backup decks are rejected before mutation',
      () async {
    final decks = _DeckRepository();
    final backup = BackupRepository(
        driveService: _Drive(duplicateCards: true), deckRepository: decks);
    await expectLater(
        backup.restoreBackup('fixture',
            onConflict: () async => RestoreMode.replace),
        throwsA(isA<FormatException>()));
    expect(decks.mutations, isEmpty);
  });

  test('account switch while downloading backup aborts before mutation',
      () async {
    AlphaAuthSession().setUser(userId: 'A');
    final decks = _DeckRepository();
    final backup = BackupRepository(
        deckRepository: decks,
        driveService: _Drive(
          onDownload: () => AlphaAuthSession().setUser(userId: 'B'),
          decks: [
            {
              'id': 'first',
              'name': 'Valid',
              'source_language': 'en',
              'cards': []
            }
          ],
        ));
    await expectLater(
        backup.restoreBackup('fixture',
            onConflict: () async => RestoreMode.replace),
        throwsA(isA<StateError>()));
    expect(decks.mutations, isEmpty);
  });
}

class _DeckDao extends DeckDao {
  int writes = 0;
  @override
  Future<bool> exists(String id) async => true;
  @override
  Future<int> insert(Deck deck) async {
    writes++;
    return 1;
  }
}

class _DeckRepository extends DeckRepository {
  final mutations = <String>[];
  @override
  Future<bool> deckExists(String id) async => true;
  @override
  Future<void> deleteDeck(String id) async {
    mutations.add('delete');
  }

  @override
  Future<Deck> importDeck(Map<String, dynamic> json,
      {bool overwrite = false}) async {
    mutations.add('import');
    return Deck.fromJson((json['decks'] as List).first as Map<String, dynamic>);
  }
}

class _Drive implements GoogleDriveService {
  final bool duplicateCards;
  final void Function()? onDownload;
  final List<Map<String, dynamic>>? decks;
  _Drive({this.duplicateCards = false, this.onDownload, this.decks});
  @override
  bool get isConnected => true;
  @override
  Future<Map<String, dynamic>?> downloadBackup(String id) async {
    onDownload?.call();
    return {
      'data': {
        'decks': decks ??
            [
              {
                'id': 'first',
                'name': 'Valid',
                'source_language': 'en',
                'cards': duplicateCards
                    ? [
                        {'id': 'same', 'front': 'one', 'back': 'mot'}
                      ]
                    : []
              },
              {
                'id': 'second',
                'name': duplicateCards ? 'Valid too' : 123,
                'source_language': 'en',
                'cards': duplicateCards
                    ? [
                        {'id': 'same', 'front': 'two', 'back': 'hai'}
                      ]
                    : []
              },
            ]
      }
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
