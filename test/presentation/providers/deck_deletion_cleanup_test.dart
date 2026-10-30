import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabflip/data/local/preferences/app_preferences.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/models/study_session.dart';
import 'package:vocabflip/data/repositories/flashcard_repository.dart';
import 'package:vocabflip/data/repositories/study_analytics_repository.dart';
import 'package:vocabflip/data/services/update_install_service.dart';
import 'package:vocabflip/presentation/providers/flashcard_provider.dart';
import 'package:vocabflip/presentation/providers/study_provider.dart';

class _FakeFlashcardRepository extends FlashcardRepository {
  final Map<String, List<Flashcard>> byDeck;
  _FakeFlashcardRepository(this.byDeck);

  @override
  Future<List<Flashcard>> getFlashcardsByDeckId(String deckId) async =>
      List<Flashcard>.from(byDeck[deckId] ?? const []);

  @override
  Future<List<Flashcard>> getDueFlashcards(String deckId, {int? limit}) async =>
      List<Flashcard>.from(byDeck[deckId] ?? const []);
}

class _FakeAnalyticsRepository extends StudyAnalyticsRepository {
  @override
  Future<void> startSession(StudySession session) async {}

  @override
  Future<void> completeSession(StudySession session) async {}
}

void main() {
  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=https://example.test/api');
    SharedPreferences.setMockInitialValues({});
    await AppPreferences().init();
  });

  test('FlashcardProvider.clearIfDeck clears only matching deck state',
      () async {
    final cardA = Flashcard(id: 'c1', deckId: 'deck-a', front: 'A', back: 'a');
    final repo = _FakeFlashcardRepository({
      'deck-a': [cardA],
    });
    final provider = FlashcardProvider(repository: repo);

    await provider.loadFlashcards('deck-a');
    provider.selectFlashcard(cardA);
    expect(provider.currentDeckId, 'deck-a');
    expect(provider.flashcards, hasLength(1));

    // Unrelated deck deletion keeps current deck loaded
    provider.clearIfDeck('deck-b');
    expect(provider.currentDeckId, 'deck-a');
    expect(provider.flashcards, hasLength(1));
    expect(provider.selectedFlashcard?.id, 'c1');

    // Matching deck deletion resets state
    provider.clearIfDeck('deck-a');
    expect(provider.currentDeckId, isNull);
    expect(provider.flashcards, isEmpty);
    expect(provider.dueFlashcards, isEmpty);
    expect(provider.selectedFlashcard, isNull);
  });

  test('StudyProvider.clearIfDeck resets session only when deleted deck matches',
      () async {
    final cardA = Flashcard(id: 'c1', deckId: 'deck-a', front: 'A', back: 'a');
    final repo = _FakeFlashcardRepository({
      'deck-a': [cardA],
    });
    final provider = StudyProvider(
      flashcardRepository: repo,
      studyAnalyticsRepository: _FakeAnalyticsRepository(),
    );

    await provider.startStudySession('deck-a');
    expect(provider.state, StudyState.studying);
    expect(provider.currentSession?.deckId, 'deck-a');
    expect(provider.studyQueue, hasLength(1));

    // Deleting a different deck preserves active study session
    provider.clearIfDeck('deck-b');
    expect(provider.state, StudyState.studying);
    expect(provider.currentSession?.deckId, 'deck-a');
    expect(provider.studyQueue, hasLength(1));

    // Deleting the studied deck resets session and queue
    provider.clearIfDeck('deck-a');
    expect(provider.state, StudyState.idle);
    expect(provider.currentSession, isNull);
    expect(provider.studyQueue, isEmpty);
  });

  test('UpdateInstallService.extractUpdate blocks Zip Slip path traversal',
      () async {
    if (!Platform.isWindows) return;

    final tempDir = await Directory.systemTemp.createTemp('vocabflip_zip_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final archive = Archive()
      ..addFile(ArchiveFile('../escaped.txt', 7, 'payload'.codeUnits));
    final zipBytes = ZipEncoder().encode(archive)!;
    final zipPath = path.join(tempDir.path, 'sub', 'update.zip');
    await File(zipPath).create(recursive: true);
    await File(zipPath).writeAsBytes(zipBytes);

    final service = UpdateInstallService();
    final extractedPath = await service.extractUpdate(zipPath);

    expect(extractedPath, isNull);
    expect(await File(path.join(tempDir.path, 'escaped.txt')).exists(), isFalse);
  });
}
