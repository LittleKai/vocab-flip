# VocabFlip - Agent Router (Codex, Antigravity & Claude Code)

Flutter vocabulary app; web build duoc nhung vao Alpha Studio.

## Doc theo viec

Luon doc `.claude/PROJECT_SUMMARY.md`.

| Task | Doc bat buoc |
|---|---|
| Provider, repository, SQLite, study flow | `.claude/PROJECT_SUMMARY.md` |
| Luat chi tiet cu | `.claude/PROJECT_RULES.md` |
| Them/sua code, quy uoc | `.claude/CONVENTIONS.md` |
| Web/SQLite, batch API, anh, GIS, dialog, Windows/TTS | `.claude/IMPORTANT_FIXED_BUGS.md`: doc Bang bay, roi chi muc mang so lien quan |
| Co che + vi sao cua tinh nang | `.claude/PROJECT_SUMMARY.md`, hoac `.claude/DESIGN_DECISIONS.md` neu file nay duoc tao |
| Truoc khi giao | `.claude/SMOKE_TEST_CHECKLIST.md` |
| Backend/SSO contract | Summary backend va frontend lien quan |

Khong doc build output, dictionary DB lon, generated web bundle hay `.claude/archive/` chi de hieu project. Archive chi de biet vi sao, khong lam theo. Khong doc `.claude/scratchpad/`, skill `tmp/`, token cache, `__pycache__/`, research hay bao cao audit cu chi de hieu project.

## Luat bat bien

- Giu Provider; khong them BLoC/Riverpod.
- Khong doi SM-2/FSRS hoac SQLite schema neu khong co yeu cau va migration plan.
- UI text phai co ca `vi` va `en`.
- Moi lenh Python/pip cho script data phai dung env Anaconda duoc phep.
- Web build phai copy vao `alpha-studio/public/vocab` va duoc commit o frontend repo.

## VERIFY - artifact Flutter release + web bundle

Artifact: Windows release/ZIP, Android APK release, web bundle nhung tai `alpha-studio/public/vocab`. Bang chung phai cua lan chay nay; neu khong mo duoc artifact/thiet bi thi bao ro phan chua verify.

1. Chay `flutter analyze` va `flutter test`.
2. Build platform bi tac dong; mo artifact release va smoke create/study/sync.
3. Voi web: `flutter build web`, copy sang frontend, serve production build va kiem SSO/API.
   Release VERIFY dung `flutter build web --release --base-href "/vocab/"`.
4. Task chi sua docs duoc mien build; van phai kiem path, placeholder, secret va diff.
5. Ghi lenh/exit code, artifact, smoke va ly do skip trong bao cao task; khong dung log cu.

## Bao mat

- Khong ghi secret that vao source, test, comment, markdown hay log; chi ghi ten bien va noi luu.
- Client Flutter khong giu AI key/client secret; `.env` duoc bundle cung app nen chi chua cau hinh public.
- Khong `git add`, commit hay push trong task nang cap setup; commit web mirror khi release do chu du an thuc hien.

## Sau moi task

Cap nhat `.claude/PROJECT_SUMMARY.md`; cap nhat project tich hop neu contract/release doi.
