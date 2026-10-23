import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/presentation/widgets/flashcard/multiple_choice_card.dart';

void main() {
  testWidgets('changing cards cancels a delayed answer from the old card',
      (tester) async {
    final a = Flashcard(id: 'a', deckId: 'deck', front: 'A', back: 'Answer A');
    final b = Flashcard(id: 'b', deckId: 'deck', front: 'B', back: 'Answer B');
    final answers = <String>[];
    Widget app(Flashcard card) => MaterialApp(
            home: Scaffold(
                body: MultipleChoiceCard(
          card: card,
          allCards: [a, b],
          onAnswerSelected: (_) => answers.add(card.id),
        )));
    await tester.pumpWidget(app(a));
    await tester.tap(find.text('Answer A'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(app(b));
    await tester.pump(const Duration(milliseconds: 600));
    expect(answers, isEmpty);
    await tester.tap(find.text('Answer B'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(answers, ['b']);
  });
}
