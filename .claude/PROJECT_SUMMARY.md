# Project Summary
**Last Updated:** 2026-01-27 16:00 UTC
**Updated By:** Claude Code - Public Library Feature

---

## 1. Project Overview
- **Name:** VocabFlip
- **Type:** Multi-language vocabulary learning flashcard app
- **Tech Stack:** Flutter 3.5.1, Dart, Provider, SQLite, Firebase
- **i18n:** ARB files (app_en.arb, app_vi.arb) with flutter_localizations
- **Deployment:** Android (APK), iOS (pending configuration)

---

## 2. Current Architecture

### File Structure (Key Files Only)
```
lib/
├── main.dart                    # Entry point, orientation, preferences init
├── app.dart                     # MultiProvider setup, theme, routing
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # SM-2 defaults, DB config, animation durations
│   │   ├── api_endpoints.dart   # Free Dictionary, Jisho API URLs
│   │   └── supported_languages.dart  # Language enum (EN, VI, JA, ZH)
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
│   │   ├── public_deck.dart     # Public library deck model
│   │   ├── public_flashcard.dart # Public flashcard model
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
│   │       ├── firebase_service.dart      # Auth service
│   │       ├── public_library_service.dart # Public deck CRUD
│   │       ├── rating_service.dart        # Deck ratings
│   │       └── sync_service.dart          # Import/sync tracking
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
│   │   ├── settings_provider.dart
│   │   ├── public_library_provider.dart # Browse/search/import
│   │   ├── publish_provider.dart # Publish workflow
│   │   └── sync_provider.dart   # Sync/notifications
│   ├── screens/
│   │   ├── home/home_screen.dart        # Main navigation + stats (6 tabs)
│   │   ├── deck/                        # Deck CRUD screens
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
    ├── app_en.arb
    └── app_vi.arb
```

### Component Dependencies
```
                    ┌─────────────────┐
                    │   main.dart     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    app.dart     │
                    │  (MultiProvider)│
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
┌──────┐  ┌──────┐
│ DAOs │  │ APIs │
└──┬───┘  └──────┘
   ▼
┌──────────┐
│  SQLite  │
└──────────┘
```

---

## 3. Key Decisions & Patterns

### State Management
- **Pattern:** Provider with ChangeNotifier
- **Why:** Simple, lightweight, sufficient for app complexity
- **Structure:** One provider per feature domain (Deck, Flashcard, Study, Dictionary, Settings)

### Data Layer
- **Pattern:** Repository + DAO
- **Why:** Separation of business logic from data access, testability
- **Models:** Immutable with `copyWith()`, dual serialization (Map for DB, JSON for export)

### Spaced Repetition
- **Algorithm:** SM-2 (SuperMemo 2)
- **Location:** `core/utils/spaced_repetition.dart`
- **Integration:** Called from `FlashcardRepository.reviewFlashcard()`

### Styling Approach
- **Design System:** Material 3 (useMaterial3: true)
- **Theme:** Light/Dark mode via SettingsProvider
- **Colors:** Centralized in `app_colors.dart`
- **Component Styling:** Defined in `app_theme.dart` (buttons, cards, inputs)

### API Integration
- **HTTP Client:** `http` package with graceful error handling
- **Pattern:** Abstract interface + concrete implementations
- **Supported:** Free Dictionary (EN), Jisho (JA), Google Translate (stub)

---

## 4. Active Features & Status

| Feature | Status | Files Involved | Notes |
|---------|--------|----------------|-------|
| Deck Management | ✅ Complete | deck_*.dart, deck_provider | CRUD fully working |
| Flashcard CRUD | ✅ Complete | flashcard_*.dart | With auto-fill from dictionary |
| SM-2 Spaced Repetition | ✅ Complete | spaced_repetition.dart | Algorithm + integration |
| Study Session | ✅ Complete | study_screen.dart, study_provider | Flip, rate, progress tracking |
| Dictionary Lookup (EN) | ✅ Complete | free_dictionary_api.dart | Free Dictionary API |
| Dictionary Lookup (JA) | ✅ Complete | jisho_api.dart | Jisho API |
| Text-to-Speech | ✅ Complete | tts_service.dart | Multi-language support |
| Statistics | ✅ Complete | statistics_screen.dart | Charts with fl_chart |
| Import/Export (JSON) | ✅ Complete | import_export_service.dart | Version-stamped format |
| Dark Mode | ✅ Complete | app_theme.dart, settings_provider | Toggle in settings |
| **Public Library** | ✅ Complete | library_*, public_library_* | Browse, search, filter public decks |
| **Deck Import** | ✅ Complete | sync_service.dart | Import with sync link |
| **Deck Publishing** | ✅ Complete | publish_*, public_library_service | Share decks with community |
| **Deck Rating** | ✅ Complete | rating_*.dart | 5-star ratings with reviews |
| **Deck Sync** | ✅ Complete | sync_provider.dart | Auto-detect updates, merge content |
| Firebase Auth | ✅ Complete | firebase_service.dart | Google Sign-In, Email/Password |
| Google Translate | 🚧 Framework | google_translate_api.dart | Needs API key |
| Quiz Modes | ⏳ Planned | - | Multiple choice, type answer |

