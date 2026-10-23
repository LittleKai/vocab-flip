import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' show Excel, TextCellValue;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabflip/data/models/deck.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/repositories/deck_repository.dart';
import 'package:vocabflip/data/repositories/flashcard_repository.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import 'package:vocabflip/presentation/providers/ai_provider.dart';
import 'package:vocabflip/presentation/providers/auth_provider.dart';
import 'package:vocabflip/presentation/providers/sync_provider.dart';
import 'package:vocabflip/presentation/providers/deck_provider.dart';
import 'package:vocabflip/presentation/providers/flashcard_provider.dart';
import 'package:vocabflip/presentation/screens/ai/ai_draft_review_screen.dart';
import 'package:vocabflip/presentation/screens/deck/create_deck_screen.dart';
import 'package:vocabflip/presentation/screens/deck/deck_detail_screen.dart';
import 'package:vocabflip/presentation/screens/flashcard/flashcard_editor_screen.dart';
import 'package:vocabflip/presentation/widgets/common/safe_network_image.dart';

final deck =
    Deck(id: 'deck', name: 'Deck', sourceLanguage: 'en', targetLanguage: 'vi');

class CardStore extends FlashcardRepository {
  final List<Flashcard> saved = [];
  bool fail = true;
  @override
  Future<void> createFlashcard(Flashcard card) async {
    if (fail || card.front == 'fail') throw StateError('write failed');
    saved.add(card);
  }

  @override
  Future<void> updateFlashcard(Flashcard card) async {
    if (fail) throw StateError('write failed');
    saved.add(card);
  }

  @override
  Future<List<Flashcard>> getFlashcardsByDeckId(String id) async => saved;
  @override
  Future<List<Flashcard>> getDueFlashcards(String id, {int? limit}) async =>
      saved;
}

class DeckStore extends DeckRepository {
  final CardStore cards;
  DeckStore(this.cards);
  @override
  Future<Deck?> getDeckById(String id) async =>
      deck.copyWith(cardCount: cards.saved.length);
  @override
  Future<List<Deck>> getAllDecks() async => [(await getDeckById('deck'))!];
}

class RefreshFailingDeckStore extends DeckRepository {
  final List<Deck> saved = [];
  @override
  Future<void> createDeck(Deck value) async => saved.add(value);
  @override
  Future<void> updateDeck(Deck value) async => saved.add(value);
  @override
  Future<List<Deck>> getAllDecks() async => throw StateError('refresh failed');
}

class FixturePicker extends FilePicker {
  final File file;
  FixturePicker(this.file);
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      FilePickerResult([
        PlatformFile(
            name: file.uri.pathSegments.last, path: file.path, size: 1),
      ]);
}

class GuestAuth extends ChangeNotifier implements AuthProvider {
  @override
  bool get isAuthenticated => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class IdleSync extends SyncProvider {
  @override
  Future<void> checkForUpdates() async {}
}

Future<void> pumpScreen(WidgetTester tester, Widget screen, CardStore cards,
    {AiProvider? ai, DeckProvider? decks, bool fileImages = false}) async {
  Future<void> pump() async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => FlashcardProvider(repository: cards)),
        ChangeNotifierProvider.value(
            value: decks ??
                (DeckProvider(repository: DeckStore(cards))
                  ..setTemporaryDeck(deck))),
        ChangeNotifierProvider.value(value: ai ?? AiProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: screen,
      ),
    ));
    await tester.pumpAndSettle();
  }

  if (fileImages) {
    await tester.runAsync(pump);
  } else {
    await pump();
  }
}

Future<void> disposeFileImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    for (var i = 0; i < 100 && imageCache.pendingImageCount > 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(imageCache.pendingImageCount, 0);
    imageCache.clear();
    imageCache.clearLiveImages();
  });
}

