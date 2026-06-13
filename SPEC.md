# Writing Practice Feature SPEC Index

## Goal

Add Japanese and Chinese writing practice to VocabFlip study sessions: stroke order animation, handwriting capture, stroke validation, and FSRS-compatible rating integration.

## Context / Constraints

- Source analysis: `docs/report.md`.
- App architecture: Flutter 3.38+, Provider, local SQLite/asset databases, generated EN/VI localization.
- Existing study flow:
  - `StudyMode` lives in `lib/presentation/screens/study/study_screen.dart`.
  - `StudyProvider.rateCard(ReviewRating)` is the existing review/FSRS integration point.
  - Providers are registered in `lib/app.dart`.
- Existing asset DB pattern:
  - `lib/data/local/database/offline_dict_dao.dart` copies bundled DB assets into the app documents folder and opens them read-only.
  - Dictionary DB assets are currently declared in `pubspec.yaml`.
- Project rules:
  - Keep Provider. Do not introduce Riverpod or BLoC.
  - Do not modify FSRS/spaced repetition behavior.
  - Any visible UI copy must be localized in both English and Vietnamese.
  - Use `showStandardDialog` instead of raw `AlertDialog`.
  - Run `flutter analyze` before completing implementation work.

## Clarified Decisions / Assumptions

- Use a separate bundled stroke asset database, `assets/stroke_data.db`, instead of merging stroke data into `ja_vi_dict.db` or `zh_vi_dict.db`.
- Normalize all stroke data to a unified 1024 x 1024 Flutter coordinate space with origin at top-left and y increasing downward.
- The initial implementation must ship real behavior for a small fixture dataset. Full animCJK/hanzi-writer-data conversion is deferred to Phase 5.
- `path_drawing` is the preferred dependency for parsing SVG path data into Flutter `Path`.
- Existing study analytics and FSRS stay untouched; writing practice maps its result into `ReviewRating` and calls the existing `_rateCard(...)` path.
- Inkstone GPL code must not be copied. Only reimplement the algorithmic ideas in original Dart code.

## Package Research Summary

- `path_drawing` is recommended for SVG path parsing. It supports parsing SVG path strings into Flutter `Path` objects and is MIT licensed: https://pub.dev/packages/path_drawing
- `kanji_drawing_animation` can animate Kanji from KanjiVG, but it is Kanji-only, does not cover Chinese/Kana, and does not provide handwriting validation: https://pub.dev/packages/kanji_drawing_animation
- `svg_drawing_animation` can animate SVG line paths, but it is not tailored to stroke validation or unified animCJK/Hanzi Writer data: https://pub.dev/packages/svg_drawing_animation
- `signature`, `scribble`, `flutter_signature_pad`, and `flutter_drawing_board` can capture freehand drawing, undo, or export points/images, but none provides Chinese/Japanese stroke order validation:
  - https://pub.dev/packages/signature
  - https://pub.dev/packages/scribble
  - https://pub.dev/packages/flutter_signature_pad
  - https://pub.dev/packages/flutter_drawing_board

Recommendation: build the stroke domain logic in VocabFlip. Use `path_drawing` for SVG path parsing. Consider `signature` or `scribble` only if custom pointer capture proves too costly, but the initial SPEC keeps pointer capture local because validation needs exact per-stroke point streams and normalized coordinates.

## No-Placeholder Contract

Each phase must implement working behavior for its declared scope, not just scaffolding. Do not leave TODO-only code, empty functions/classes, `pass`, `NotImplemented`, mock returns, fake sample data, disconnected UI, uncalled services, or handlers without real integration unless listed under Deferred Work in the phase file.

## Phase Files

1. `SPEC-phase-1.md` - Stroke data model, bundled read-only DB access, repository, fixture data, and unit tests.
2. `SPEC-phase-2.md` - Stroke rendering and stroke order animation using Flutter paint APIs plus `path_drawing`.
3. `SPEC-phase-3.md` - Handwriting input capture and validation algorithm v1.
4. `SPEC-phase-4.md` - Study flow integration, Provider wiring, l10n, and rating mapping.
5. `SPEC-phase-5.md` - Data conversion/import tooling and dataset expansion.

## Validation Plan

- Preflight:
  - Confirm current files with `rg`: `StudyMode`, `StudyProvider.rateCard`, `MultiProvider`, `OfflineDictDao`, `app_en.arb`, `app_vi.arb`.
  - Confirm no existing `SPEC.md` or `SPEC-phase-*.md` needs archival before writing. If any exists in future edits, copy it to `.spec-archive/YYYY-MM-DD_HHMMSS-{filename}` before overwrite.
- Per phase:
  - Run focused unit/widget tests named in the phase file.
  - Run `flutter analyze`.
  - Run a placeholder scan on touched implementation files for `TODO`, `stub`, `mock`, `placeholder`, `NotImplemented`, empty handlers, and hardcoded fake data.
- Manual smoke after Phase 4:
  - Open a Japanese or Chinese deck with a fixture character.
  - Select Writing Practice.
  - Replay stroke animation.
  - Draw a correct stroke and an incorrect stroke.
  - Complete a character and verify the existing study queue advances through `StudyProvider.rateCard`.

## Dependencies

- Phase 2 depends on Phase 1.
- Phase 3 depends on Phases 1 and 2.
- Phase 4 depends on Phases 1, 2, and 3.
- Phase 5 can start after Phase 1, but full rollout should wait until Phase 4 behavior is usable.