---

## 5. Known Issues & TODOs

### High Priority
- [ ] Configure Firebase project (google-services.json, GoogleService-Info.plist)
- [ ] Set up Firestore security rules for public_decks collection
- [ ] Deploy Cloud Functions for sync notifications

### Medium Priority
- [ ] Add comprehensive unit tests for repositories
- [ ] Implement quiz modes (multiple choice, type answer)
- [ ] Add audio pronunciation playback from dictionary
- [ ] Implement Cloud Functions to notify importers of deck updates

### Low Priority
- [ ] Add more `const` constructors (analyzer suggestions)
- [ ] Implement Google Translate integration
- [ ] Add widget tests for screens
- [ ] Optimize response time tracking in study sessions
- [ ] Add analytics for published deck performance

---

## 6. Important Context for Claude

### When making changes:
1. Always update this file's "Last Updated" timestamp
2. Create new history entry in `.claude/history/`
3. Follow naming conventions in CONVENTIONS.md
4. Run `flutter analyze` before committing
5. Keep Provider pattern - don't introduce BLoC/Riverpod

### Critical Files (read before major changes):
- `lib/app.dart` - Provider setup and routing
- `lib/core/utils/spaced_repetition.dart` - SM-2 algorithm (don't modify without understanding)
- `lib/data/local/database/app_database.dart` - Database schema
- `lib/data/models/flashcard.dart` - Core data model with SM-2 fields
- `pubspec.yaml` - Dependencies

### Database Schema Note:
**SQLite Tables:** `decks`, `flashcards`, `study_sessions`, `review_logs`, `imported_deck_links`
- Flashcards have SM-2 fields: `easiness_factor`, `interval`, `repetitions`, `next_review_date`
- Decks have library fields: `linked_public_deck_id`, `linked_version`, `is_published`, `published_deck_id`
- Cascade delete enabled: Deck → Flashcards → Reviews
- **Database Version:** 2 (migrated from v1)

**Firestore Collections:**
- `public_decks/{deckId}` - Published decks
- `public_decks/{deckId}/flashcards/{cardId}` - Public flashcards
- `public_decks/{deckId}/ratings/{userId}` - Deck ratings
- `users/{userId}/imported_decks/{importId}` - Import links (cloud sync)
- `sync_notifications/{notifId}` - Update notifications

---

## 7. Recent Changes (Last 3 Sessions)

1. **2026-01-27 16:00** - Public Library Feature Implementation
   - Added 6 new data models for public library (public_deck, deck_rating, category, etc.)
   - Modified Deck model with library linking fields (linkedPublicDeckId, isPublished)
   - Database migration v1→v2 with new columns and imported_deck_links table
   - Created 3 Firebase services (public_library, rating, sync)
   - Created PublicLibraryRepository coordinating services + local DB
   - Added 3 new providers (public_library, publish, sync)
   - Created 6 new screens (library, public_deck_detail, search, publish, manage, notifications)
   - Created 5 new widgets (public_deck_card, rating, filter_sheet, tag_input, sync_badge)
   - Updated home_screen with Library tab (now 6 tabs)
   - Updated deck_detail_screen with publish/sync options
   - Updated deck_list_screen with sync badges
   - Added flutter_rating_bar and infinite_scroll_pagination dependencies

2. **2026-01-27 14:30** - Initial project creation and documentation setup
   - Created complete Flutter project structure (51 Dart files)
   - Implemented all Phase 1-6 features from plan
   - Set up .claude documentation

---

## 8. Quick Commands
```bash
# Development
cd vocabflip
flutter run

# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Run tests
flutter test

# Generate localizations
flutter gen-l10n

# Clean build
flutter clean && flutter pub get
```

---

## 9. Environment Notes
- **Flutter SDK:** ^3.5.1
- **Gradle:** 8.4 (updated from 7.6.3 for Java 21 compatibility)
- **Android Gradle Plugin:** 8.1.0
- **Kotlin:** 1.8.22
- **Java Target:** 17

---

**NOTE TO CLAUDE CODE:**
Read this file FIRST before making any changes.
Update Section 4, 5, 7 after each session.
Create history entry with details of changes made.
