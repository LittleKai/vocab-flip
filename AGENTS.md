# VocabFlip - Agent Router (Codex, Antigravity & Claude Code)

Flutter vocabulary app; web build duoc nhung vao Alpha Studio.

Text files are UTF-8 without BOM. In PowerShell read them with
`Get-Content -Encoding UTF8`; plain `Get-Content` under `-NoProfile` garbles
Vietnamese, and writing that text back corrupts the file.

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
- Giu nguyen package manager/lockfile (`pubspec.yaml`, `pubspec.lock`) va duong dan entrypoint/script (`lib/main.dart`, `tools/build_stroke_data.script.dart`, `tools/verify_stroke_data.script.dart`, `tools/stroke_data_manifest.json`, `.agents/skills/build-and-release/scripts/build.ps1`); file tam dat tai `.claude/scratchpad/` hoac `build/` (da gitignore), kiem hash khi di chuyen asset/data.
- Tach runtime Flutter bundled voi Python tooling: moi lenh Python/pip phai dung Anaconda env `D:\Dev\conda-envs\py310` hoac `D:\Dev\conda-envs\py312` (khong dung system Python hay conda base). `.env.example` chi ghi bien public ma client doc (`assets/config.env` nap qua `flutter_dotenv`); credential release (`GITHUB_TOKEN`, `B2_*`) chi doc tu env backend/release ben ngoai, khong dua vao client.
- Web build phai copy vao `alpha-studio/public/vocab` va duoc commit o frontend repo.

## Contract van hanh

- **Scope & ranh gioi:** repo nam long trong workspace Alpha Studio; task cua VocabFlip chi sua file trong repo nay (tru buoc copy web bundle khi release), canh bao ngoai pham vi bao rieng. Chi promote helper thuan vao `lib/_kit/` khi co >= 2 caller that (`lib/_kit/KIT.md`).
- **Bridge/IPC, manifest & bundle nhung:** giu nguyen hop dong Web SSO `postMessage` (`lib/core/web/web_sso_web.dart`, `lib/core/web/sso_message.dart`, kiem `origin` va `window.parent`), proxy CORS (`lib/data/remote/api/web_proxy_http_client.dart`) va REST/sync; phan biet manifest tinh (`tools/stroke_data_manifest.json`, B2 release manifest) voi payload API/postMessage. Build tren dia chua chung minh host dang chay ban moi — phai copy bundle/rebuild artifact va xac nhan runtime.
- **An toan du lieu, timeout & review:** validate toan bo backup truoc khi restore va giu SQLite transaction nguyen tu (`lib/data/services/sync_queue_service.dart`), chi xoa anh local thuoc app sau khi DB commit thanh cong, va giu gioi han 200MB / 3 ban release tren B2 (bo qua `-Draft`/`-Prerelease`). Khi timeout hoac `CREATE` 409 chua ro trang thai, doi chieu qua owner/session-bound `GET` va giu submission lock truoc khi gui lai thao tac ghi. Khi review doc lap qua Orca, dung dung route `orchestration` va giu receipt that.

## VERIFY - artifact Flutter release + web bundle

Artifact: Windows release/ZIP, Android APK release, web bundle nhung tai `alpha-studio/public/vocab`. Tach test/guard cau truc, runtime/native smoke va nghiem thu artifact; bang chung phai cua lan chay nay, neu khong mo duoc artifact/thiet bi thi bao ro phan chua verify.

1. Chay `flutter analyze` va `flutter test`.
2. Build platform bi tac dong; mo artifact release va smoke create/study/sync.
3. Voi web: `flutter build web`, copy sang frontend, serve production build va kiem SSO/API.
   Release VERIFY dung `flutter build web --release --base-href "/vocab/"`.
4. Task chi sua docs duoc mien build; van phai kiem path, placeholder, secret va diff.
5. Ghi lenh/exit code, pham vi da kiem va phan chua kiem, artifact, smoke va ly do skip trong bao cao task; khong dung log cu, khong sua hash de lam xanh verifier.

## Bao mat

- Khong ghi secret that vao source, test, comment, markdown hay log; chi ghi ten bien va noi luu.
- Client Flutter khong giu AI key/client secret; `assets/config.env` (copy tu `.env.example`) duoc bundle cung app nen chi chua cau hinh public.
- Khong `git add`, commit hay push trong task nang cap setup; commit web mirror khi release do chu du an thuc hien.

## Sau moi task

Cap nhat `.claude/PROJECT_SUMMARY.md`; cap nhat project tich hop neu contract/release doi.
