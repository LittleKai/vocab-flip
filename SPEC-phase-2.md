# SPEC Phase 2: Stroke Rendering and Animation

## Goal

Render unified stroke data in Flutter and animate the current stroke in order, using real SVG path parsing and median-based reveal behavior.

## Context / Constraints

- Depends on `StrokeCharacter` and `StrokeDataRepository` from Phase 1.
- The report recommends a Hanzi Writer style renderer: draw gray stroke outlines, clip to the active stroke outline, and reveal a thick round median path over time.
- `pubspec.yaml` currently does not include `path_drawing`.
- Avoid using package-level Kanji-only animation as the core solution because VocabFlip needs Japanese, Kana, Chinese Simplified/Traditional, and later validation against median points.

## Clarified Decisions / Assumptions

- Add `path_drawing: ^1.0.1` unless dependency resolution shows a newer compatible version.
- Use `CustomPainter` for the domain-specific renderer.
- `kanji_drawing_animation` and `svg_drawing_animation` are not selected for core implementation because they do not provide unified Chinese/Japanese/Kana validation surfaces.
- The painter takes normalized 1024 x 1024 stroke data and scales it into the available square canvas.

## No-Placeholder Contract

This phase must display actual parsed stroke paths and actual animation progress for fixture characters. A widget that only shows text, an empty square, or hardcoded lines is not acceptable.

## Deferred Work

- Handwriting validation is Phase 3.
- Study flow integration is Phase 4.

## Steps

### Step 1: Add path parsing dependency

- **File(s):**
  - `pubspec.yaml`
  - `pubspec.lock` after dependency resolution
- **Action:**
  - Add `path_drawing` under dependencies.
  - Run dependency resolution with Flutter tooling.
- **Verify:**
  - `flutter pub get` succeeds.
  - `rg -n "path_drawing" pubspec.yaml pubspec.lock` finds the dependency.

### Step 2: Add stroke painter

- **File(s):**
  - `lib/presentation/widgets/stroke/stroke_order_painter.dart` (new)
- **Action:**
  - Implement `StrokeOrderPainter` with inputs:
    - `StrokeCharacter character`
    - `int completedStrokeCount`
    - `double activeProgress`
    - optional user stroke overlay points
  - Parse each stroke `path` with `parseSvgPathData`.
  - Draw unrevealed outlines in muted gray.
  - Draw completed strokes in ink color.
  - For the active stroke, clip to its outline and draw the partial median polyline with a thick round stroke.
  - Draw guideline grid inside the same painter or a small companion painter.
  - Cache parsed paths at widget/controller level if profiling shows repeated parsing is expensive.
- **Verify:**
  - Widget test pumps the painter with a fixture `StrokeCharacter` and completes without exceptions.
  - A golden or smoke widget test verifies that a non-empty canvas is produced for progress `0.0`, `0.5`, and `1.0`.

### Step 3: Add animation widget

- **File(s):**
  - `lib/presentation/widgets/stroke/stroke_order_animation.dart` (new)
- **Action:**
  - Implement a `StatefulWidget` with `AnimationController`.
  - Accept `StrokeCharacter`, current stroke index, duration/speed, replay callback, and color parameters from theme.
  - Use `RepaintBoundary` around the `CustomPaint`.
  - Expose replay by resetting and forwarding the controller.
  - Ensure controller is disposed.
- **Verify:**
  - Widget test verifies animation advances `activeProgress` over time.
  - Replaying resets progress to the start and animates again.

### Step 4: Add renderer tests

- **File(s):**
  - `test/presentation/widgets/stroke/stroke_order_painter_test.dart` (new)
  - `test/presentation/widgets/stroke/stroke_order_animation_test.dart` (new)
- **Action:**
  - Test valid path parsing, invalid path handling, progress bounds, and replay.
  - Invalid path should fail gracefully by showing an error state at the widget level or by throwing in tests with a clear error, based on implementation choice.
- **Verify:**
  - `flutter test test/presentation/widgets/stroke/stroke_order_painter_test.dart test/presentation/widgets/stroke/stroke_order_animation_test.dart` passes.

## Validation Plan

- `rg -n "path_drawing|parseSvgPathData" pubspec.yaml lib test`
- `flutter test test/presentation/widgets/stroke/stroke_order_painter_test.dart test/presentation/widgets/stroke/stroke_order_animation_test.dart`
- `flutter analyze`
- Placeholder scan on new stroke widget files.

## Dependencies

- Phase 1 must be complete.