void main() {
  setUpAll(() => FilePicker.platform = FixturePicker(File('unused')));
  setUp(() => dotenv.testLoad(fileInput: ''));

  for (final update in [false, true]) {
    test(
        'committed deck ${update ? 'update' : 'create'} survives refresh failure',
        () async {
      final repository = RefreshFailingDeckStore();
      final provider = DeckProvider(repository: repository)
        ..setTemporaryDeck(deck);
      final saved = deck.copyWith(name: 'committed');
      await (update ? provider.updateDeck(saved) : provider.createDeck(saved));
      expect(repository.saved.single.name, 'committed');
      expect(provider.decks.single.name, 'committed');
      if (update) expect(provider.selectedDeck!.name, 'committed');
      expect(provider.error, contains('refresh failed'));
    });
  }

  testWidgets(
      'committed cover survives editor disposal when list refresh fails',
      (tester) async {
    late Directory sandbox;
    final source = (await tester.runAsync(() async {
      sandbox = await Directory.systemTemp.createTemp('vocabflip-cover-');
      return File('${sandbox.path}/source.png').writeAsBytes(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg=='));
    }))!;
    final picker = FilePicker.platform;
    FilePicker.platform = FixturePicker(source);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => sandbox.path);
    addTearDown(() async {
      await disposeFileImages(tester);
      FilePicker.platform = picker;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'), null);
      await sandbox.delete(recursive: true);
    });
    final repository = RefreshFailingDeckStore();
    await pumpScreen(
        tester,
        Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateDeckScreen())),
                  child: const Text('Open editor'),
                ))),
        CardStore(),
        decks: DeckProvider(repository: repository));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Saved cover');
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined).first);
      for (var i = 0; i < 100; i++) {
        final managed = Directory('${sandbox.path}/flashcard_images');
        if (await managed.exists() &&
            (await managed.list().toList()).isNotEmpty) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.runAsync(() => tester.pumpAndSettle());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Deck'));
    await tester.pumpAndSettle();
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.imagePath, isNotNull);
    expect(find.text('Open editor'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(
        await tester
            .runAsync(() => File(repository.saved.single.imagePath!).exists()),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial Excel import refreshes counts and enables Study',
      (tester) async {
    late Directory sandbox;
    final file = (await tester.runAsync(() async {
      sandbox =
          await Directory.systemTemp.createTemp('vocabflip-partial-import-');
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      for (final row in [
        ['Word', 'Phonetic', 'Meaning'],
        ['saved', '', 'meaning'],
        ['fail', '', 'meaning'],
      ]) {
        sheet.appendRow(row.map(TextCellValue.new).toList());
      }
      return File('${sandbox.path}/cards.xlsx').writeAsBytes(excel.encode()!);
    }))!;
    final picker = FilePicker.platform;
    FilePicker.platform = FixturePicker(file);
    SharedPreferences.setMockInitialValues({'hide_tts_warning': true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
            (call) async {
      if (call.method == 'getLanguages') return ['en-US'];
      if (call.method == 'getVoices') return <Map<String, String>>[];
      return 1;
    });
    addTearDown(() async {
      FilePicker.platform = picker;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
      await sandbox.delete(recursive: true);
    });
    final cards = CardStore()..fail = false;
    final decks = DeckProvider(repository: DeckStore(cards));
    await pumpScreen(
        tester,
        MultiProvider(providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => GuestAuth()),
          ChangeNotifierProvider<SyncProvider>(create: (_) => IdleSync()),
        ], child: const DeckDetailScreen(deckId: 'deck')),
        cards,
        decks: decks);
    // Excel reads bytes from disk, so allow real I/O to finish.
    await tester.runAsync(() async {
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import from Excel').first);
      await tester.pumpAndSettle();
      for (var i = 0;
          i < 100 && find.byType(AlertDialog).evaluate().isEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import 2 cards'));
      for (var i = 0; i < 100 && decks.selectedDeck?.cardCount != 1; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(cards.saved, hasLength(1));
    expect(decks.selectedDeck!.cardCount, 1);
    expect(decks.decks.single.cardCount, 1);
    expect(find.textContaining('write failed'), findsOneWidget);
    final study = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Study Again'));
    expect(study.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [true, false]) {
    testWidgets(
        'removing image ${fail ? 'failure retains' : 'success deletes'} original',
        (tester) async {
      late Directory sandbox;
      final original = (await tester.runAsync(() async {
        sandbox = await Directory.systemTemp.createTemp('vocabflip-editor-');
        final owned =
            await Directory('${sandbox.path}/flashcard_images').create();
        return File('${owned.path}/original.png').writeAsBytes(base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg=='));
      }))!;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'),
              (_) async => sandbox.path);
      addTearDown(() async {
        await disposeFileImages(tester);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('plugins.flutter.io/path_provider'), null);
        await sandbox.delete(recursive: true);
      });
      final cards = CardStore()..fail = fail;
      await pumpScreen(
          tester,
          FlashcardEditorScreen(
              deckId: 'deck',
              flashcard: Flashcard(
                  deckId: 'deck',
                  front: 'word',
                  back: 'meaning',
                  frontImageUrl: original.path)),
          cards,
          fileImages: true);
      await tester.scrollUntilVisible(find.byType(ToggleButtons), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byIcon(Icons.link).first);
      await tester.pumpAndSettle();
      final update = find.widgetWithText(ElevatedButton, 'Update');
      await tester.scrollUntilVisible(update, 200,
          scrollable: find.byType(Scrollable).first);
      // Let the managed file check/delete finish outside the fake clock.
      await tester.runAsync(() async {
        await tester.tap(update);
        for (var i = 0; i < 100; i++) {
          if (fail || !await original.exists()) break;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(await tester.runAsync(original.exists), fail);
      if (fail) {
        expect(find.textContaining('write failed'), findsOneWidget);
        // Cancel after the failed replacement still preserves the stored image.
        await tester.pumpWidget(const SizedBox());
        expect(await tester.runAsync(original.exists), isTrue);
      } else {
        expect(cards.saved.single.effectiveFrontImageUrl, isNull);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed add another retains entered fields and displays failure',
      (tester) async {
    await pumpScreen(
        tester, const FlashcardEditorScreen(deckId: 'deck'), CardStore());
    await tester.enterText(find.byType(TextFormField).at(0), 'hello');
    await tester.enterText(find.byType(TextFormField).at(2), 'meaning');
    final addAnother =
        find.widgetWithText(OutlinedButton, 'Add & Create Another');
    await tester.scrollUntilVisible(addAnother, 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(addAnother);
    await tester.pumpAndSettle();
    expect(find.textContaining('write failed'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'AI partial save removes only committed drafts and retry keeps failed draft',
      (tester) async {
    final ai = AiProvider();
    ai.draftCards.addAll([
      Flashcard(deckId: 'deck', front: 'saved', back: 'meaning'),
      Flashcard(deckId: 'deck', front: 'fail', back: 'meaning'),
      Flashcard(deckId: 'deck', front: 'unselected', back: 'meaning'),
    ]);
    final cards = CardStore()..fail = false;
    await pumpScreen(tester, const AiDraftReviewScreen(deckId: 'deck'), cards,
        ai: ai);
    await tester.tap(find.byType(Checkbox).last);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(ai.draftCards.map((c) => c.front), ['fail', 'unselected']);
    expect(cards.saved.map((c) => c.front), ['saved']);
    expect(find.textContaining('write failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a remote deck cover uses the shared network image',
      (tester) async {
    await pumpScreen(
        tester,
        CreateDeckScreen(
            deck: deck.copyWith(imagePath: 'https://example.org/cover.jpg')),
        CardStore());
    expect(find.byType(SafeNetworkImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
