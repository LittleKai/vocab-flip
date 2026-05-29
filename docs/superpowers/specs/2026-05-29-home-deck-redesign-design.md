# VocabFlip Home + Deck List Redesign Design

## Goal

Refresh the first-run and daily-use experience for VocabFlip by redesigning the Home tab as a focused learning dashboard and tightening the Deck list for faster scanning. This design covers only Home and Deck list UI. It does not change study scheduling, SM-2 behavior, database schema, backend API behavior, authentication, or state management.

## Selected Direction

Use direction A: Focused dashboard.

Home should answer "what should I study today?" quickly, while still showing enough deck context to navigate. Deck list should remain a management surface, but with clearer hierarchy and less visual crowding.

## Constraints

- Keep Provider-based state management.
- Keep existing `HomeScreen`, `DeckListScreen`, `ResponsiveGrid`, `DeckNavigation`, and route patterns unless a small extraction is needed for readability.
- Preserve current bottom navigation structure and tab order.
- Do not change review counts, due logic, deck model semantics, sync state, or publish/link behavior.
- Follow Flutter Material 3 patterns already used by the project.
- Use 8 point spacing increments where practical.
- Support mobile, desktop, and web through existing responsive patterns.
- Any new visible UI text must be added to both English and Vietnamese l10n files.

## Home Dashboard

The Home tab becomes a daily learning dashboard with these sections, in order:

1. Header summary
   - Shows greeting, streak, and concise daily context.
   - Uses a calmer, more polished surface than the current large saturated gradient.
   - Keeps the app identity visible without turning the page into a landing page.

2. Due today focus panel
   - Primary visual element on Home.
   - Shows total due cards and a clear Study action.
   - If there are due decks, the action starts the most relevant due deck. The initial implementation can choose the first due deck from the current provider ordering to avoid changing domain logic.
   - If there are no due cards, show the caught-up state with subdued success styling.

3. Quick stats
   - Shows decks, cards, and due counts.
   - Uses compact stat tiles with stable dimensions.
   - Avoids oversized decorative cards.

4. Due decks
   - Shows up to three due decks.
   - Each row/card includes image, deck name, language badge, due count, total card count, and Study button.
   - Study button is prominent but sized to avoid text overflow on mobile.

5. Recent decks
   - Shows up to three recent decks after due decks.
   - Recent cards are visually quieter than due cards.
   - If there are no decks, the existing empty state behavior should remain handled by Deck list rather than adding a new Home-only creation flow.

## Deck List

The Deck list remains a deck management and browsing screen, with these UI refinements:

1. Search and filter
   - Keep existing search toggle behavior unless implementation shows a simple always-visible search field fits without reducing mobile usability.
   - Make deck count and active filter state easier to scan.
   - Keep existing filter bottom sheet behavior.

2. Deck cards
   - Preserve card tap to browse and menu actions for details, edit, and delete.
   - Organize content into clear zones:
     - Title, image, language/field badges, and status icons.
     - Optional description and tags.
     - Category, card/new/review counts, and Study action.
   - Study button appears only when `deck.dueCount > 0`.
   - Published and linked indicators stay visible but should not compete with the deck title.

3. Responsive behavior
   - Continue using `ResponsiveGrid`.
   - Maintain readable card widths on desktop and natural list behavior on mobile.
   - Ensure fixed grid extents are updated only if the new deck card height requires it.

## Components

Prefer small private widgets inside the existing screen files if the scope stays local. Extract reusable widgets only when they are used by both Home and Deck list or when a build method becomes hard to read.

Likely implementation units:

- Home daily summary panel.
- Home stat tile.
- Home compact deck row/card.
- Deck list card layout update.

No new state provider is required.

## Data Flow

Home continues to read from `DeckProvider` and `SettingsProvider`.

- Due cards: `deckProvider.totalDueCards`.
- Deck/card totals: existing `DeckProvider` aggregate getters.
- Due decks: `provider.decks.where((deck) => deck.dueCount > 0)`.
- Recent decks: existing provider ordering with `take(3)`.
- Navigation: existing `DeckNavigation.navigateToStudy` and `DeckNavigation.navigateToBrowse`.

Deck list continues to use `DeckProvider` for loading, search, filters, and filtered deck results, and `SyncProvider` for linked deck update indicators.

## Empty, Loading, and Error States

- Keep current loading behavior for Deck list.
- Keep current Deck list empty state and create deck action.
- Home caught-up state should remain visible when no decks are due.
- No new network or backend error states are introduced.

## Localization

Reuse existing l10n keys where possible, including app title, greeting, streak, deck/card/due labels, study labels, due text, and caught-up text.

If implementation needs new copy such as "Today" or "Ready for review", add keys to:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_vi.arb`

Then regenerate or update generated localization files according to the project's Flutter l10n workflow.

## Testing and Verification

Implementation should be verified with:

- `flutter analyze`
- Existing widget tests if they remain applicable.
- Manual responsive inspection for mobile-width and desktop-width layouts.
- Manual dark mode inspection, because this redesign changes surface hierarchy.

Risk areas:

- Text overflow in deck cards on mobile.
- Grid `mainAxisExtent` being too short after layout changes.
- Light/dark contrast for new surfaces.
- New l10n keys missing from one locale.

## Out of Scope

- Study screen redesign.
- Public library redesign.
- Settings, statistics, dictionary, auth, sync, or publish screens.
- New animations beyond standard Material interactions.
- New packages.
- Backend, database, or algorithm changes.
