# Project Summary
**Last Updated:** 2026-01-28
**Updated By:** Claude Code - Windows REST API & Localization

---

## 1. Project Overview
- **Name:** VocabFlip
- **Type:** Multi-language vocabulary learning flashcard app
- **Tech Stack:** Flutter 3.38.7, Dart, Provider, SQLite, Firebase
- **i18n:** ARB files (app_en.arb, app_vi.arb) with flutter_localizations
- **Platforms:** Windows (primary), Web, Android
- **Windows Support:** Firestore via REST API (native SDK crashes)

---

## 2. Current Architecture

### File Structure (Key Files Only)
```
lib/
├── main.dart                    # Entry point, orientation, preferences init
├── app.dart                     # MultiProvider, theme, routing, localization
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # SM-2 defaults, DB config, Firestore collections
│   │   ├── api_endpoints.dart   # Free Dictionary, Jisho API URLs
│   │   └── supported_languages.dart  # Language enum + pairs (EN↔VI↔JA↔ZH)
│   ├── theme/
│   │   ├── app_colors.dart      # Color palette (primary, status, badges)
│   │   └── app_theme.dart       # Material 3 light/dark themes
│   ├── utils/
│   │   └── spaced_repetition.dart # SM-2 algorithm implementation
│   └── extensions/
│       └── string_extensions.dart # String utilities
│
├── data/
│   ├── models/                  # Data classes with toMap/fromMap
│   │   ├── flashcard.dart       # SM-2 fields included
│   │   ├── deck.dart            # With computed card counts + library linking
│   │   ├── study_session.dart   # Session tracking
│   │   ├── dictionary_result.dart # API response models
│   │   ├── public_deck.dart     # Public library deck (Firestore + REST)
│   │   ├── public_flashcard.dart # Public flashcard (Firestore + REST)
│   │   ├── deck_rating.dart     # Rating model (1-5 stars)
│   │   ├── category.dart        # Predefined categories
│   │   ├── imported_deck_link.dart # Track sync links
│   │   └── sync_notification.dart # Update notifications
│   ├── local/
│   │   ├── database/
│   │   │   ├── app_database.dart    # Singleton SQLite setup
│   │   │   ├── deck_dao.dart        # Deck CRUD + counts
│   │   │   └── flashcard_dao.dart   # Flashcard CRUD + queries
│   │   └── preferences/
│   │       └── app_preferences.dart # SharedPreferences wrapper
│   ├── remote/
│   │   ├── api/                 # Dictionary API clients
│   │   │   ├── free_dictionary_api.dart  # English
│   │   │   └── jisho_api.dart            # Japanese
│   │   └── firebase/            # Firebase services
│   │       ├── firebase_service.dart      # Auth + ID token
│   │       ├── firestore_rest_client.dart # REST API for Windows
│   │       ├── public_library_service.dart # Public deck CRUD (REST + Native)
│   │       ├── rating_service.dart        # Deck ratings
│   │       ├── sync_service.dart          # Import/sync tracking
│   │       ├── category_seeder.dart       # Seed categories (REST + Native)
│   │       └── public_deck_seeder.dart    # Seed sample deck (REST + Native)
│   ├── repositories/            # Business logic layer
│   │   ├── deck_repository.dart      # Deck ops + import/export
│   │   ├── flashcard_repository.dart # SM-2 integration
│   │   ├── dictionary_repository.dart # Language routing
│   │   └── public_library_repository.dart # Public library operations
│   └── services/
│       ├── tts_service.dart     # Text-to-speech wrapper
│       └── import_export_service.dart # JSON handling
│
├── presentation/
│   ├── providers/               # ChangeNotifier state management
│   │   ├── deck_provider.dart
│   │   ├── flashcard_provider.dart
│   │   ├── study_provider.dart  # StudyState enum
│   │   ├── dictionary_provider.dart
│   │   ├── settings_provider.dart # Theme, locale, preferences
│   │   ├── public_library_provider.dart # Browse/search/import
│   │   ├── publish_provider.dart # Publish workflow
│   │   └── sync_provider.dart   # Sync/notifications
│   ├── screens/
│   │   ├── home/home_screen.dart        # Main navigation + stats (6 tabs)
│   │   ├── deck/                        # Deck CRUD screens
│   │   │   ├── deck_list_screen.dart    # List with sync badges
│   │   │   ├── deck_detail_screen.dart  # Detail + publish/sync
│   │   │   └── create_deck_screen.dart  # Create/edit with language selection
│   │   ├── flashcard/                   # Card editor/viewer
│   │   ├── study/study_screen.dart      # Study session UI
│   │   ├── dictionary/                  # Word lookup
│   │   ├── statistics/                  # Charts & progress
│   │   ├── settings/                    # User preferences
│   │   ├── library/                     # Public library
│   │   │   ├── library_screen.dart      # Browse with tabs
│   │   │   ├── public_deck_detail_screen.dart # Deck details + import
│   │   │   └── library_search_screen.dart # Search functionality
│   │   ├── publish/                     # Publish workflow
│   │   │   ├── publish_deck_screen.dart # Publish with category/tags
│   │   │   └── manage_published_screen.dart # Manage published decks
│   │   └── sync/
│   │       └── sync_notifications_screen.dart # Update notifications
│   └── widgets/
│       ├── common/              # Loading, error, empty states
│       ├── flashcard/
│       │   └── flip_card.dart   # 3D flip animation widget
│       ├── library/             # Public library widgets
│       │   ├── public_deck_card.dart # Deck card display
│       │   ├── rating_widget.dart    # Star rating components
│       │   ├── filter_sheet.dart     # Filter bottom sheet
│       │   └── tag_input.dart        # Tag input with autocomplete
│       └── sync/
│           └── sync_badge.dart  # Sync status indicators
│
└── l10n/                        # Localization
    ├── app_en.arb               # English strings
    ├── app_vi.arb               # Vietnamese strings
    ├── app_localizations.dart   # Generated delegate
    ├── app_localizations_en.dart
    └── app_localizations_vi.dart
```

