import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/core/utils/spaced_repetition.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/data/repositories/stroke_data_repository.dart';
import 'package:vocabflip/data/services/stroke_validation_service.dart';
import 'package:vocabflip/presentation/providers/stroke_practice_provider.dart';
import 'package:vocabflip/presentation/widgets/flashcard/writing_practice_card.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vocabflip/l10n/app_localizations.dart';

class FakeStrokeDataRepository implements StrokeDataRepository {
  final Map<String, StrokeCharacter> fixtures;
  FakeStrokeDataRepository(this.fixtures);

  @override
  Future<StrokeCharacter?> lookupCharacter(
      String char, String sourceLanguage) async {
    return fixtures[char];
  }

  @override
  Future<bool> hasStrokeData(String char, String sourceLanguage) async {
    return fixtures.containsKey(char);
  }
}

class FakeValidationService implements StrokeValidationService {
  StrokeValidationResult result;

  FakeValidationService({
    this.result = const StrokeValidationResult.accept(1.0),
  });

  @override
  StrokeValidationResult validateStroke({
    required List<Offset> userPoints,
    required int expectedIndex,
    required StrokeCharacter character,
    StrokeValidationProfile profile = StrokeValidationProfile.standard,
  }) {
    return result;
  }
}

void main() {
  late StrokeCharacter char1;
  late StrokeCharacter char2;

  setUp(() {
    char1 = const StrokeCharacter(
      character: '日',
      locale: 'ja',
      source: 'test',
      viewBox: [0, 0, 1024, 1024],
      strokes: [
        StrokeData(
            index: 0,
            path: 'M0,0 L100,100',
            median: [StrokePoint(100, 100), StrokePoint(200, 200)])
      ],
    );

    char2 = const StrokeCharacter(
      character: '本',
      locale: 'ja',
      source: 'test',
      viewBox: [0, 0, 1024, 1024],
      strokes: [
        StrokeData(
            index: 0,
            path: 'M0,0 L100,100',
            median: [StrokePoint(100, 100), StrokePoint(200, 200)])
      ],
    );
  });

  Widget buildTestApp(StrokePracticeProvider provider, Flashcard card,
      ValueChanged<ReviewRating> onComplete) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: WritingPracticeCard(
            card: card,
            onComplete: onComplete,
          ),
        ),
      ),
    );
  }

  testWidgets('WritingPracticeCard single-character completes normally',
      (WidgetTester tester) async {
    final provider = StrokePracticeProvider(
      repository: FakeStrokeDataRepository({'日': char1}),
      validationService: FakeValidationService(),
    );

    final testCard = Flashcard(
      id: '1',
      deckId: 'deck1',
      front: '日',
      back: 'Sun',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ReviewRating? completedRating;

    await tester.pumpWidget(buildTestApp(provider, testCard, (rating) {
      completedRating = rating;
    }));
    await tester.pump();

    await provider.loadForCard(text: '日', sourceLanguage: 'ja');
    await tester.pumpAndSettle();

    final canvasFinder = find.byType(GestureDetector);
    await tester.drag(canvasFinder.first, const Offset(100, 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(completedRating, isNotNull);
    expect(completedRating, ReviewRating.easy);
  });

  testWidgets('WritingPracticeCard multi-character flow completes both targets',
      (WidgetTester tester) async {
    final provider = StrokePracticeProvider(
      repository: FakeStrokeDataRepository({'日': char1, '本': char2}),
      validationService: FakeValidationService(),
    );

    final testCard = Flashcard(
      id: '2',
      deckId: 'deck2',
      front: '日本',
      back: 'Japan',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ReviewRating? completedRating;
    int callCount = 0;

    await tester.pumpWidget(buildTestApp(provider, testCard, (rating) {
      completedRating = rating;
      callCount++;
    }));
    await tester.pump();

    await provider.loadForCard(text: '日本', sourceLanguage: 'ja');
    await tester.pumpAndSettle();

    expect(find.text('Character 1 of 2'), findsOneWidget);

    // Complete the first character
    final canvasFinder = find.byType(GestureDetector);
    await tester.drag(canvasFinder.first, const Offset(100, 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // onComplete should NOT have fired yet
    expect(callCount, 0);
    expect(completedRating, isNull);

    // It should have advanced to the second character
    expect(find.text('Character 2 of 2'), findsOneWidget);

    // Complete the second character
    await tester.drag(canvasFinder.first, const Offset(100, 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // onComplete SHOULD have fired once
    expect(callCount, 1);
    expect(completedRating, ReviewRating.easy);
  });

  testWidgets('WritingPracticeCard displays skipped unsupported characters',
      (WidgetTester tester) async {
    final provider = StrokePracticeProvider(
      repository: FakeStrokeDataRepository({'日': char1, '本': char2}),
      validationService: FakeValidationService(),
    );

    final testCard = Flashcard(
      id: '3',
      deckId: 'deck3',
      front: '日本!',
      back: 'Japan!',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestApp(provider, testCard, (_) {}));
    await tester.pump();

    await provider.loadForCard(text: '日本!', sourceLanguage: 'ja');
    await tester.pumpAndSettle();

    expect(find.text('Skipped 1 unsupported'), findsOneWidget);
  });

  testWidgets('WritingPracticeCard profile menu changes provider state',
      (WidgetTester tester) async {
    final provider = StrokePracticeProvider(
      repository: FakeStrokeDataRepository({'日': char1}),
      validationService: FakeValidationService(),
    );

    final testCard = Flashcard(
      id: '4',
      deckId: 'deck4',
      front: '日',
      back: 'Sun',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestApp(provider, testCard, (_) {}));
    await tester.pump();

    await provider.loadForCard(text: '日', sourceLanguage: 'ja');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Strict').last);
    await tester.pumpAndSettle();

    expect(provider.validationProfile, StrokeValidationProfile.strict);
  });

  testWidgets('WritingPracticeCard rejected stroke path does not throw',
      (WidgetTester tester) async {
    final provider = StrokePracticeProvider(
      repository: FakeStrokeDataRepository({'日': char1}),
      validationService: FakeValidationService(
        result: const StrokeValidationResult.reject(
          StrokeRejection.wrongDirection,
        ),
      ),
    );

    final testCard = Flashcard(
      id: '5',
      deckId: 'deck5',
      front: '日',
      back: 'Sun',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ReviewRating? completedRating;

    await tester.pumpWidget(buildTestApp(provider, testCard, (rating) {
      completedRating = rating;
    }));
    await tester.pump();

    await provider.loadForCard(text: '日', sourceLanguage: 'ja');
    await tester.pumpAndSettle();

    final canvasFinder = find.byType(GestureDetector);
    await tester.drag(canvasFinder.first, const Offset(100, 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(completedRating, isNull);
    expect(provider.lastValidationResult?.rejection,
        StrokeRejection.wrongDirection);
  });
}
