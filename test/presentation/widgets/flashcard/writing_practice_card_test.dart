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
  final StrokeCharacter character;
  FakeStrokeDataRepository(this.character);

  @override
  Future<StrokeCharacter?> lookupCharacter(String char, String sourceLanguage) async {
    return character;
  }

  @override
  Future<bool> hasStrokeData(String char, String sourceLanguage) async {
    return true;
  }
}

class FakeValidationService implements StrokeValidationService {
  @override
  StrokeValidationResult validateStroke({
    required List<Offset> userPoints,
    required int expectedIndex,
    required StrokeCharacter character,
  }) {
    return const StrokeValidationResult.accept(1.0);
  }
}

void main() {
  late StrokeCharacter testCharacter;
  late Flashcard testCard;

  setUp(() {
    testCharacter = const StrokeCharacter(
      character: '一',
      locale: 'zh',
      source: 'test',
      viewBox: [0, 0, 1024, 1024],
      strokes: [
        StrokeData(index: 0, path: 'M0,0 L100,100', median: [StrokePoint(100, 100), StrokePoint(200, 200)])
      ],
    );

    testCard = Flashcard(
      id: '1',
      deckId: 'deck1',
      front: '一',
      back: 'One',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  Widget buildTestApp(StrokePracticeProvider provider, ValueChanged<ReviewRating> onComplete) {
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
            card: testCard,
            onComplete: onComplete,
          ),
        ),
      ),
    );
  }

  testWidgets('WritingPracticeCard shows canvas, buttons and completes', (WidgetTester tester) async {
    final provider = StrokePracticeProvider(
      repository: FakeStrokeDataRepository(testCharacter),
      validationService: FakeValidationService(),
    );

    ReviewRating? completedRating;

    await tester.pumpWidget(buildTestApp(provider, (rating) {
      completedRating = rating;
    }));
    await tester.pump();

    // Provider is initially loading/initial. Call load.
    await provider.loadForCard(text: '一', sourceLanguage: 'zh');
    await tester.pumpAndSettle();

    // Should see the text
    expect(find.text('一'), findsOneWidget);
    
    // Should see buttons
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

    // Provide a stroke
    final canvasFinder = find.byType(GestureDetector);
    expect(canvasFinder, findsWidgets);

    // We can simulate a drag across the canvas
    await tester.drag(canvasFinder.first, const Offset(100, 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 600)); // wait for completion delay

    // Because FakeValidationService accepts everything, it should complete with rating
    expect(completedRating, isNotNull);
    expect(completedRating, ReviewRating.easy); // 0 mistakes
  });
}
