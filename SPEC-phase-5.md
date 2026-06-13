# SPEC Phase 5: Stroke Dataset Conversion and Expansion

## Goal

Replace the small fixture dataset with a repeatable conversion pipeline that builds `assets/stroke_data.db` from approved reference sources for Japanese Kanji/Kana and Chinese Simplified/Traditional characters.

## Context / Constraints

- Reference projects live under `D:\Dev\2.reference_pj\language-ref`.
- Preferred sources from `docs/report.md`:
  - animCJK for unified Japanese, Kana, Chinese Simplified, and Chinese Traditional coverage.
  - hanzi-writer-data/makemeahanzi as Chinese comparison/fallback source.
  - kanjivg as Japanese Kanji metadata/reference source, not primary validation data.
- Python commands must not use system Python or conda base. If Python is needed, use an explicit approved Anaconda environment per project instructions.
- Generated data must respect source licenses. License notes must be included in docs.

## Clarified Decisions / Assumptions

- The conversion tool can be Dart or Node to avoid Python environment risk. If Python is chosen, use `D:\Dev\conda-envs\python3_10` or `D:\Dev\conda-envs\py312` only after confirming with the user.
- The app consumes only `assets/stroke_data.db`; raw reference datasets are not bundled in the app.
- The converter must be deterministic and re-runnable.

## No-Placeholder Contract

This phase must produce a real `assets/stroke_data.db` from source files and verify records. Do not write a converter that only logs planned work or emits a fixed tiny DB.

## Deferred Work

- Cloud/on-demand stroke data downloads are deferred.
- Personalization based on long-term handwriting analytics is deferred.

## Steps

### Step 1: Add source audit document

- **File(s):**
  - `docs/stroke_data_sources.md` (new)
- **Action:**
  - Document source folders, file formats, locale mapping, selected license notes, and inclusion decision.
  - Explicitly state that Inkstone GPL code is not copied.
- **Verify:**
  - Document includes animCJK, hanzi-writer-data, makemeahanzi, kanjivg, and Inkstone notes.

### Step 2: Add converter tool

- **File(s):**
  - `tools/build_stroke_data.dart` (new) or `tools/build_stroke_data.js` (new)
  - `tools/stroke_data_manifest.json` (new)
- **Action:**
  - Read animCJK `graphicsJa.txt`, `graphicsJaKana.txt`, `graphicsZhHans.txt`, and `graphicsZhHant.txt`.
  - Parse JSONL records containing `character`, `strokes`, and `medians`.
  - Normalize locale names to `ja`, `ja-kana`, `zh-Hans`, `zh-Hant`.
  - Validate each record before insertion:
    - non-empty character
    - stroke count matches median count
    - path strings are non-empty
    - every median has at least two points
  - Insert into the Phase 1 `stroke_chars` schema.
  - Emit a summary: records read, records inserted, records skipped, errors by source.
- **Verify:**
  - Running the converter builds a DB with records for the smoke characters listed in the manifest.
  - Malformed records are reported and skipped without aborting the whole run unless they are in the smoke manifest.

### Step 3: Add DB verification command

- **File(s):**
  - `tools/verify_stroke_data.dart` (new) or corresponding JS file
- **Action:**
  - Open `assets/stroke_data.db`.
  - Verify schema.
  - Verify smoke characters across locales:
    - `ja:一`
    - `ja:日`
    - `ja-kana:あ`
    - `zh-Hans:一`
    - `zh-Hans:中`
    - `zh-Hant:一`
  - Verify JSON data parses through `StrokeCharacter.fromJson` if implemented in Dart; otherwise verify equivalent structure.
- **Verify:**
  - Verification command exits non-zero on missing schema, missing smoke records, invalid JSON, or stroke/median mismatch.

### Step 4: Replace fixture DB with generated DB

- **File(s):**
  - `assets/stroke_data.db`
  - `pubspec.yaml` if asset path changes
- **Action:**
  - Build the generated DB.
  - Replace the fixture DB.
  - Keep DB size acceptable for target app distribution. If too large, split by locale or create a reduced deck-driven subset.
- **Verify:**
  - App lookup still works through `StrokeDataRepository`.
  - Smoke characters render and validate in the app.

## Validation Plan

- Converter command for selected implementation language.
- Verification command for generated DB.
- `flutter test` for stroke model/repository/renderer/validation tests.
- `flutter analyze`.
- Manual smoke for Japanese Kanji, Japanese Kana, Chinese Simplified, and Chinese Traditional fixture cards.
- Placeholder scan on converter and docs.

## Dependencies

- Phase 1 should be complete before final DB replacement.
- Phases 2-4 should be complete before app-level smoke validation.

