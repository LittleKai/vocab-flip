# SPEC Phase 3: Handwriting Input and Stroke Validation

## Goal

Capture user handwriting stroke points and validate each user stroke against the expected stroke order, direction, and shape using an original Dart implementation inspired by Hanzi Writer and Inkstone research.

## Context / Constraints

- Depends on Phase 1 stroke models and Phase 2 render widgets.
- Hanzi Writer validation concepts from `docs/report.md`:
  - dedupe user points
  - check start/end distance
  - check average distance to expected median
  - check direction by cosine similarity
  - check length ratio
  - check normalized Frechet distance
  - detect reversed stroke and likely wrong order
- Inkstone concepts may inform later segment alignment, but GPL code must not be copied.

## Clarified Decisions / Assumptions

- Implement validation in pure Dart under `lib/core/utils` or `lib/data/services`, not inside widgets.
- Pointer capture remains local to VocabFlip initially; do not depend on `signature`/`scribble` unless custom input proves insufficient.
- User input is normalized to the same 1024 x 1024 coordinate space as stroke data before validation.
- Validation v1 is strict enough for learning feedback but not a full OCR recognizer.

## No-Placeholder Contract

This phase must reject and accept real point streams using implemented geometry. Do not return canned success/failure values or rely on UI-only checks.

## Deferred Work

- Inkstone-style ShortStraw corner detection and dynamic programming segment alignment are deferred to the future-feature document unless added in a later explicit phase.
- Advanced leniency profiles by grade/learner level are deferred.

## Steps

### Step 1: Add geometry helpers

- **File(s):**
  - `lib/core/utils/stroke_geometry.dart` (new)
  - `test/core/utils/stroke_geometry_test.dart` (new)
- **Action:**
  - Implement:
    - point dedupe by distance threshold
    - polyline length
    - resample or normalize point lists
    - distance from point to segment/polyline
    - average distance to polyline
    - average cosine similarity
    - discrete Frechet distance or bounded dynamic distance
  - Keep functions deterministic and unit-testable.
- **Verify:**
  - Tests cover horizontal, vertical, diagonal, reversed, and far-away polylines.

### Step 2: Add validation service

- **File(s):**
  - `lib/data/services/stroke_validation_service.dart` (new)
  - `test/data/services/stroke_validation_service_test.dart` (new)
- **Action:**
  - Add `StrokeValidationService`.
  - Add result types:
    - `StrokeValidationResult`
    - enum/status: `accepted`, `tooShort`, `wrongStart`, `wrongEnd`, `wrongDirection`, `wrongOrder`, `inaccurate`
  - Implement `validateStroke(...)`:
    - Takes user points, `StrokeCharacter`, expected stroke index.
    - Normalizes and dedupes input.
    - Compares with expected median.
    - Checks reversed user stroke to detect wrong direction.
    - Optionally compares a limited lookahead of later strokes to flag wrong order.
    - Returns a score and reason code.
  - Make thresholds explicit constants with conservative defaults based on the report:
    - average distance threshold around 350 in 1024-space
    - start/end threshold around 250
    - minimum length ratio around 0.35
    - normalized shape threshold around 0.4
- **Verify:**
  - Tests prove:
    - correct stroke accepted
    - reversed stroke rejected as wrong direction
    - drawing stroke 2 when expected stroke 1 reports wrong order
    - short taps are rejected
    - far-away strokes are rejected

### Step 3: Add handwriting canvas widget

- **File(s):**
  - `lib/presentation/widgets/stroke/handwriting_canvas.dart` (new)
  - `test/presentation/widgets/stroke/handwriting_canvas_test.dart` (new)
- **Action:**
  - Build a square canvas using `GestureDetector` or `Listener`.
  - Capture one user stroke between pan start/update/end.
  - Normalize local coordinates into 1024 x 1024.
  - Overlay active user stroke over the `StrokeOrderPainter`.
  - Emit `onStrokeComplete(List<Offset> points)` on pan end.
  - Support clear current stroke.
- **Verify:**
  - Widget test simulates drag and receives normalized points.
  - Clearing removes user overlay.

## Validation Plan

- `flutter test test/core/utils/stroke_geometry_test.dart test/data/services/stroke_validation_service_test.dart test/presentation/widgets/stroke/handwriting_canvas_test.dart`
- `flutter analyze`
- Placeholder scan on new geometry, validation, and canvas files.

## Dependencies

- Phase 1 must be complete.
- Phase 2 must be complete.

