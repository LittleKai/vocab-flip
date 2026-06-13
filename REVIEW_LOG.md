# REVIEW_LOG.md

**Reviewed:** SPEC-phase-1.md
**Reviewed by:** Codex, 2026-06-13 17:44 +07:00
**Status:** Approved with commit-scope caution

## Scope

- Compared `SPEC.md`, `SPEC-phase-1.md`, `BUILDER_LOG.md`, project instructions, CodeGraph context, git status/diff, and the Phase 1 implementation.
- Reviewed:
  - `lib/data/models/stroke_character.dart`
  - `lib/data/local/database/stroke_data_dao.dart`
  - `lib/data/repositories/stroke_data_repository.dart`
  - `assets/stroke_data.db`
  - `pubspec.yaml`
  - `test/data/models/stroke_character_test.dart`
  - `test/data/repositories/stroke_data_repository_test.dart`

## Findings

- No blocking implementation defects found in the Phase 1 data model, DAO, repository fallback logic, or bundled fixture database.
- Commit-scope caution: `.gitignore` ignores `test/`, so the two Phase 1 test files are currently ignored by git and will not be included by a normal `git add .`. Force-add them or adjust `.gitignore` before committing Phase 1.
- `pubspec.yaml` contains an unrelated `cached_network_image` dependency diff that is not part of SPEC Phase 1. Exclude it from the Phase 1 commit unless it belongs to another intentional change.

## Inline Fixes

- Fixed one Phase 1 test lint by making the fixture `StrokeData` constructor const and removing nested redundant const.

## Verification

- `flutter test test/data/models/stroke_character_test.dart test/data/repositories/stroke_data_repository_test.dart` passed: 33/33.
- `flutter analyze lib/data/models/stroke_character.dart lib/data/local/database/stroke_data_dao.dart lib/data/repositories/stroke_data_repository.dart test/data/models/stroke_character_test.dart test/data/repositories/stroke_data_repository_test.dart` passed with no issues.
- `sqlite3 assets/stroke_data.db` confirmed `stroke_chars` schema, lookup index, and 4 fixture records: `ja:一`, `ja:日`, `zh-Hans:一`, `zh-Hans:中`.
- Full `flutter analyze` still fails with 207 existing project-wide issues outside Phase 1.

---

**Reviewed:** SPEC-phase-2.md and SPEC-phase-3.md
**Reviewed by:** Codex, 2026-06-13 19:12 +07:00
**Status:** Approved with commit-scope caution

## Scope

- Compared `SPEC.md`, `SPEC-phase-2.md`, `SPEC-phase-3.md`, `BUILDER_LOG.md`, project instructions, CodeGraph context, git status/diff, and the Phase 2/3 implementation.
- Reviewed:
  - `lib/presentation/widgets/stroke/stroke_order_painter.dart`
  - `lib/presentation/widgets/stroke/stroke_order_animation.dart`
  - `lib/presentation/widgets/stroke/handwriting_canvas.dart`
  - `lib/core/utils/stroke_geometry.dart`
  - `lib/data/services/stroke_validation_service.dart`
  - Phase 2/3 focused tests under `test/presentation/widgets/stroke`, `test/core/utils`, and `test/data/services`

## Findings

- No blocking implementation defects found in Phase 2 rendering/animation or Phase 3 handwriting capture/validation.
- Commit-scope caution: `.gitignore` ignores `test/`, so Phase 2/3 tests are ignored by git and will not be included by a normal `git add .`. Force-add them or adjust `.gitignore` before committing.
- Process caution: `BUILDER_LOG.md` currently records Phase 3 only. The Phase 2 implementation exists and was reviewed from source/SPEC, but the Phase 2 builder log was overwritten or not retained.
- `pubspec.yaml` / `pubspec.lock` still include unrelated `cached_network_image` dependency changes. Exclude them from a Writing Practice Phase 2/3 commit unless intentional for a separate change.

## Inline Fixes

- Fixed two unnecessary imports in Phase 3 tests.
- Fixed `StrokeOrderPainter.shouldRepaint` so guideline and user-stroke color changes repaint correctly.
- Added a focused test for repaint behavior when overlay colors change.

## Verification

