# SPEC Phase 1: Stroke Data Storage and Repository

## Goal

Add a real offline stroke data layer for Writing Practice, backed by a bundled read-only SQLite asset database and a small fixture dataset that can be queried by character and locale.

## Context / Constraints

- Existing read-only asset DB copy/open pattern is in `lib/data/local/database/offline_dict_dao.dart`.
- Existing app user DB is in `lib/data/local/database/app_database.dart`; do not modify it for this phase.
- Current stroke data source recommendation comes from `docs/report.md`: unified data from animCJK plus hanzi-writer-data/makemeahanzi, stored separately from dictionary DBs.
- `pubspec.yaml` currently declares dictionary DB assets but not `assets/stroke_data.db`.
- This phase must not add UI or study mode behavior.

## Clarified Decisions / Assumptions

- Create a new asset DB `assets/stroke_data.db` with table:

```sql
CREATE TABLE stroke_chars (
  id TEXT PRIMARY KEY,
  character TEXT NOT NULL,
  locale TEXT NOT NULL,
  source TEXT NOT NULL,
  stroke_count INTEGER NOT NULL,
  view_box TEXT NOT NULL,
  data_json TEXT NOT NULL,
  updated_at TEXT
);
CREATE INDEX idx_stroke_chars_lookup ON stroke_chars(character, locale);
```

- `data_json` uses the unified JSON shape:

```json
{
  "character": "sample",
  "locale": "ja",
  "source": "fixture",
  "viewBox": [0, 0, 1024, 1024],
  "strokes": [
    {
      "index": 0,
      "path": "M 100 100 L 900 100 L 900 220 L 100 220 Z",
      "median": [[100, 160], [900, 160]],
      "type": null,
      "component": null
    }
  ]
}
```

- Fixture DB must contain at least these records if licensing allows local fixture use: `ja:一`, `ja:日`, `zh-Hans:一`, `zh-Hans:中`. If real source data cannot be embedded safely during implementation, use hand-authored geometric fixture records only in tests and document that production source import is Phase 5.

## No-Placeholder Contract

This phase must implement working data access. Do not create only empty models, empty DAO methods, or a repository that returns hardcoded data from app code. Fixture data may exist in the bundled test/asset DB only, not as fake repository returns.

## Deferred Work

- Full animCJK/hanzi-writer-data conversion is deferred to Phase 5.
- UI rendering and study flow are deferred to later phases.

## Steps

### Step 1: Add stroke data models

- **File(s):**
  - `lib/data/models/stroke_character.dart` (new)
- **Action:**
  - Add immutable Dart models:
    - `StrokeCharacter`
    - `StrokeData`
    - `StrokePoint` or use `Offset` where appropriate outside pure data parsing.
  - Implement `fromJson(Map<String, dynamic>)` and `toJson()` for unified JSON.
  - Validate required fields, stroke order indexes, non-empty `path`, and median points with at least two points.
  - Keep model parsing independent from Flutter widgets where practical. If using `Offset`, keep the dependency limited to `dart:ui`.
- **Verify:**
  - A unit test can parse a fixture JSON record and read character, locale, source, viewBox, stroke count, path, and median points.
  - Invalid JSON with no strokes or a one-point median throws a clear `FormatException`.

### Step 2: Add read-only stroke DB DAO

- **File(s):**
  - `lib/data/local/database/stroke_data_dao.dart` (new)
  - `assets/stroke_data.db` (new generated/bundled fixture DB)
  - `pubspec.yaml`
- **Action:**
  - Implement `StrokeDataDao` using the same platform behavior as `OfflineDictDao`:
    - Return no records on web if local SQLite asset DB is not supported.
    - Use `sqflite_common_ffi` on desktop platforms.
    - Copy `assets/stroke_data.db` into the app documents `vocabflip` directory if missing.
    - Open copied DB read-only.
  - Add methods:
    - `Future<void> init()`
    - `Future<StrokeCharacter?> lookup({required String character, required String locale})`
    - `Future<bool> exists({required String character, required String locale})`
    - `Future<void> close()`
  - Declare `assets/stroke_data.db` in `pubspec.yaml`.
- **Verify:**
  - DAO lookup returns the expected fixture character from a copied read-only DB.
  - DAO returns `null` for missing character/locale.
  - DAO does not touch `AppDatabase` migrations.

### Step 3: Add repository and locale fallback logic

- **File(s):**
  - `lib/data/repositories/stroke_data_repository.dart` (new)
- **Action:**
  - Add `StrokeDataRepository` wrapping `StrokeDataDao`.
  - Add `lookupCharacter(String character, String sourceLanguage)` with locale fallback:
    - `ja` -> `ja`, then `ja-kana` when applicable.
    - `zh` -> `zh-Hans`, then `zh-Hant`.
    - Non-Japanese/Chinese languages return `null`.
  - Add `hasStrokeData(String character, String sourceLanguage)`.
- **Verify:**
  - Unit tests prove Japanese and Chinese fallback order.
  - English/Vietnamese source language returns `null` without opening unnecessary DB work where possible.

### Step 4: Add focused tests

- **File(s):**
  - `test/data/models/stroke_character_test.dart` (new)
  - `test/data/repositories/stroke_data_repository_test.dart` (new)
- **Action:**
  - Cover JSON parsing, malformed data, successful repository lookup, missing lookup, and locale fallback.
  - If direct SQLite fixture testing is too slow, keep DAO tests focused and repository tests dependency-inject a fake DAO interface. Do not fake the production repository return path.
- **Verify:**
  - `flutter test test/data/models/stroke_character_test.dart test/data/repositories/stroke_data_repository_test.dart` passes.

## Validation Plan

- `rg -n "class OfflineDictDao|openDatabase|rootBundle.load" lib/data/local/database`
- `rg -n "assets:" pubspec.yaml`
- `flutter test test/data/models/stroke_character_test.dart test/data/repositories/stroke_data_repository_test.dart`
- `flutter analyze`
- Placeholder scan on new implementation files:
  - `rg -n "TODO|stub|mock|placeholder|NotImplemented|fake" lib/data/models/stroke_character.dart lib/data/local/database/stroke_data_dao.dart lib/data/repositories/stroke_data_repository.dart`

## Dependencies

None.

