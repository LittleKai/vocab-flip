import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/deck.dart';
import 'package:vocabflip/presentation/widgets/deck/deck_summary_card.dart';

Deck _deck({int dueCount = 0}) {
  final now = DateTime(2026, 5, 29);
  return Deck(
    id: 'deck-1',
    name: 'Japanese N5',
    description: 'Core vocabulary',
    sourceLanguage: 'ja',
    targetLanguage: 'vi',
    createdAt: now,
    updatedAt: now,
    cardCount: 42,
    newCount: 0,
    reviewCount: dueCount,
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required Deck deck,
  VoidCallback? onStudy,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DeckSummaryCard(
          deck: deck,
          cardCountLabel: '${deck.cardCount} cards',
          dueLabel: '${deck.dueCount} due',
          studyLabel: 'Study',
          onTap: () {},
          onStudy: onStudy,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows deck name and card count', (tester) async {
    await _pumpCard(tester, deck: _deck());

    expect(find.text('Japanese N5'), findsOneWidget);
    expect(find.text('42 cards'), findsOneWidget);
  });

  testWidgets('shows study button only when a study callback is provided',
      (tester) async {
    await _pumpCard(tester, deck: _deck(dueCount: 4));

    expect(find.text('Study'), findsNothing);

    await _pumpCard(tester, deck: _deck(dueCount: 4), onStudy: () {});

    expect(find.text('Study'), findsOneWidget);
    expect(find.text('4 due'), findsOneWidget);
  });

  testWidgets('shows trailing widget alongside study button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckSummaryCard(
            deck: _deck(dueCount: 4),
            cardCountLabel: '42 cards',
            dueLabel: '4 due',
            studyLabel: 'Study',
            onTap: () {},
            onStudy: () {},
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );

    expect(find.text('Study'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('emphasizes due study cards with progress and play affordance',
      (tester) async {
    await _pumpCard(tester, deck: _deck(dueCount: 4), onStudy: () {});

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
