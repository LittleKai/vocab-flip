# Instructions for Claude Code

## Before Starting ANY Task

1. **Read .claude/PROJECT_SUMMARY.md FIRST** - Contains current state, active features, known issues
2. **Check Recent Changes (Section 7)** - Avoid conflicts with recent work
3. **Review Active Features (Section 4)** - Understand what's implemented

---

## After EVERY Session

### 1. Update .claude/PROJECT_SUMMARY.md
- Update "Last Updated" timestamp
- Update Section 4 (Features) if status changed
- Update Section 5 (Issues) if new issues found/resolved
- Add entry to Section 7 (Recent Changes)

### 2. Create History Entry
Create new file: `.claude/history/YYYY-MM-DD_HH-MM.md`

Use this template:
```markdown
# Change Log: YYYY-MM-DD HH:MM

## Session Info
- **Duration:** ~X minutes
- **Request:** "[Brief description]"
- **Files Modified:** X
- **Files Created:** X

---

## Changes Made

### [Change Category]
**What changed:**
- [Description]

**Why:**
- [Reason]

**Files affected:**
- `path/to/file.dart`

---

## Testing Done
- [ ] `flutter analyze` passed
- [ ] Manual testing completed
- [ ] Relevant screens tested

---

## Notes for Next Session
- [Any important context]
```

---

## Code Change Rules

### DO
- Follow patterns in CONVENTIONS.md
- Run `flutter analyze` before finishing
- Keep changes minimal and focused
- Use existing patterns (Provider, Repository, DAO)
- Update documentation when adding features

### DON'T
- Introduce new state management (no BLoC, Riverpod)
- Modify SM-2 algorithm without explicit request
- Change database schema without migration plan
- Remove features without confirmation
- Skip error handling

---

## Quick Reference

### Project Structure
```
lib/
├── core/          # Constants, theme, utils
├── data/          # Models, DAOs, repos, APIs
├── presentation/  # Providers, screens, widgets
└── l10n/          # Localization
```

### Key Files
- `lib/app.dart` - Provider setup
- `lib/data/models/flashcard.dart` - Core model
- `lib/core/utils/spaced_repetition.dart` - SM-2 algorithm

### Common Commands
```bash
flutter analyze    # Check for issues
flutter run        # Run app
flutter test       # Run tests
flutter clean      # Clean build
```

---

## When Adding New Features

1. Create model in `data/models/`
2. Create DAO in `data/local/database/`
3. Create repository in `data/repositories/`
4. Create provider in `presentation/providers/`
5. Add provider to `app.dart` MultiProvider
6. Create screen in `presentation/screens/`
7. Update PROJECT_SUMMARY.md Section 4

---

## When Fixing Bugs

1. Identify affected files
2. Check if bug exists in PROJECT_SUMMARY.md Section 5
3. Fix and test
4. Update Section 5 if issue was listed
5. Create history entry with fix details

---

## Communication

- Be concise in responses
- Explain "why" for significant changes
- List all modified files
- Warn about breaking changes
- Ask for clarification when requirements unclear
