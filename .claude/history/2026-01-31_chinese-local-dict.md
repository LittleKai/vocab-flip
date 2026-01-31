# Change Log: 2026-01-31 Chinese-Vietnamese Local Dictionary

## Session Info
- **Duration:** ~45 minutes
- **Request:** "Integrate Chinese-Vietnamese dictionary using local database from LacViet.txt"
- **Files Modified:** 5
- **Files Created:** 4

---

## Changes Made

### 1. Created Build Tool for Chinese Dictionary
**What changed:**
- Created `tools/build_chinese_dict.dart` to parse LacViet.txt and build SQLite database
- Parses word, pinyin (multiple pronunciations), Hán Việt, and definitions
- Renumbers definitions sequentially across multiple pronunciation sections
- Handles inline definitions after "Hán Việt: X" patterns

**Why:**
- Mazii API returned Japanese results for Chinese words (wrong dict parameter)
- Local database provides reliable, fast, offline access
- LacViet dictionary has 66,447 high-quality Chinese-Vietnamese entries

**Files affected:**
- `tools/build_chinese_dict.dart` (NEW)
- `tools/test_chinese_dict.dart` (NEW - for testing)
- `assets/chinese_dict.db` (NEW - 7.9MB, 66K+ entries)

### 2. Created Chinese Dictionary DAO
**What changed:**
- Created `ChineseDictDao` singleton for database access
- Auto-copies database from assets to documents on first launch
- Supports exact match, prefix match, and contains search
- Supports search by pinyin

**Files affected:**
- `lib/data/local/database/chinese_dict_dao.dart` (NEW)

### 3. Rewrote HanziiApi to Use Local Database
**What changed:**
- Changed from Mazii API to local SQLite database
- Removed HTTP client dependency
- Simplified result parsing
- Fixed UI display: keep all definitions in single meaning for proper numbering

**Why:**
- API wasn't working correctly (returning Japanese instead of Chinese)
- Local database is faster and works offline

**Files affected:**
- `lib/data/remote/api/hanzii_api.dart` (REWRITTEN)

### 4. Updated App Initialization
**What changed:**
- Added Chinese dictionary initialization in main.dart
- Database loads asynchronously on app start

**Files affected:**
- `lib/main.dart`

### 5. Updated Dependencies
**What changed:**
- Added `sqlite3: ^3.1.4` as dev dependency (for build tool)
- Added `assets/chinese_dict.db` to pubspec.yaml assets

**Files affected:**
- `pubspec.yaml`

---

## Data Format

### LacViet.txt Format
```
阿哥=✚[āgē] \n\t1. đại ca; anh; huynh\n\t2. con trai...
啊=✚[ā] Hán Việt: A a; chà; à\n✚[á] Hán Việt: A hả; há...\n✚[à] \n\t1. ừ; ờ...
```

### Database Schema
```sql
CREATE TABLE words (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  word TEXT NOT NULL,
  pinyin TEXT,
  han_viet TEXT,
  definition TEXT NOT NULL
);
CREATE INDEX idx_word ON words(word);
CREATE INDEX idx_pinyin ON words(pinyin);
```

### Parsed Result Example
```
Word: 啊
Pinyin: ā, á, ǎ, à, ·a
Definition:
1. a; chà; à
2. hả; há (thán từ, hỏi dồn)
3. ủa; hả (thán từ, tỏ ý kinh ngạc, khó hiểu)
...
11. này; nào (dùng sau những cái được liệt kê)
```

---

## Commands

### Build/Rebuild Dictionary
```bash
dart run tools/build_chinese_dict.dart "path/to/LacViet.txt"
```

### Test Dictionary
```bash
dart run tools/test_chinese_dict.dart
```

---

## Testing Done
- [x] Build tool parses 66,447 entries successfully
- [x] Database queries work correctly
- [x] Definition numbering is sequential (1, 2, 3... not 1, 1, 1...)
- [x] Multiple pronunciations merged correctly
- [x] App loads dictionary on startup
- [ ] Full UI testing in Dictionary tab

---

## Notes for Next Session
- Set `forceUpdate = false` in `chinese_dict_dao.dart` after confirming database works
- Consider adding version check for database updates
- May want to add search by Hán Việt in future
