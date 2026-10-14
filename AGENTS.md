# VocabFlip - Agent Router (Codex, Antigravity & Claude Code)

Flutter vocabulary app; web build duoc nhung vao Alpha Studio.

## Doc theo viec

Luon doc `.claude/PROJECT_SUMMARY.md`.

| Task | Doc bat buoc |
|---|---|
| Provider, repository, SQLite, study flow | `.claude/PROJECT_SUMMARY.md` |
| Luat chi tiet cu | `.claude/PROJECT_RULES.md` |
| Truoc khi giao | `.claude/SMOKE_TEST_CHECKLIST.md` |
| Backend/SSO contract | Summary backend va frontend lien quan |

Khong doc build output, dictionary DB lon, generated web bundle hay `.claude/archive/` chi de hieu project.

## Luat bat bien

- Giu Provider; khong them BLoC/Riverpod.
- Khong doi SM-2/FSRS hoac SQLite schema neu khong co yeu cau va migration plan.
- UI text phai co ca `vi` va `en`.
- Moi lenh Python/pip cho script data phai dung env Anaconda duoc phep.
- Web build phai copy vao `alpha-studio/public/vocab` va duoc commit o frontend repo.

## VERIFY - artifact Flutter release + web bundle

1. Chay `flutter analyze` va `flutter test`.
2. Build platform bi tac dong; mo artifact release va smoke create/study/sync.
3. Voi web: `flutter build web`, copy sang frontend, serve production build va kiem SSO/API.
4. Task chi sua docs duoc mien build; van phai kiem path, placeholder, secret va diff.

## Sau moi task

Cap nhat `.claude/PROJECT_SUMMARY.md`; cap nhat project tich hop neu contract/release doi.
