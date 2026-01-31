# Change Log: 2026-01-31 Chinese-Vietnamese Dictionary

## Session Info
- **Duration:** ~30 minutes
- **Request:** "Integrate Chinese-Vietnamese dictionary for the dictionary tab"
- **Files Modified:** 2
- **Files Created:** 1

---

## Changes Made

### Chinese-Vietnamese Dictionary Integration
**What changed:**
- Created HanziiApi class for Chinese → Vietnamese translation
- Uses same Mazii backend but with `dict: 'hanzivi'` parameter
- Integrated into DictionaryRepository for all lookup methods

**Why:**
- User requested Chinese dictionary support for the dictionary tab
- Mazii API supports Chinese-Vietnamese via same endpoint with different dict parameter

**Files affected:**
- `lib/data/remote/api/hanzii_api.dart` (NEW)
- `lib/core/constants/api_endpoints.dart` (added Hanzii endpoints)
- `lib/data/repositories/dictionary_repository.dart` (added HanziiApi integration)

---

## Implementation Details

### HanziiApi Structure
- Mirrors MaziiApi structure for consistency
- Classes: `HanziiApi`, `HanziiResult`, `HanziiMeaning`, `HanziiExample`
- Methods: `lookup()`, `lookupWithFilter()`, `search()`, `getWordDetail()`
- Converts to generic `DictionaryResult` via `toDictionaryResult()`

### DictionaryRepository Changes
- Added `_hanziiApi` field and constructor parameter
- Updated `lookupAll()` - Chinese case now uses HanziiApi
- Updated `search()` - Added Chinese case
- Updated `lookupVietnamese()` - Added Chinese case

### API Endpoints Added
```dart
static const String hanziiSearch = 'https://mazii.net/api/search';
static const String hanziiBase = 'https://mazii.net/api/search';
static String hanzii(String word, {int limit = 10, int page = 1}) =>
    '$hanziiBase/${Uri.encodeComponent(word)}/$limit/$page';
static const String hanziiDetailBase = 'https://mazii.net/api/hanzivi';
static String hanziiDetail(int mobileId) => '$hanziiDetailBase/$mobileId';
```

---

## Testing Done
- [x] `flutter analyze` passed (no issues)
- [ ] Manual testing - Chinese word lookup
- [ ] Dictionary tab with Chinese source language

---

## Notes for Next Session
- Test Chinese dictionary with actual Chinese words
- Verify pinyin (phonetic) extraction works correctly
- May need to add Chinese-English fallback dictionary in future
