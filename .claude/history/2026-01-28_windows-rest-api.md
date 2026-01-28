# Session: Windows Platform Support & Localization
**Date:** 2026-01-28
**Duration:** ~60 minutes
**Focus:** Fix Windows platform crash, implement Firestore REST API, setup localization

---

## Summary
Resolved Windows platform crash caused by Firestore C++ SDK by implementing a REST API alternative. Also configured proper localization support in the app.

---

## Problem Identified
When running `flutter run -d windows`, the app would crash immediately after Firebase initialization with error:
```
Error connecting to the service protocol: failed to connect to http://127.0.0.1:xxx/
HttpException: Connection closed before full header was received
```

**Root Cause:** The `cloud_firestore` package uses a C++ SDK on Windows which is unstable and crashes when accessing Firestore.

---

## Solution Implemented

### 1. Firestore REST API Client
Created a complete REST API wrapper to bypass the native Firestore SDK on Windows.

**New File:** `lib/data/remote/firebase/firestore_rest_client.dart`

| Feature | Implementation |
|---------|----------------|
| GET document | `getDocument(collection, id)` |
| GET collection | `getCollection(path, where, orderBy, limit)` |
| Structured Query | `_runStructuredQuery()` with filters |
| CREATE document | `createDocument(path, data, documentId?)` |
| UPDATE document | `updateDocument(path, id, data)` |
| DELETE document | `deleteDocument(path, id)` |
| SET document | `setDocument(path, id, data, merge?)` |
| Batch Write | `batchWrite(operations)` |

**Helper Classes:**
- `QueryFilter` - Filter conditions (equal, greaterThan, lessThan, arrayContains)
- `OrderBy` - Sort specification
- `BatchOperation` - Set/Update/Delete operations
- `ServerTimestamp`, `FieldIncrement` - Special field values

**Platform Detection:**
```dart
static bool get shouldUseRest => !kIsWeb && Platform.isWindows;
```

### 2. Updated Services for Dual-Mode

**Modified Files:**
- `public_library_service.dart` - Added `_useRest` check and REST implementations
- `category_seeder.dart` - REST API support for seeding
- `public_deck_seeder.dart` - REST API support for seeding

**Pattern Used:**
```dart
Future<List<PublicDeck>> browse() async {
  if (_useRest) {
    return _browseRest();  // REST API
  }
  return _browseNative();  // Firestore SDK
}
```

### 3. Model Updates for REST API

**Modified Files:**
- `public_deck.dart` - Added `fromMap()` factory constructor
- `public_flashcard.dart` - Added `fromMap()` factory constructor

**Why:** REST API returns parsed `Map<String, dynamic>` instead of Firestore `DocumentSnapshot`.

### 4. Firebase Service Update

**Modified:** `firebase_service.dart`
- Added `getIdToken()` method for REST API authentication

---

## Localization Setup

### Problem
App displayed English only regardless of language setting in Settings.

### Solution
Updated `lib/app.dart` with proper localization configuration:

```dart
MaterialApp(
  locale: Locale(settings.locale),
  supportedLocales: const [
    Locale('en'),
    Locale('vi'),
  ],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  // ...
)
```

**New Import:** `flutter_localizations/flutter_localizations.dart`

---

## Supported Languages Update

**Modified:** `lib/core/constants/supported_languages.dart`

Extended language pairs to support bidirectional learning:

```dart
static const List<LanguagePair> supportedPairs = [
  // English pairs
  LanguagePair(source: SupportedLanguage.english, target: SupportedLanguage.vietnamese),
  LanguagePair(source: SupportedLanguage.english, target: SupportedLanguage.japanese),
  LanguagePair(source: SupportedLanguage.english, target: SupportedLanguage.chinese),
  // Vietnamese pairs
  LanguagePair(source: SupportedLanguage.vietnamese, target: SupportedLanguage.english),
  LanguagePair(source: SupportedLanguage.vietnamese, target: SupportedLanguage.japanese),
  LanguagePair(source: SupportedLanguage.vietnamese, target: SupportedLanguage.chinese),
  // Japanese pairs
  LanguagePair(source: SupportedLanguage.japanese, target: SupportedLanguage.vietnamese),
  LanguagePair(source: SupportedLanguage.japanese, target: SupportedLanguage.english),
  // Chinese pairs
  LanguagePair(source: SupportedLanguage.chinese, target: SupportedLanguage.vietnamese),
  LanguagePair(source: SupportedLanguage.chinese, target: SupportedLanguage.english),
];
```

---

## Create Deck Screen Update

**Modified:** `lib/presentation/screens/deck/create_deck_screen.dart`

- Target language remains fixed as Vietnamese (design decision)
- Improved UI with flags and Vietnamese names for each language
- Used `withValues(alpha: 0.1)` instead of deprecated `withOpacity()`

---

## Bug Fixes

### Structured Query Type Error
**Error:** `type '_Map<String, dynamic>' is not a subtype of type 'List<Map<String, String>>'`

**Fix:** Added explicit type annotations in `_runStructuredQuery()`:
```dart
final structuredQuery = <String, dynamic>{
  'from': <Map<String, dynamic>>[
    <String, dynamic>{'collectionId': collectionId}
  ],
};
```

---

## Files Changed

### Created (1 file)
| File | Lines | Description |
|------|-------|-------------|
| `firestore_rest_client.dart` | ~400 | Complete REST API client |

### Modified (8 files)
| File | Changes |
|------|---------|
| `app.dart` | Added localization delegates and locale |
| `firebase_service.dart` | Added `getIdToken()` method |
| `public_library_service.dart` | Added REST API implementations |
| `category_seeder.dart` | Added REST API support |
| `public_deck_seeder.dart` | Added REST API support |
| `public_deck.dart` | Added `fromMap()` constructor |
| `public_flashcard.dart` | Added `fromMap()` constructor |
| `supported_languages.dart` | Extended language pairs |
| `create_deck_screen.dart` | Fixed deprecation, improved UI |
| `main.dart` | Removed unused imports |

---

## Architecture Decision

### REST API vs Native SDK Trade-offs

| Aspect | REST API | Native SDK |
|--------|----------|------------|
| Stability | ✅ 100% stable | ❌ Crashes on Windows |
| Real-time listeners | ❌ Not supported | ✅ Supported |
| Offline persistence | ❌ Not supported | ✅ Supported |
| Code complexity | Higher (dual impl) | Lower |
| Maintenance | More work | Less work |

**Decision:** Use REST API on Windows only, keep native SDK for Android/iOS/Web for better features.

---

## Testing Notes

### Windows
```bash
flutter clean && flutter run -d windows
```
App should start successfully with REST API logs:
- `Firebase initialized successfully`
- `CategorySeeder: Categories already exist` (or seeded)
- `PublicDeckSeeder: Collection already has documents`

### Localization Test
1. Go to Settings
2. Change Language to Vietnamese
3. App UI should update to Vietnamese

---

## Next Steps
- [ ] Update remaining services (SyncService, RatingService) with REST API
- [ ] Add offline caching for Windows using local storage
- [ ] Implement real-time polling as alternative to listeners on Windows
- [ ] Update screens to use AppLocalizations.of(context) consistently
