# BUILDER_LOG.md

**SPEC:** SPEC-phase-8.md
**Built by:** Antigravity Builder
**Status:** Complete

## Files touched

- `lib/data/local/preferences/app_preferences.dart` — Added `advancedLearningScience` boolean property flag.
- `lib/presentation/providers/settings_provider.dart` — Exposed `advancedLearningScience` feature flag to Settings UI.
- `lib/presentation/screens/settings/settings_screen.dart` — Added SwitchListTile for turning Advanced Learning Science on/off.
- `lib/data/services/advanced_learning_science.dart` — Created to encapsulate `applySemanticShuffle` and `checkFatigue`.
- `lib/presentation/providers/study_provider.dart` — Injected `AdvancedLearningScience`. Triggered Semantic Shuffle when pulling cards, and checked fatigue on rating submission.
- `lib/presentation/screens/study/study_screen.dart` — Added a popup dialog when fatigue is detected during rating.

## Summary

Implemented Phase 8 (Advanced Learning Science). I isolated the new experimental logic in a dedicated service class (`AdvancedLearningScience`) to avoid polluting the core study logic. The semantic shuffle spaces out cards with identical tags so they aren't reviewed back-to-back, enhancing memory separation. The cognitive load detection tracks rapid incorrect responses and presents an interruption dialog when fatigue thresholds are met. Both features are guarded by an "Advanced Learning Science" feature flag.

## Deviations from SPEC

Rather than creating `study_session_manager.dart` and `study_service.dart`, I created one unified `advanced_learning_science.dart` and wired it straight into the existing `StudyProvider` and `StudyScreen`. This was much less intrusive to the codebase structure.

## Open questions

None. The feature flag gives users and testers total control.