- `flutter test test/presentation/widgets/stroke/stroke_order_painter_test.dart test/presentation/widgets/stroke/stroke_order_animation_test.dart test/core/utils/stroke_geometry_test.dart test/data/services/stroke_validation_service_test.dart test/presentation/widgets/stroke/handwriting_canvas_test.dart` passed: 61/61.
- Focused `flutter analyze` on Phase 2/3 implementation files and tests passed with no issues.
- Placeholder scan on Phase 2/3 implementation files found no matches.
- `rg -n "path_drawing|parseSvgPathData" pubspec.yaml pubspec.lock lib test` confirmed dependency and usage.
- Full `flutter analyze` still fails with 206 existing project-wide issues outside Phase 2/3.

---

**Reviewed:** SPEC-phase-4.md and SPEC-phase-5.md
**Reviewed by:** Codex, 2026-06-13 21:14 +07:00
**Status:** Approved with cautions

## Scope

- Compared `SPEC.md`, `SPEC-phase-4.md`, `SPEC-phase-5.md`, `BUILDER_LOG.md`, project instructions, CodeGraph context, git status/diff, and the Phase 4/5 implementation.
- Reviewed:
  - `lib/app.dart`
  - `lib/presentation/screens/study/study_screen.dart`
  - `lib/presentation/providers/stroke_practice_provider.dart`
  - `lib/presentation/widgets/flashcard/writing_practice_card.dart`
  - `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, and generated localizations
  - `lib/data/local/database/stroke_data_dao.dart`
  - `lib/data/models/stroke_character.dart`
  - `docs/stroke_data_sources.md`
  - `tools/build_stroke_data_test.dart`
  - `tools/verify_stroke_data_test.dart`
  - `tools/stroke_data_manifest.json`
  - Phase 4 focused tests

## Findings

- Blocking app defect fixed during review: Phase 5 changed `data_json` to a ZLIB BLOB, but `StrokeDataDao.lookup()` still cast it to `String` and decoded raw JSON. This would make production app lookup fail for the generated database.
- Process caution: `BUILDER_LOG.md` currently records Phase 5 only. Phase 4 implementation exists and was reviewed from source/SPEC, but the Phase 4 builder log was overwritten or not retained.
- Phase 5 converter/verify files are named `_test.dart` and the build test deletes and rewrites `assets/stroke_data.db`. Do not include `tools/build_stroke_data_test.dart` in routine full test runs unless regenerating the DB is intentional.
- Phase 5 generated DB schema deviates from the Phase 1 schema in the SPEC: it stores compact ZLIB BLOB rows and omits columns like `source`, `stroke_count`, `view_box`, and `updated_at`. Runtime lookup now supports it, but this is a documented schema deviation to preserve DB size.
- Existing installed apps with an already-copied old `stroke_data.db` may not receive the new generated asset because `StrokeDataDao.init()` only copies the asset when the app-documents DB is missing.
- `cached_network_image` remains an unrelated dependency diff in `pubspec.yaml` / `pubspec.lock`.

## Inline Fixes

- Updated `StrokeDataDao.lookup()` to select `character`, `locale`, and `data_json`, then parse via `StrokeCharacter.fromDbRow()` so both legacy JSON strings and compressed BLOB rows work.
- Fixed focused lints in Phase 4/5 files and tests.
- Replaced remaining `withOpacity` calls in `study_screen.dart` with `withValues(alpha: ...)`.
- Updated `.gitignore` so Phase 5 `tools/build_stroke_data_test.dart`, `tools/verify_stroke_data_test.dart`, and `tools/stroke_data_manifest.json` are no longer ignored.

## Verification

- `flutter test test/presentation/providers/stroke_practice_provider_test.dart test/presentation/widgets/flashcard/writing_practice_card_test.dart test/data/models/stroke_character_test.dart test/data/repositories/stroke_data_repository_test.dart tools/verify_stroke_data_test.dart` passed: 41/41.
- Focused `flutter analyze` on Phase 4/5 implementation files, tools, and tests passed with no issues.
- Placeholder scan on Phase 4/5 implementation/tool/doc files found no matches.
- Full `flutter analyze` still fails with 201 existing project-wide issues outside Phase 4/5.