### Component Dependencies
```
                    ┌─────────────────┐
                    │   main.dart     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    app.dart     │
                    │  (MultiProvider │
                    │  + Localization)│
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   Providers   │   │   Screens     │   │   Widgets     │
│ (ChangeNotify)│◄──│ (Consumer)    │   │               │
└───────┬───────┘   └───────────────┘   └───────────────┘
        │
        ▼
┌───────────────┐
│  Repositories │
└───────┬───────┘
        │
   ┌────┴────┐
   ▼         ▼
┌──────┐  ┌──────────────┐
│ DAOs │  │ Firebase     │
└──┬───┘  │ (REST/Native)│
   ▼      └──────────────┘
┌──────────┐
│  SQLite  │
└──────────┘
```

---

## 3. Platform-Specific Implementation

### Windows (Primary Platform)
- **Firestore:** REST API via `FirestoreRestClient`
- **Why:** Native C++ SDK crashes immediately
- **Trade-offs:**
  - ✅ 100% stable
  - ❌ No real-time listeners
  - ❌ No offline persistence

### Android/iOS/Web
- **Firestore:** Native SDK (`cloud_firestore`)
- **Features:** Real-time, offline persistence

### Platform Detection
```dart
// In FirestoreRestClient
static bool get shouldUseRest => !kIsWeb && Platform.isWindows;

// In services
if (_useRest) {
  return _methodRest();  // REST API
}
return _methodNative();  // Firestore SDK
```

---

## 4. Key Decisions & Patterns

### State Management
- **Pattern:** Provider with ChangeNotifier
- **Why:** Simple, lightweight, sufficient for app complexity
- **Structure:** One provider per feature domain

### Data Layer
- **Pattern:** Repository + DAO + Service
- **Why:** Separation of business logic from data access
- **Models:** Immutable with `copyWith()`, dual serialization

### Spaced Repetition
- **Algorithm:** SM-2 (SuperMemo 2)
- **Location:** `core/utils/spaced_repetition.dart`
- **Integration:** Called from `FlashcardRepository.reviewFlashcard()`

### Localization
- **System:** Flutter gen-l10n
- **Files:** ARB format (app_en.arb, app_vi.arb)
- **Usage:** `AppLocalizations.of(context)!.keyName`

### Styling Approach
- **Design System:** Material 3 (useMaterial3: true)
- **Theme:** Light/Dark mode via SettingsProvider
- **Colors:** Centralized in `app_colors.dart`

---

## 5. Active Features & Status

| Feature | Status | Platform Notes |
|---------|--------|----------------|
| Deck Management | ✅ Complete | All platforms |
| Flashcard CRUD | ✅ Complete | Auto-fill from dictionary |
| SM-2 Spaced Repetition | ✅ Complete | All platforms |
| Study Session | ✅ Complete | Flip, rate, progress |
| Dictionary Lookup (EN) | ✅ Complete | Free Dictionary API |
| Dictionary Lookup (JA) | ✅ Complete | Jisho API |
| Text-to-Speech | ✅ Complete | Multi-language |
| Statistics | ✅ Complete | Charts with fl_chart |
| Import/Export (JSON) | ✅ Complete | All platforms |
| Dark Mode | ✅ Complete | Toggle in settings |
| **Localization** | ✅ Complete | EN/VI supported |
| **Public Library** | ✅ Complete | REST on Windows |
| **Deck Import** | ✅ Complete | With sync link |
| **Deck Publishing** | ✅ Complete | Category/tags |
| **Deck Rating** | ✅ Complete | 5-star + reviews |
| **Deck Sync** | ✅ Complete | Auto-detect updates |
| Firebase Auth | ✅ Complete | Google, Email/Pass |
| **Windows Support** | ✅ Complete | Via REST API |
| Google Translate | 🚧 Framework | Needs API key |
| Quiz Modes | ⏳ Planned | Multiple choice |

---

## 6. Supported Languages

### UI Languages
- English (en)
- Vietnamese (vi)

