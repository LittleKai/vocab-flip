# Session: Card Structure Configuration & TTS Improvements
**Date:** 2026-01-31
**Focus:** Deck card structure, TTS fixes, UI improvements

---

## Changes Made

### 1. Card Structure Configuration (Deck Settings)
- Added 2-tab interface in Create/Edit Deck:
  - **Tab 1:** Basic Info (name, description, language, display mode, auto-play TTS)
  - **Tab 2:** Card Structure (front/back field configuration)
- Added drag-and-drop between Front/Back sections for fields
- Added `CardFieldType` enum: word, phonetic, meaning, example, notes
- Added `ImageDisplayMode` enum: none, both, front, back
- **Initially locked Word to Front and Meaning to Back, then removed restriction per user request**
- Fields can now be freely moved between Front and Back

### 2. Database Changes
- **Database version:** 6 → 7
- New columns in `decks` table:
  - `front_fields` (TEXT, default: 'word,phonetic')
  - `back_fields` (TEXT, default: 'meaning,example,notes')
  - `image_display_mode` (TEXT, default: 'both')
  - `auto_play_tts_on_flip` (INTEGER, default: 1)

### 3. StructuredFlashcardFace Widget
- New widget that renders flashcard content dynamically based on deck configuration
- Respects field order from deck settings
- Shows/hides image based on `imageDisplayMode`

### 4. TTS Improvements
- **Fixed pronunciation button** - Now only speaks word (front), not meaning
- **Uses source language** for TTS (JP deck → Japanese TTS, CN → Chinese TTS)
- **Added auto-play on flip** setting in deck configuration (default: enabled)
- **TTS Warning Dialog** for missing language voices on Windows:
  - Shows when entering a deck with unsupported TTS language
  - Provides step-by-step Windows voice installation instructions
  - "Don't show again" checkbox option
  - Helper icon in Settings to view instructions anytime

### 5. UI Fixes
- **Fixed ReorderableListView drag handle** - Added `buildDefaultDragHandles: false` to prevent duplicate drag icons
- **Changed card sort order** - New cards now appear at bottom (ASC instead of DESC)
- **Added pronunciation button** to Study Screen
- **Fixed "Study Again" button** - Now reshuffles cards instead of loading empty due list

### 6. Study Screen Enhancements
- Added TTS button next to stats bar
- Fixed forceReload parameter for Study Again functionality
- Auto-play TTS respects deck's `autoPlayTtsOnFlip` setting

---

## Files Modified

### Core/Models
- `lib/data/models/deck.dart` - Added CardFieldType, ImageDisplayMode, autoPlayTtsOnFlip

### Database
- `lib/data/local/database/app_database.dart` - Migration v6→v7
- `lib/core/constants/app_constants.dart` - Database version 7
- `lib/data/local/database/flashcard_dao.dart` - Changed order to ASC

### Screens
- `lib/presentation/screens/deck/create_deck_screen.dart` - 2-tab structure UI
- `lib/presentation/screens/deck/deck_detail_screen.dart` - TTS check on enter, drag handle fix
- `lib/presentation/screens/flashcard/flashcard_viewer_screen.dart` - StructuredFlashcardFace, auto-play
- `lib/presentation/screens/study/study_screen.dart` - TTS button, Study Again fix
- `lib/presentation/screens/settings/settings_screen.dart` - TTS help button
- `lib/presentation/screens/home/home_screen.dart` - Removed global TTS check

### Widgets
- `lib/presentation/widgets/flashcard/flip_card.dart` - StructuredFlashcardFace widget
- `lib/presentation/widgets/dialogs/tts_help_dialog.dart` - NEW: TTS installation guide dialog

### Services
- `lib/data/services/tts_service.dart` - Language availability check, debug logging

### Providers
- `lib/presentation/providers/study_provider.dart` - forceReload parameter

### Preferences
- `lib/data/local/preferences/app_preferences.dart` - hideTtsWarning preference

### Localization
- `lib/l10n/app_en.arb` - TTS dialog strings
- `lib/l10n/app_vi.arb` - TTS dialog strings (Vietnamese)

---

## New Localization Keys
- `autoPlayTts`, `autoPlayTtsDesc`
- `ttsHelp`, `ttsLanguagesMissing`, `ttsLanguagesMissingDesc`
- `ttsInstallInstructions`, `ttsStepOpenSettings`, `ttsStepTimeLanguage`
- `ttsStepAddLanguage`, `ttsStepSelectLanguage`, `ttsStepDownloadSpeech`
- `ttsStepRestartApp`, `ttsGenericInstructions`, `dontShowAgain`, `ttsSettings`

---

## Technical Notes

### TTS Language Check Logic
1. Check happens when entering a deck (not on app start)
2. Only checks the specific language of that deck
3. Checks `hideTtsWarning` preference before showing dialog
4. Only shows on Windows/Linux (desktop platforms)

### Card Structure Storage
- Fields stored as comma-separated names: `"word,phonetic,meaning"`
- Parsed with `CardFieldType.values.firstWhere()`
- Default values used if parsing fails

### Flutter TTS Threading Issue
- Windows flutter_tts has threading issues with non-English voices
- Added try-catch and availability checks to prevent crashes
- Shows helpful dialog instead of silent failure

---

## Firebase Changes
**None** - All changes in this session are SQLite and client-side only.
