# Session: 2026-01-29 - Flashcard Images & SQLite Windows Fix

## Summary
Fixed SQLite not working on Windows desktop and added flashcard image support (URL or local file).

## Issues Fixed

### 1. SQLite Not Working on Windows
**Problem:** Deck creation silently failed on Windows desktop with no error message.

**Root Cause:** The `sqflite` package doesn't work on Windows desktop - requires FFI version.

**Solution:**
- Added `sqflite_common_ffi: ^2.4.0` and `sqlite3_flutter_libs: ^0.5.0` to pubspec.yaml
- Updated `app_database.dart` to initialize FFI factory for desktop platforms:
```dart
if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```
- Added error handling with user feedback in `create_deck_screen.dart`

### 2. Firestore Index Field Names
**Problem:** Firebase returned 400 errors for composite index queries.

**Root Cause:** `firestore.indexes.json` used camelCase (`isActive`) but Firestore data uses snake_case (`is_active`).

**Solution:** Updated all field names in `firestore.indexes.json` to snake_case.

## New Features

### Flashcard Images
Users can now add images to flashcards using either URL or local file.

**Files Created:**
- `lib/data/services/image_service.dart` - Image picking, saving, and management

**Files Modified:**
- `lib/data/models/flashcard.dart` - Added `imageUrl` field with helpers (`hasImage`, `isImageUrl`, `isLocalImage`)
- `lib/data/local/database/app_database.dart` - Migration v2→v3 adding `image_url` column
- `lib/core/constants/app_constants.dart` - Database version 2→3
- `lib/presentation/screens/flashcard/flashcard_editor_screen.dart` - Complete image UI
- `lib/presentation/widgets/flashcard/flip_card.dart` - Display images in FlashcardFace
- `lib/presentation/widgets/flashcard/card_content.dart` - Display images in CardContent
- `lib/presentation/screens/study/study_screen.dart` - Pass imageUrl to cards
- `lib/presentation/screens/flashcard/flashcard_viewer_screen.dart` - Pass imageUrl to cards
- `lib/l10n/app_en.arb` - 9 new localization keys
- `lib/l10n/app_vi.arb` - 9 new localization keys

**Image UI Features:**
- SegmentedButton toggle between "Local File" and "Image URL" modes
- URL mode: Text input with preview and validation
- Local file mode: Tap to pick, with edit/delete overlay buttons
- Images saved to app's documents directory with UUID filenames
- Old images cleaned up when replaced or removed

**New Localization Keys:**
- `image`, `imageOptional`, `localFile`, `imageUrl`
- `enterImageUrl`, `invalidImageUrl`
- `tapToAddImage`, `changeImage`, `removeImage`

## Other Files Created
- `deploy_indexes.bat` - Script to deploy Firestore indexes using Firebase CLI

## Database Changes
- **Version:** 2 → 3
- **New Column:** `flashcards.image_url TEXT`

## Dependencies Added
```yaml
sqflite_common_ffi: ^2.4.0
sqlite3_flutter_libs: ^0.5.0
```

## Testing Notes
- `flutter analyze` passes with no errors (only warnings/info)
- Deck creation works on Windows
- Image feature ready for testing

---

# Session 2: Auth System, Image Settings, Navigation Improvements

## Summary
Added authentication system, flashcard image size settings, navigation improvements, and various bug fixes.

## New Features

### 1. Authentication System
**Files Created:**
- `lib/presentation/providers/auth_provider.dart` - Auth state management
- `lib/presentation/screens/auth/login_screen.dart` - Email + Google sign in
- `lib/presentation/screens/auth/signup_screen.dart` - Account creation

**Features:**
- Email/password sign in and sign up
- Google sign in support
- Forgot password functionality
- Auth state persistence
- Account section in Settings screen

### 2. Flashcard Image Size Settings
**Changes:**
- Added `flashcardImageMaxWidth` setting to `AppPreferences`
- Default: 1000px on Windows/macOS/Linux, 600px on mobile
- UI in Settings to choose from 400px to 1500px
- Images auto-resize on save to match setting (saves storage)

**Files Modified:**
- `lib/data/local/preferences/app_preferences.dart` - New setting
- `lib/presentation/providers/settings_provider.dart` - New getter/setter
- `lib/presentation/screens/settings/settings_screen.dart` - UI for setting
- `lib/data/services/image_service.dart` - Image resize functionality
- `lib/presentation/widgets/flashcard/flip_card.dart` - Use setting for display
- `lib/presentation/widgets/flashcard/card_content.dart` - Use setting for display

### 3. Navigation Improvements
**Files Created:**
- `lib/core/utils/deck_navigation.dart` - Reusable navigation helper

**Changes:**
- Tapping deck now goes to Browse (flashcards) instead of Detail screen
- Menu option "Deck Details" to go to detail screen for adding cards
- Navigation helper used in: DeckListScreen, HomeScreen, PublicDeckDetailScreen

### 4. Firebase CLI Tool
**Files Created:**
- `tools/firebase_setup.dart` - Generate and deploy Firestore indexes/rules

**Usage:**
```bash
dart run tools/firebase_setup.dart generate  # Generate files
dart run tools/firebase_setup.dart indexes   # Deploy indexes
dart run tools/firebase_setup.dart rules     # Deploy rules
dart run tools/firebase_setup.dart all       # Deploy everything
```

## Bug Fixes

### TTS Service (Windows)
- `setSharedInstance()` only called on iOS/macOS
- Added try-catch and `_isAvailable` flag for graceful degradation

### REST API Support
- Updated `RatingService` with REST API for Windows
- Updated `SyncService` with REST API for Windows
- Added `fromMap()` to `DeckRating`, `SyncNotification`, `ImportedDeckLink`

### Hero Tag Conflict
- Added unique `heroTag` to FloatingActionButtons in deck screens

### Flashcard Viewer
- Removed audio button from FlashcardFace
- Replaced flip icon with audio play button in navigation bar
- Fixed image URL display ratio

## New Dependencies
```yaml
image: ^4.1.3  # For image resizing
```

## New Localization Keys
- Auth: `account`, `signInWithEmail`, `createAccount`, `email`, `password`, etc.
- Settings: `flashcardImageSize`, `recommendedForMobile`, `recommendedForDesktop`, `balanced`

## Files Modified Summary
- 15+ files modified
- 5 new files created
- 20+ localization keys added

## Testing Notes
- `flutter analyze` passes with no errors (only info-level warnings)
- Auth flow ready for testing
- Image resize works in background isolate
