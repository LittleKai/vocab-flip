# Home Deck Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign VocabFlip Home as a focused daily learning dashboard and tighten Deck list card hierarchy without changing state, routing, backend, database, or study logic.

**Architecture:** Keep `HomeScreen` and `DeckListScreen` as the owning screens. Extract small reusable deck presentation widgets into `lib/presentation/widgets/deck/deck_summary_card.dart` so Home and Deck list share the same compact card language without introducing new state. Use existing Provider data and existing l10n keys.

**Tech Stack:** Flutter, Dart, Material 3, Provider, existing Flutter l10n.

---

## File Structure

- Create `lib/presentation/widgets/deck/deck_summary_card.dart`
  - Owns reusable visual pieces for compact deck rows/cards used by Home and Deck list.
  - Exposes `DeckSummaryCard` and `DeckStatusChip`.
  - Depends only on `Deck`, `DeckCardHeader`, `AppColors`, and callbacks.

- Modify `lib/presentation/screens/home/home_screen.dart`
  - Replaces the current large gradient welcome card with a focused dashboard layout.
  - Uses existing `DeckProvider`, `SettingsProvider`, and `DeckNavigation`.
  - Uses existing l10n keys only.

- Modify `lib/presentation/screens/deck/deck_list_screen.dart`
  - Keeps search toggle, filter sheet, menu actions, and navigation behavior.
  - Refines `_DeckCard` layout and spacing using `DeckStatusChip`.
  - Adjusts `ResponsiveGrid.mainAxisExtent` only if needed after the card redesign.

- Create `test/presentation/widgets/deck/deck_summary_card_test.dart`
  - Widget tests for the reusable deck summary card and study action visibility.

- Modify `.gitignore`
  - Add `.superpowers/` so visual companion artifacts remain local.

---

### Task 1: Add Reusable Deck Summary Widgets

**Files:**
- Create: `lib/presentation/widgets/deck/deck_summary_card.dart`
- Test: `test/presentation/widgets/deck/deck_summary_card_test.dart`

- [ ] **Step 1: Write widget tests for deck summary behavior**

Create `test/presentation/widgets/deck/deck_summary_card_test.dart`:

```dart
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
    newCount: 3,
    reviewCount: 5,
    dueCount: dueCount,
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

  testWidgets('shows study button only when a study callback is provided', (tester) async {
    await _pumpCard(tester, deck: _deck(dueCount: 4));

    expect(find.text('Study'), findsNothing);

    await _pumpCard(tester, deck: _deck(dueCount: 4), onStudy: () {});

    expect(find.text('Study'), findsOneWidget);
    expect(find.text('4 due'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the new test and verify it fails**

Run:

```powershell
flutter test test/presentation/widgets/deck/deck_summary_card_test.dart
```

Expected: FAIL because `lib/presentation/widgets/deck/deck_summary_card.dart` does not exist.

- [ ] **Step 3: Add `DeckSummaryCard` and `DeckStatusChip`**

Create `lib/presentation/widgets/deck/deck_summary_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/deck.dart';
import '../common/deck_card_header.dart';

class DeckSummaryCard extends StatelessWidget {
  final Deck deck;
  final String cardCountLabel;
  final String? dueLabel;
  final String? studyLabel;
  final VoidCallback onTap;
  final VoidCallback? onStudy;
  final Widget? trailing;
  final bool compact;