### Learning Language Pairs
| Source | Target |
|--------|--------|
| English | Vietnamese, Japanese, Chinese |
| Vietnamese | English, Japanese, Chinese |
| Japanese | Vietnamese, English |
| Chinese | Vietnamese, English |

**Note:** Target language for deck creation is fixed to Vietnamese (design decision for Vietnamese learners).

---

## 7. Known Issues & TODOs

### High Priority
- [ ] Update SyncService and RatingService with REST API support
- [ ] Set up Firestore security rules for public_decks collection
- [ ] Add offline caching for Windows using local storage

### Medium Priority
- [ ] Update all screens to use AppLocalizations consistently
- [ ] Add comprehensive unit tests for repositories
- [ ] Implement real-time polling as alternative to listeners on Windows
- [ ] Deploy Cloud Functions for sync notifications

### Low Priority
- [ ] Implement Google Translate integration
- [ ] Add widget tests for screens
- [ ] Add analytics for published deck performance
- [ ] Fix remaining deprecation warnings (withOpacity → withValues)

---

## 8. Important Context for Claude

### When making changes:
1. Always update this file's "Last Updated" timestamp
2. Create new history entry in `.claude/history/`
3. Follow naming conventions in CONVENTIONS.md
4. Run `flutter analyze` before committing
5. Keep Provider pattern - don't introduce BLoC/Riverpod
6. **For Firestore operations:** Check if REST API version exists for Windows

### Critical Files (read before major changes):
- `lib/app.dart` - Provider setup, routing, localization
- `lib/data/remote/firebase/firestore_rest_client.dart` - REST API implementation
- `lib/core/utils/spaced_repetition.dart` - SM-2 algorithm
- `lib/data/local/database/app_database.dart` - Database schema
- `pubspec.yaml` - Dependencies

### Database Schema Note:
**SQLite Tables:** `decks`, `flashcards`, `study_sessions`, `review_logs`, `imported_deck_links`
- Flashcards have SM-2 fields: `easiness_factor`, `interval`, `repetitions`, `next_review_date`
- Decks have library fields: `linked_public_deck_id`, `linked_version`, `is_published`, `published_deck_id`
- **Database Version:** 2

**Firestore Collections:**
- `public_decks/{deckId}` - Published decks
- `public_decks/{deckId}/flashcards/{cardId}` - Public flashcards
- `public_decks/{deckId}/ratings/{userId}` - Deck ratings
- `categories/{categoryId}` - Predefined categories
- `users/{userId}/imported_decks/{importId}` - Import links
- `sync_notifications/{notifId}` - Update notifications

---

## 9. Recent Changes (Last 3 Sessions)

1. **2026-01-28** - Windows Platform Support & Localization
   - Created FirestoreRestClient for Windows (bypasses crashing C++ SDK)
   - Updated PublicLibraryService, CategorySeeder, PublicDeckSeeder with dual-mode
   - Added fromMap() constructors to PublicDeck and PublicFlashcard
   - Configured localization in app.dart (locale, delegates)
   - Extended supported language pairs (bidirectional)
   - Fixed structured query type casting bug
   - Updated create_deck_screen with improved language selector UI

2. **2026-01-27 16:00** - Public Library Feature Implementation
   - Added 6 new data models for public library
   - Created 3 Firebase services (public_library, rating, sync)
   - Added 3 new providers (public_library, publish, sync)
   - Created 6 new screens (library, publish, manage, notifications)
   - Database migration v1→v2 with library linking fields
   - Updated home_screen with Library tab (6 tabs total)

3. **2026-01-27 14:30** - Initial project creation
   - Created complete Flutter project structure (51 Dart files)
   - Implemented all Phase 1-6 features from plan
   - Set up .claude documentation

---

## 10. Quick Commands
```bash
# Development (Windows - primary)
cd vocabflip
flutter run -d windows

# Development (Web)
flutter run -d chrome

# Development (Android)
flutter run -d <device-id>

# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Build APK (release)
flutter build apk --release

# Build Windows (release)
flutter build windows --release

# Run tests
flutter test

# Generate localizations
flutter gen-l10n

# Clean build
flutter clean && flutter pub get
```

---

## 11. Environment Notes
- **Flutter SDK:** 3.38.7
- **Dart SDK:** Compatible
- **Gradle:** 8.4
- **Android Gradle Plugin:** 8.1.0
- **Kotlin:** 1.8.22
- **Java Target:** 17
- **Windows:** Visual Studio 2022 with C++ Desktop Development

---

## 12. Firebase Configuration

### Project Info
- **Project ID:** vocal-flip
- **API Key:** AIzaSyD_nazGJzlQrUSPmsTWZmGDp0Ey7pD6-Rc (in firestore_rest_client.dart)

### Configured Platforms
- ✅ Android (google-services.json)
- ✅ Web (firebase_options.dart)
- ✅ Windows (uses web config via REST API)

---

**NOTE TO CLAUDE CODE:**
Read this file FIRST before making any changes.
Update Section 5, 7, 9 after each session.
Create history entry with details of changes made.
For Firestore changes, always implement both REST and Native versions.
