# BUILDER_LOG.md

**SPEC:** SPEC-phase-5.md
**Built by:** antigravity-claude-opus-4-6-thinking, 2026-06-13
**Status:** Complete

## Files touched

- `docs/stroke_data_sources.md` - Added documentation about animCJK data sources, fallback logic, licensing, and explicit validation that no GPL Inkstone code was copied.
- `tools/stroke_data_manifest.json` - Defined the smoke characters list required to verify the output DB integrity.
- `tools/build_stroke_data_test.dart` - Created a converter script (runnable via `flutter test`) to parse animCJK JSONL, strip extraneous JSON keys, normalize coordinates into compact arrays, compress `data_json` with ZLIB, and insert into SQLite. Reduced size from ~106MB to ~41MB.
- `lib/data/models/stroke_character.dart` - Updated JSON parsers to support both the standard key-value map format and the new compact array layout (`[pathStr, [ [x,y], ... ]]`). Updated `fromDbRow` to decode ZLIB BLOBs.
- `tools/verify_stroke_data_test.dart` - Created verification script to query `assets/stroke_data.db` against the smoke manifest and validate model parsing.
- `assets/stroke_data.db` - Replaced the fixture database with the generated, ZLIB-compressed production database containing ~16.2K kanji and kana characters.

## Summary

Implemented phase 5 by writing a dedicated Dart conversion tool that processes animCJK graphics files, extracts the necessary SVG paths and medians, heavily strips object keys into positional arrays, ZLIB compresses the string, and stores it in `assets/stroke_data.db`. The DB was reduced to ~41MB, well within the threshold compared to other existing VocabFlip assets (~66MB English dict). Wrote a verification tool that checks for schema integrity and the required smoke characters.

## Baseline verification

- Checked `assets/` size and reference source files at `D:/Dev/2.reference_pj/language-ref/animCJK` - Found them and proceeded.

## Final verification

- `flutter test tools/build_stroke_data_test.dart` - Passed (successfully built ~41MB DB)
- `flutter test tools/verify_stroke_data_test.dart` - Passed (verified smoke characters parsed correctly)
- `flutter test test/data/models/stroke_character_test.dart` - Passed (ensured model parser changes didn't break compatibility)
- `flutter analyze` - Passed (no new errors in the written files)

## Placeholder scan

- Searched `TODO|stub|mock|placeholder|NotImplemented|fake|hardcoded` in the tools and docs - Clean.

## Deviations from SPEC

- Renamed `tools/build_stroke_data.dart` and `tools/verify_stroke_data.dart` to end with `_test.dart` to allow execution via `flutter test`, since `sqflite_common_ffi` on Windows requires the `sqlite3.dll` context which `flutter test` provides natively.
- Stored the DB data as ZLIB-compressed BLOBs of compacted arrays rather than raw JSON strings. This keeps the DB size at ~41MB without dropping characters or needing complex locale-splitting workflows.

## Open questions

None.