  const DeckSummaryCard({
    super.key,
    required this.deck,
    required this.cardCountLabel,
    required this.onTap,
    this.dueLabel,
    this.studyLabel,
    this.onStudy,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDue = dueLabel != null && dueLabel!.isNotEmpty;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            children: [
              DeckCardHeader.buildDeckImage(context, deck.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deck.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        DeckCardHeader.buildLanguageBadge(context, deck.sourceLanguage),
                      ],
                    ),
                    if (deck.description != null && deck.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        deck.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        DeckStatusChip(
                          icon: Icons.style,
                          label: cardCountLabel,
                          color: AppColors.info,
                        ),
                        if (hasDue)
                          DeckStatusChip(
                            icon: Icons.schedule,
                            label: dueLabel!,
                            color: AppColors.accent,
                            emphasized: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onStudy != null && studyLabel != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: onStudy,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: Text(
                      studyLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ] else if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DeckStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool emphasized;

  const DeckStatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: emphasized ? color : AppColors.textSecondary(context),
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the new widget test and verify it passes**

Run:

```powershell
flutter test test/presentation/widgets/deck/deck_summary_card_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit Task 1**

Run:

```powershell
git add lib/presentation/widgets/deck/deck_summary_card.dart
git add -f test/presentation/widgets/deck/deck_summary_card_test.dart
git commit -m "Add deck summary card widget"
```

---

### Task 2: Redesign Home Dashboard

**Files:**
- Modify: `lib/presentation/screens/home/home_screen.dart`
- Test: `test/presentation/widgets/deck/deck_summary_card_test.dart`

- [ ] **Step 1: Replace Home tab section structure**

In `lib/presentation/screens/home/home_screen.dart`, add this import:

```dart
import '../../widgets/deck/deck_summary_card.dart';
```

Replace `_HomeTab` helper methods so the body renders:

```dart
children: [
  _buildDashboardHeader(context, settingsProvider),
  const SizedBox(height: 16),
  _buildDueFocusPanel(context, deckProvider),
  const SizedBox(height: 16),
  _buildQuickStats(context, deckProvider, settingsProvider),
  const SizedBox(height: 24),
  _buildDueTodaySection(context, deckProvider),
  const SizedBox(height: 24),
  _buildRecentDecks(context, deckProvider),
],
```

- [ ] **Step 2: Add the focused dashboard header**

Add this method to `_HomeTab` and remove the old `_buildWelcomeCard` call:

```dart
Widget _buildDashboardHeader(BuildContext context, SettingsProvider settings) {
  final l10n = AppLocalizations.of(context)!;
  final hour = DateTime.now().hour;
  final greeting = hour < 12
      ? l10n.goodMorning
      : hour < 17
          ? l10n.goodAfternoon
          : l10n.goodEvening;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.readyToLearn,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.accent.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 18, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              l10n.dayStreak(settings.streak),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    ],
  );
}
```

- [ ] **Step 3: Add the due focus panel**

Add this method to `_HomeTab`:

```dart
Widget _buildDueFocusPanel(BuildContext context, DeckProvider provider) {
  final l10n = AppLocalizations.of(context)!;
  final dueDecks = provider.decks.where((deck) => deck.dueCount > 0).toList();
  final primaryDeck = dueDecks.isNotEmpty ? dueDecks.first : null;
  final hasDue = provider.totalDueCards > 0 && primaryDeck != null;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.55,
          ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.today,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          hasDue ? l10n.cardsDue(provider.totalDueCards) : l10n.allCaughtUp,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          hasDue ? primaryDeck.name : l10n.noCardsToReviewToday,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary(context),
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasDue) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => DeckNavigation.navigateToStudy(context, primaryDeck.id),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startStudy),
            ),
          ),
        ],
      ],
    ),
  );
}
```

- [ ] **Step 4: Update due and recent deck sections to use `DeckSummaryCard`**

Replace `_DueDeckCard`, `_RecentDeckCard`, and `_ResponsiveCardList` item builders with `DeckSummaryCard`:

```dart
_ResponsiveCardList(
  items: dueDecks.take(3).toList(),
  itemBuilder: (deck) => DeckSummaryCard(
    deck: deck,
    cardCountLabel: l10n.nCards(deck.cardCount),
    dueLabel: l10n.cardsDue(deck.dueCount),
    studyLabel: l10n.study,
    onTap: () => DeckNavigation.navigateToStudy(context, deck.id),
    onStudy: () => DeckNavigation.navigateToStudy(context, deck.id),
    compact: true,
  ),
)
```

For recent decks:

```dart
_ResponsiveCardList(
  items: provider.decks.take(3).toList(),
  itemBuilder: (deck) => DeckSummaryCard(
    deck: deck,
    cardCountLabel: l10n.nCards(deck.cardCount),
    dueLabel: deck.dueCount > 0 ? l10n.cardsDue(deck.dueCount) : null,
    onTap: () => DeckNavigation.navigateToBrowse(context, deck.id),
    trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary(context)),
    compact: true,
  ),
)
```

Delete now-unused private classes `_DueDeckCard` and `_RecentDeckCard` after replacing all references.

- [ ] **Step 5: Run analyzer for Home changes**

Run:

```powershell
flutter analyze
```

Expected: no new analyzer errors from `home_screen.dart`.

- [ ] **Step 6: Commit Task 2**

Run:

```powershell
git add lib/presentation/screens/home/home_screen.dart
git commit -m "Redesign home dashboard"
```

---

### Task 3: Refine Deck List Card Hierarchy

**Files:**
- Modify: `lib/presentation/screens/deck/deck_list_screen.dart`
- Test: `test/presentation/widgets/deck/deck_summary_card_test.dart`

- [ ] **Step 1: Import reusable deck status chip**

In `lib/presentation/screens/deck/deck_list_screen.dart`, add:

```dart
import '../../widgets/deck/deck_summary_card.dart';
```

- [ ] **Step 2: Tighten `ResponsiveGrid` extent if required**

Keep this value if the card still fits after implementation:

```dart
mainAxisExtent: 175,
```

If analyzer/manual layout shows overflow in desktop grid mode, increase only to:

```dart
mainAxisExtent: 188,
```

Do not change `ResponsiveGrid.minCardWidth`.

- [ ] **Step 3: Refine `_DeckCard` content zones**

Inside `_DeckCard.build`, keep the current `Card`, `InkWell`, menu, and navigation behavior. Replace the lower stats row with `DeckStatusChip` usage:

```dart
Wrap(
  spacing: 12,
  runSpacing: 6,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    if (deck.category != null)
      _CategoryChip(categoryId: deck.category!),
    DeckStatusChip(
      icon: Icons.style,
      label: l10n.nCards(deck.cardCount),
      color: AppColors.info,
    ),
    if (deck.newCount > 0)
      DeckStatusChip(
        icon: Icons.fiber_new,
        label: l10n.nNew(deck.newCount),
        color: AppColors.error,
        emphasized: true,
      ),
    if (deck.reviewCount > 0)
      DeckStatusChip(
        icon: Icons.replay,
        label: l10n.nReview(deck.reviewCount),
        color: AppColors.warning,
        emphasized: true,
      ),
  ],
)
```

Move the Study button to the far right below or beside the stats depending on available width:

```dart
if (deck.dueCount > 0)
  Align(
    alignment: Alignment.centerRight,
    child: SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToStudy(context),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: Text(l10n.study),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
    ),
  ),
