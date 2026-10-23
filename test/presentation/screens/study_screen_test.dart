import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabflip/data/local/preferences/app_preferences.dart';
import 'package:vocabflip/data/models/deck.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import 'package:vocabflip/presentation/providers/deck_provider.dart';
import 'package:vocabflip/presentation/providers/stroke_practice_provider.dart';
import 'package:vocabflip/presentation/providers/study_provider.dart';
import 'package:vocabflip/presentation/providers/settings_provider.dart';
import 'package:vocabflip/presentation/screens/study/study_screen.dart';
import 'package:vocabflip/presentation/widgets/stroke/handwriting_canvas.dart';
import '../providers/study_provider_test.dart'
    show MemoryCards, MemoryAnalytics;
import '../widgets/flashcard/writing_practice_card_test.dart'
    show FakeStrokeDataRepository, FakeValidationService;

class StudyDeck extends DeckProvider {
  @override
  Deck get selectedDeck => Deck(
      id: 'deck', name: 'Test', sourceLanguage: 'ja', targetLanguage: 'en');

  @override
  Future<void> selectDeck(String id) async {}
}

void main() {
  late StudyProvider study;
  late StrokePracticeProvider stroke;
  late MemoryCards cards;

  setUp(() async {
    dotenv.testLoad(fileInput: '');
    SharedPreferences.setMockInitialValues({});
    await AppPreferences().init();
    cards = MemoryCards(
        [Flashcard(id: 'a', deckId: 'deck', front: '日', back: 'Sun')]);
    study = StudyProvider(
      flashcardRepository: cards,
      studyAnalyticsRepository: MemoryAnalytics(),
    )..toggleShuffleMode();
    stroke = StrokePracticeProvider(
      repository: FakeStrokeDataRepository({
        '日': const StrokeCharacter(
          character: '日',
          locale: 'ja',
          source: 'test',
          viewBox: [0, 0, 1024, 1024],
          strokes: [
            StrokeData(
                index: 0,
                path: 'M0,0 L100,100',
                median: [StrokePoint(0, 0), StrokePoint(100, 100)])
          ],
        ),
        '本': const StrokeCharacter(
          character: '本',
          locale: 'ja',
          source: 'test',
          viewBox: [0, 0, 1024, 1024],
          strokes: [
            StrokeData(
                index: 0,
                path: 'M0,0 L100,100',
                median: [StrokePoint(0, 0), StrokePoint(100, 100)])
          ],
        ),
      }),
      validationService: FakeValidationService(),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async =>
          call.method == 'getLanguages' || call.method == 'getVoices' ? [] : 1,
    );
  });

  Future<void> open(WidgetTester tester, StudyMode mode) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: study),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<DeckProvider>(create: (_) => StudyDeck()),
        ChangeNotifierProvider.value(value: stroke),
      ],
      child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: [Locale('en')],
          home: StudyScreen(deckId: 'deck')),
    ));
    await tester.pumpAndSettle();
    // Exercise the actual mode-selection handler without depending on menu labels.
    tester
        .widget<PopupMenuButton<StudyMode>>(
            find.byType(PopupMenuButton<StudyMode>))
        .onSelected!(mode);
    await tester.pumpAndSettle();
  }

  testWidgets('last-card Again in multiple choice accepts the next attempt',
      (tester) async {
    await open(tester, StudyMode.multipleChoice);
    await tester.tap(find.text('Distractor 1'));
    await tester.pumpAndSettle(const Duration(milliseconds: 650));
    expect(study.cardsStudied, 1);
    await tester.tap(find.text('Sun'));
    await tester.pumpAndSettle(const Duration(milliseconds: 650));
    expect(study.cardsStudied, 2);
    expect(study.state, StudyState.completed);
  });

  testWidgets(
      'rating disables Skip, exit and mode controls until persistence finishes',
      (tester) async {
    await open(tester, StudyMode.classic);
    await tester.tap(find.text('Show Answer'));
    await tester.pumpAndSettle();
    final gate = Completer<void>();
    cards.reviewGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.tap(find.text('Good'));
    await tester.pump();
    expect(study.isSubmitting, isTrue);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.skip_next))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<PopupMenuButton<StudyMode>>(
                find.byType(PopupMenuButton<StudyMode>))
            .enabled,
        isFalse);
    expect(
        tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .every((button) => button.onPressed == null),
        isTrue);
    gate.complete();
    await tester.pumpAndSettle();
    expect(study.cardsStudied, 1);
  });

  testWidgets('Study Again reloads a completed writing target', (tester) async {
    cards.cards['b'] =
        Flashcard(id: 'b', deckId: 'deck', front: '本', back: 'Book');
    await open(tester, StudyMode.writingPractice);
    await tester.drag(find.byType(HandwritingCanvas), const Offset(100, 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 650));
    expect(study.currentCard!.front, '本');
    expect(stroke.activeDisplayCharacter, '本');
    await tester.drag(find.byType(HandwritingCanvas), const Offset(100, 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 650));
    expect(study.state, StudyState.completed);
    expect(stroke.activeDisplayCharacter, '本');
    await tester.tap(find.text('Study Again'));
    await tester.pumpAndSettle();
    expect(study.state, StudyState.studying);
    expect(study.currentCard!.front, '日');
    expect(stroke.isWordComplete, isFalse);
    expect(stroke.completedStrokeCount, 0);
    expect(stroke.activeDisplayCharacter, '日');
  });

  testWidgets('Skip on the only multiple-choice card cancels the old answer',
      (tester) async {
    await open(tester, StudyMode.multipleChoice);
    await tester.tap(find.text('Sun'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump(const Duration(milliseconds: 650));
    expect(study.cardsStudied, 0);
    await tester.tap(find.text('Sun'));
    await tester.pumpAndSettle(const Duration(milliseconds: 650));
    expect(study.cardsStudied, 1);
  });

  testWidgets(
      'Skip during writing completion clears the target and pending rating',
      (tester) async {
    await open(tester, StudyMode.writingPractice);
    await tester.drag(find.byType(HandwritingCanvas), const Offset(100, 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump(const Duration(milliseconds: 650));
    expect(study.cardsStudied, 0);
    expect(stroke.isWordComplete, isFalse);
    expect(stroke.completedStrokeCount, 0);
    await tester.drag(find.byType(HandwritingCanvas), const Offset(100, 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 650));
    expect(study.cardsStudied, 1);
  });
}
