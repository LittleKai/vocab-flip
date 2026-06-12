# SPEC: UI Refactoring - System-wide Dialog Standardization

## Goal
Standardize all dialogs across the VocabFlip system by replacing the legacy `showDialog` + `AlertDialog` pattern with the new `showStandardDialog` (powered by `AwesomeDialog`). This ensures a unified, modern "Product" aesthetic (Light/Dark mode compliant, rounded corners, clean typography) across the entire app without breaking existing complex UI structures like Forms or ProgressBars.

## Context / Constraints
- **Core Component:** `lib/presentation/widgets/dialogs/standard_dialog.dart` provides `showStandardDialog`.
- **Constraint 1 (No breaking UI):** Many dialogs contain stateful widgets (e.g., `StatefulBuilder`, `TextField`, `LinearProgressIndicator`). The new `showStandardDialog` supports `body` (for arbitrary widgets). The refactor must correctly map `AlertDialog.content` to `showStandardDialog(body: ...)`, and `AlertDialog.actions` to `btnOkOnPress`/`btnCancelOnPress` or keep custom buttons if needed.
- **Constraint 2 (Return values):** `showStandardDialog` returns the generic type passed to it (or relies on `Navigator.pop(context, value)`). The refactoring must preserve the exact return types (`Future<bool?>`, `Future<String?>`, etc.) expected by the calling functions.

---

## Batch 1: Settings & Backup Screens
**Focus:** The configuration and data safety screens contain many confirmation dialogs.

### Step 1.1: `settings_screen.dart`
- **File:** `lib/presentation/screens/settings/settings_screen.dart`
- **Action:** Replace all 8 usages of `showDialog` with `showStandardDialog`.
  - Delete Deck Confirmation
  - Reset Progress Confirmation
  - Logout Confirmation
  - Change Language Dialog (may contain a list/radio buttons -> map to `body`)
  - Theme Selection Dialog
- **Verify:** Run app, go to Settings, tap all actionable tiles and ensure dialogs display in the new style and return correct actions.

### Step 1.2: `backup_screen.dart` & `backup_progress_dialog.dart`
- **File:** `lib/presentation/screens/settings/backup_screen.dart` (3 usages)
- **File:** `lib/presentation/widgets/backup/backup_progress_dialog.dart` (3 usages)
- **Action:** Refactor confirmation dialogs (Create backup, Restore backup, Delete backup) and the progress UI overlay to use `showStandardDialog`. Ensure progress streams don't break when wrapped in the new dialog.
- **Verify:** Perform a fake/real backup and restore. Verify the UI updates correctly and dismisses when done.

---

## Batch 2: Deck Management & Dictionary
**Focus:** Core study preparation flows.

### Step 2.1: `deck_detail_screen.dart` & `deck_list_screen.dart`
- **File:** `lib/presentation/screens/deck/deck_detail_screen.dart` (6 usages)
- **File:** `lib/presentation/screens/deck/deck_list_screen.dart` (1 usage)
- **Action:** Refactor dialogs for: deleting a deck, deleting a specific card, importing cards, and renaming.
- **Verify:** Test deleting a card from the list in Deck Detail. Test deck deletion confirmation.

### Step 2.2: `dictionary_search_screen.dart`
- **File:** `lib/presentation/screens/dictionary/dictionary_search_screen.dart` (2 usages)
- **Action:** Refactor the "Add to Deck" dialog (which often contains a Dropdown/Form) and any TTS/Pronunciation helper dialogs.
- **Verify:** Search a word, tap "Add to Deck", ensure the dropdown renders correctly inside the `AwesomeDialog` body.

---

## Batch 3: Global Widgets, Study, Library, and Others
**Focus:** Edge cases, global helpers, and remaining screens.

### Step 3.1: Global Dialog Widgets
- **Files:** 
  - `lib/presentation/widgets/dialogs/profile_edit_dialog.dart`
  - `lib/presentation/widgets/dialogs/tts_help_dialog.dart`
  - `lib/presentation/widgets/dialogs/update_dialog.dart`
  - `lib/presentation/widgets/dialogs/update_progress_dialog.dart`
  - `lib/presentation/widgets/dialogs/feedback_dialog.dart`
  - `lib/presentation/widgets/dialogs/helper_dialog.dart`
- **Action:** These files encapsulate `showDialog` inside generic utility functions. Refactor them internally to use `showStandardDialog`.
- **Verify:** Test editing profile, opening TTS help, and sending feedback.

### Step 3.2: Study & Library Screens
- **Files:**
  - `lib/presentation/screens/study/study_screen.dart` (2 usages)
  - `lib/presentation/screens/library/library_screen.dart` (2 usages)
  - `lib/presentation/screens/library/public_deck_detail_screen.dart` (2 usages)
  - `lib/presentation/screens/publish/publish_deck_screen.dart` (1 usage)
  - `lib/presentation/screens/publish/manage_published_screen.dart` (1 usage)
- **Action:** Refactor confirmation dialogs for leaving study session mid-way, downloading public decks, and publishing decks.
- **Verify:** Start a study session and press the Back button. The confirmation dialog should be the new style.

### Step 3.3: Home & Admin
- **Files:**
  - `lib/presentation/screens/home/home_screen.dart` (1 usage)
  - `lib/presentation/screens/admin/admin_feedback_screen.dart` (1 usage)
- **Action:** Clean up remaining usages.
- **Verify:** Check home screen edge cases and admin dashboard actions.

---
## How to execute
This task has been divided into 3 independent batches. You can assign an AI agent to execute them one by one.
To start, open a terminal and run:
`use build` 
and prompt: "Hãy thực hiện Batch 1 của SPEC-ui-dialogs.md"