```

- [ ] **Step 4: Extract `_CategoryChip` private widget**

Add this private widget near `_StatChip` replacement area:

```dart
class _CategoryChip extends StatelessWidget {
  final String categoryId;

  const _CategoryChip({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final category = Category.predefined.where((c) => c.id == categoryId).firstOrNull;
    final categoryName = category?.getLocalizedName(
          Localizations.localeOf(context).languageCode,
        ) ??
        categoryId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _categoryIcon(category?.icon),
            size: 13,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            categoryName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(String? iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'translate':
        return Icons.translate;
      case 'flight':
        return Icons.flight;
      case 'business':
        return Icons.business;
      case 'home':
        return Icons.home;
      case 'menu_book':
        return Icons.menu_book;
      case 'chat_bubble':
        return Icons.chat_bubble;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
```

Delete the old `_StatChip` class and `_getCategoryIcon` method if they are no longer referenced.

- [ ] **Step 5: Run analyzer for Deck list changes**

Run:

```powershell
flutter analyze
```

Expected: no new analyzer errors from `deck_list_screen.dart`.

- [ ] **Step 6: Commit Task 3**

Run:

```powershell
git add lib/presentation/screens/deck/deck_list_screen.dart
git commit -m "Refine deck list cards"
```

---

### Task 4: Ignore Visual Companion Artifacts

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add `.superpowers/` to `.gitignore`**

Add this line near the other local/tooling ignores:

```gitignore
.superpowers/
```

- [ ] **Step 2: Verify companion artifacts are ignored**

Run:

```powershell
git status --short -- .superpowers .gitignore
```

Expected: `.gitignore` is modified and `.superpowers/` is not listed as untracked.

- [ ] **Step 3: Commit Task 4**

Run:

```powershell
git add .gitignore
git commit -m "Ignore brainstorm companion artifacts"
```

---

### Task 5: Final Verification

**Files:**
- Verify: `lib/presentation/screens/home/home_screen.dart`
- Verify: `lib/presentation/screens/deck/deck_list_screen.dart`
- Verify: `lib/presentation/widgets/deck/deck_summary_card.dart`
- Verify: `test/presentation/widgets/deck/deck_summary_card_test.dart`

- [ ] **Step 1: Run targeted widget test**

Run:

```powershell
flutter test test/presentation/widgets/deck/deck_summary_card_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: no analyzer errors.

- [ ] **Step 3: Inspect git diff**

Run:

```powershell
git diff -- lib/presentation/screens/home/home_screen.dart lib/presentation/screens/deck/deck_list_screen.dart lib/presentation/widgets/deck/deck_summary_card.dart test/presentation/widgets/deck/deck_summary_card_test.dart .gitignore
```

Expected:

- No backend, database, route, provider, or SM-2 changes.
- No new l10n keys unless implementation intentionally introduced new visible text.
- Home uses focused dashboard sections.
- Deck list still preserves search, filter sheet, menu actions, browse navigation, and study navigation.

- [ ] **Step 4: Final commit if any verification-only fixes were needed**

If verification required small fixes after previous commits, commit only those files:

```powershell
git add lib/presentation/screens/home/home_screen.dart lib/presentation/screens/deck/deck_list_screen.dart lib/presentation/widgets/deck/deck_summary_card.dart .gitignore
git add -f test/presentation/widgets/deck/deck_summary_card_test.dart
git commit -m "Polish home deck redesign"
```

If no files changed after verification, skip this commit.
