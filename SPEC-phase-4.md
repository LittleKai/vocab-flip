# SPEC Phase 4: Study Flow Integration

## Goal

Expose Writing Practice as a real VocabFlip study mode for Japanese and Chinese decks, connect it to Provider state, local stroke data, localized UI, and existing FSRS review rating.

## Context / Constraints

- Existing `StudyMode` enum and mode menu are in `lib/presentation/screens/study/study_screen.dart`.
- Existing non-classic study cards call `_rateCard(provider, ReviewRating.good/again)` from `StudyScreen`.
- `StudyProvider.rateCard` already logs analytics and updates FSRS.
- Providers are registered in `lib/app.dart`.
- Visible strings must be added to both `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`, then generated files updated through Flutter tooling.

## Clarified Decisions / Assumptions

- `StudyMode.writingPractice` is visible only for `ja` and `zh` deck source languages when stroke data exists for the current card front.
- Writing practice result mapping:
  - 0 mistakes: `ReviewRating.easy`
  - 1-2 mistakes: `ReviewRating.good`
  - 3-5 mistakes: `ReviewRating.hard`
  - skipped, unavailable, or too many mistakes: `ReviewRating.again`
- If a card has no stroke data, the UI should show a localized unavailable state and offer to continue with Classic Flip or skip/rate again. The mode menu should avoid selecting Writing Practice when no data exists for any current candidate if practical.

## No-Placeholder Contract

This phase must wire the mode into the real study session and rating flow. A disconnected demo screen or widget that does not advance the study queue is not acceptable.

## Deferred Work

- Persistent per-character handwriting analytics is deferred.
- Full dataset rollout is Phase 5.

## Steps

### Step 1: Add practice Provider

- **File(s):**
  - `lib/presentation/providers/stroke_practice_provider.dart` (new)
  - `lib/app.dart`
- **Action:**
  - Add `StrokePracticeProvider extends ChangeNotifier`.
  - Inject/use `StrokeDataRepository` and `StrokeValidationService`.
  - Track:
    - current `StrokeCharacter?`
    - loading/error state
    - active stroke index
    - mistake count
    - completed stroke count
    - last validation result
  - Add methods:
    - `Future<void> loadForCard({required String text, required String sourceLanguage})`
    - `Future<StrokeValidationResult> submitStroke(List<Offset> points)`
    - `void replayCurrentStroke()`
    - `void resetPractice()`
    - `ReviewRating ratingForCompletion()`
  - Register it in `MultiProvider` in `lib/app.dart`.
- **Verify:**
  - Provider unit test loads fixture data, accepts correct strokes, increments mistakes on wrong strokes, and returns expected `ReviewRating`.
  - `rg -n "StrokePracticeProvider" lib/app.dart lib/presentation/providers` confirms it is wired.

### Step 2: Add writing practice flashcard widget

- **File(s):**
  - `lib/presentation/widgets/flashcard/writing_practice_card.dart` (new)
  - `lib/presentation/widgets/stroke/*` from earlier phases
- **Action:**
  - Build a compact study card:
    - front text and phonetic
    - square stroke canvas
    - icon buttons for replay, hint, undo/reset
    - localized validation feedback
    - completion callback with `ReviewRating`
  - Use existing theme colors and 8-point spacing.
  - Do not put visible instructional paragraphs in the UI; rely on direct controls and feedback states.
- **Verify:**
  - Widget test with fake provider state shows canvas, replay button, reset button, and feedback.
  - Completion callback fires with expected rating after all strokes are accepted.

### Step 3: Extend StudyMode and mode menu

- **File(s):**
  - `lib/presentation/screens/study/study_screen.dart`
- **Action:**
  - Add `StudyMode.writingPractice`.
  - Add localized menu item for Writing Practice.
  - When selected:
    - load current card stroke data by `card.front` and `deck.sourceLanguage`
    - render `WritingPracticeCard`
    - call `_rateCard(provider, rating)` when practice completes
  - Reset practice state when the study card changes.
  - Hide or disable the mode for non-`ja`/`zh` decks.
- **Verify:**
  - Manual smoke: in a fixture Japanese/Chinese deck, select Writing Practice, complete a character, and confirm the card advances.
  - Manual smoke: in an English deck, Writing Practice is not offered.

### Step 4: Add localization

- **File(s):**
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_vi.arb`
  - generated localization files after `flutter gen-l10n` or `flutter analyze` workflow
- **Action:**
  - Add strings for:
    - Writing Practice
    - replay stroke
    - show hint
    - reset stroke
    - correct stroke
    - wrong direction
    - wrong order
    - try again
    - stroke data unavailable
  - Regenerate localization outputs.
- **Verify:**
  - `rg -n "writingPractice|strokeDataUnavailable" lib/l10n`
  - App builds with no missing localization getter errors.

## Validation Plan

- `rg -n "enum StudyMode|_rateCard|PopupMenuButton<StudyMode>" lib/presentation/screens/study/study_screen.dart`
- `rg -n "MultiProvider|ChangeNotifierProvider" lib/app.dart`
- `flutter test` for the new provider/widget tests.
- `flutter analyze`
- Manual smoke on `ja`, `zh`, and non-CJK decks.
- Placeholder scan on touched UI/provider files.

## Dependencies

- Phase 1 must be complete.
- Phase 2 must be complete.
- Phase 3 must be complete.

