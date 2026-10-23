---
name: build-and-release
description: |
  Build VocabFlip cho Windows (zip), Android (apk) và Web (/vocab/), sau đó phát hành đồng thời lên
  GitHub Release (LittleKai/vocab-flip), Backblaze B2 (cập nhật trong app + link tải cho /studio/vocab),
  và copy bản Web sang alpha-studio/public/vocab.
  Trigger: khi user yêu cầu build, release, publish, xuất bản, deploy, hoặc tạo phiên bản mới cho VocabFlip.
---

# Build & Release VocabFlip

Skill này tự động hóa quy trình: build Windows + Android + Web → copy Web sang `alpha-studio/public/vocab` → tạo GitHub Release → upload artifacts → đẩy APK + Windows ZIP + `version.json` lên Backblaze B2.

## ⚠️ Ba đầu ra phát hành — đừng nhầm

| Kênh / Đích | Phục vụ | Nguồn dữ liệu |
|-------------|---------|---------------|
| **Backblaze B2** (`vocabflip-app/`) | **Cập nhật trong app** (`UpdateProvider` → `UpdateApi`) **VÀ** **Link tải trên web** (`giaiphapsangtao.com/studio/vocab` qua `GET /api/vocab/releases/latest`) | `vocabflip-app/version.json` + `vocabflip-app/releases/vocabflip-v<version>.apk` + `vocabflip-app/releases/vocabflip-windows-v<version>.zip` |
| **GitHub Release** (`LittleKai/vocab-flip`) | Lưu trữ phiên bản chính thức, git tag và release notes kèm binary trên GitHub | Tag `v<version>` + assets `.apk` và `.zip` |
| **Flutter Web Mirror** (`alpha-studio/public/vocab`) | Bản web nhúng trực tiếp tại `/vocab/` trên Alpha Studio | `flutter build web --release --base-href "/vocab/"` copy sang repo frontend `alpha-studio/public/vocab` (cần commit & push ở repo `alpha-studio` để Vercel deploy) |

- Cùng **bộ file APK + Windows ZIP** đi lên cả GitHub Release và B2 (`vocabflip-v<version>.apk`, `vocabflip-windows-v<version>.zip`).
- Bỏ bước B2 → cả trang `/studio/vocab` lẫn trình cập nhật tự động trong app (`UpdateProvider`) vẫn đọc bản cũ.
- Bỏ bước copy/commit `alpha-studio/public/vocab` → bản web nhúng trên Studio vẫn là bản cũ.
- `-Draft` / `-Prerelease` tự bỏ qua B2 stable, kể cả release có sẵn trên GitHub. Chỉ upload B2 sau khi release đã được chuyển sang bản chính thức; chạy lại `release.ps1 -SkipBuild` không kèm hai cờ này.

## Yêu cầu trước khi chạy

1. **Flutter** phải có trong PATH (`D:\3.Flutter\flutter\bin\flutter.bat`).
2. **Credential GitHub & B2** đặt trong `..\..\alpha-studio-backend\.env` (hoặc `.env.release` không được bundle):
   ```
   GITHUB_TOKEN=<github personal access token>
   B2_ACCESS_KEY_ID=<b2 keyID>
   B2_SECRET_ACCESS_KEY=<b2 applicationKey>
   B2_BUCKET_NAME=alpha-studio
   CDN_BASE_URL=https://cdn.giaiphapsangtao.com/file/alpha-studio
   ```
   > 🔴 **CẢNH BÁO BẢO MẬT**: Trong `tools/vocabflip/pubspec.yaml`, file `.env` tại root `tools/vocabflip/.env` được khai báo trong `flutter.assets` và **bị đóng gói vào mọi bản build client (APK/ZIP/Web)**. **TUYỆT ĐỐI KHÔNG** ghi `GITHUB_TOKEN` hay `B2_SECRET_ACCESS_KEY` vào `tools/vocabflip/.env`. Các script trong skill này tự động đọc từ `..\..\alpha-studio-backend\.env`.
3. **Git** working directory sạch (không có uncommitted changes).
4. Máy phải là **Windows** (build Windows native cần chạy trên Windows).

## Quy trình release

### Bước 1: Xác nhận thông tin

⚡ **Quy tắc ngầm định (Zero-Prompting):** Khi user yêu cầu build hoặc release mà **không nói gì thêm / không chỉ định cụ thể**, MẶC ĐỊNH HIỂU LÀ **build release phiên bản mới**:
- **Version**: Tự động tăng version từ `pubspec.yaml` (minor nếu có tính năng mới, patch nếu chỉ sửa lỗi).
- **Targets**: Mặc định cả ba (`windows,android,web`).
- **Loại release**: Bản chính thức (không phải prerelease).
- **Release notes**: Tự động thu thập toàn bộ thay đổi từ tag/release gần nhất đến HEAD theo góc nhìn người dùng tiếng Việt.
- **Git Push**: Tự động push cả git branch hiện tại (`git push origin <branch>`) và tag release lên GitHub.
- **Kênh phát hành**: Đẩy đồng thời cả GitHub Release, Backblaze B2 và cập nhật `alpha-studio/public/vocab`.

Nếu user có yêu cầu tùy biến riêng, hỏi hoặc làm theo yêu cầu:
- **Version**: tag mới (ví dụ `v1.2.5`). Nếu user không chỉ định, đọc version từ `pubspec.yaml` và đề xuất.
- **Release title**: tên hiển thị trên GitHub và B2 (mặc định: `VocabFlip v<version>`).
- **Release notes**: nội dung phiên bản, tổng hợp **TOÀN BỘ** các commit kể từ release trước đó (nếu cần cập nhật bắt buộc, thêm `[MANDATORY]` vào nội dung để `AppVersion.fromJson()` bật cờ `isMandatory`).

  #### Cách thu thập commit:
  1. Tìm tag release gần nhất: `rtk git tag --sort=-creatordate -n1`
  2. Lấy tất cả commits từ tag đó đến HEAD: `rtk git log <tag_trước>..HEAD --oneline`
  3. BẮT BỘC kiểm tra chi tiết nội dung thay đổi của từng commit: `rtk git log <tag_trước>..HEAD -p` hoặc `rtk git show <commit_hash>` để nắm trọn vẹn từng tính năng, sửa lỗi UI, cập nhật từ điển/bộ thẻ và trải nghiệm người dùng.
  4. Nếu có uncommitted changes (`rtk git diff`), đọc kỹ các file thay đổi để đưa vào nội dung release.
  5. Tuyệt đối KHÔNG tóm tắt qua loa hay bỏ sót các chi tiết nhỏ (như nút bấm mới, sửa bo góc dialog, tối ưu bộ từ điển/SRS, icon mới...).

  #### Cấu trúc release notes (viết bằng tiếng Việt):

  ```markdown
  ## Có gì mới trong phiên bản <version>

  ### ✨ Tính năng mới & Cải tiến
  - **Tên tính năng 1:**
    - Chi tiết cải tiến 1.1
    - Chi tiết cải tiến 1.2
  - **Tên tính năng 2:**
    - Chi tiết cải tiến 2.1

  ### 🐛 Sửa lỗi & Tinh chỉnh Giao diện
  - **Mô tả lỗi/tinh chỉnh 1:**
    - Chi tiết sửa lỗi 1.1
  ```

  #### Quy tắc viết nội dung:
  - ⚠️ **Bắt buộc**: Kiểm tra KỸ LƯỠNG và ĐẦY ĐỦ toàn bộ thay đổi trước khi soạn Release Notes.
  - Tuyệt đối **TRÁNH nhắc đến các phần kỹ thuật code**, tên file (`.dart`), tên class, function hay refactor nội bộ.
  - Chỉ mô tả dưới **góc độ trải nghiệm người dùng** nhưng phải **CHI TIẾT và PHONG PHÚ** (dùng các nhóm gạch đầu dòng con để liệt kê rõ từng điểm cải tiến).
  - Gộp các commit cùng chủ đề thành một mục chính kèm các dòng mô tả chi tiết bên dưới.
  - Nếu một section không có nội dung, **bỏ section đó đi** (không để trống).
  - Giữ đúng 3 dòng tiêu đề `##`/`###` như mẫu trên (vì `AppVersion._parseReleaseNotes` trong app tách theo `##\s+` và kiểm tra từ khóa `en`/`vi` không dấu trên dòng tiêu đề).

### Bước 2: Kiểm tra trước khi build

```powershell
# Kiểm tra git sạch
rtk git status

# Chạy flutter analyze
flutter analyze

# Chạy tests
flutter test
```

Nếu có lỗi analyze mới hoặc test fail → báo user, KHÔNG tiếp tục build.

### Bước 3: Build

Chạy script build:

```powershell
powershell -ExecutionPolicy Bypass -File ".agents\skills\build-and-release\scripts\build.ps1" -Version "<version>"
```

Script sẽ:
1. Cập nhật version trong `pubspec.yaml` (`version: <version>+<buildNumber+1>`)
2. Build Windows release: `flutter build windows --release` → nén thành `build/release/vocabflip-windows-v<version>.zip`
3. Build Android APK release: `flutter build apk --release` → copy ra `build/release/vocabflip-v<version>.apk`
4. Build Web release: `flutter build web --release --base-href "/vocab/"` → xóa bản cũ và copy sang `..\..\alpha-studio\public\vocab`

> ⚠️ **Thứ tự commit: BUILD TRƯỚC, COMMIT SAU.** Bước 1 sửa `pubspec.yaml`. `release.ps1` tạo git tag trên HEAD mà **không** tự commit thay đổi đó, nên nếu commit trước rồi mới build thì tag sẽ trỏ vào commit vẫn ghi version cũ — tag và binary lệch nhau.
>
> Trình tự đúng:
> ```powershell
> powershell -ExecutionPolicy Bypass -File ".agents\skills\build-and-release\scripts\build.ps1" -Version "<version>"
> rtk git add pubspec.yaml && rtk git commit -m "chore(release): bump version to v<version>"
> powershell -ExecutionPolicy Bypass -File ".agents\skills\build-and-release\scripts\release.ps1" -Version "<version>" -Title "<title>" -Notes "<notes>" -SkipBuild
> ```

### Bước 4: Release lên GitHub + B2

Chạy script release (một lệnh làm cả hai kênh):

```powershell
powershell -ExecutionPolicy Bypass -File ".agents\skills\build-and-release\scripts\release.ps1" -Version "<version>" -Title "<title>" -Notes "<notes>" -SkipBuild [-Prerelease] [-SkipB2]
```

Script sẽ:
1. Đọc `GITHUB_TOKEN` từ `..\..\alpha-studio-backend\.env`
2. Push branch hiện tại lên `origin`
3. Tạo git tag `v<version>` và push tag lên `origin`
4. Tạo GitHub Release qua API trên `LittleKai/vocab-flip` (hoặc cập nhật release đã có cùng tag)
5. Upload `vocabflip-v<version>.apk` và `vocabflip-windows-v<version>.zip` lên GitHub Release
6. Gọi `upload-b2.ps1` để đẩy bản tải và manifest lên B2 (bỏ qua nếu truyền `-SkipB2`)

Bước 6 upload lên bucket `alpha-studio`:
- `vocabflip-app/releases/vocabflip-v<version>.apk` — APK cho Android và web
- `vocabflip-app/releases/vocabflip-windows-v<version>.zip` — ZIP cho Windows auto-updater và web
- `vocabflip-app/version.json` — manifest cho cả `UpdateProvider` trong app và backend `GET /api/vocab/releases/latest`
- Tự động dọn các bản cũ trên B2, giữ lại 3 phiên bản mới nhất trong `vocabflip-app/releases/`.

> Nếu bước B2 fail: **GitHub Release đã publish xong rồi**, đừng tạo lại tag. Chỉ chạy lại một mình `upload-b2.ps1` (xem mục "Chạy từng bước thủ công").

### Bước 5: Xác nhận & Cập nhật tài liệu

Sau khi hoàn tất:
1. Kiểm tra nhanh manifest B2 và API backend:
   ```powershell
   # Manifest B2 đã đúng version chưa
   curl.exe -s "https://cdn.giaiphapsangtao.com/file/alpha-studio/vocabflip-app/version.json"

   # Backend đã đọc được manifest chưa
   curl.exe -s "https://alpha-studio-backend.fly.dev/api/vocab/releases/latest"
   ```
2. Cập nhật `.claude/PROJECT_SUMMARY.md` theo quy tắc của repo.
3. Nhắc (hoặc thực hiện nếu user yêu cầu) commit thư mục `public/vocab` tại repo frontend `D:\Dev\NodeJS\alpha-studio\alpha-studio` để Vercel deploy bản Web mới.
4. Hiển thị cho user:
   - Link đến GitHub Release (`https://github.com/LittleKai/vocab-flip/releases/tag/v<version>`)
   - Link tải trên CDN (`vocabflip-v<version>.apk` và `vocabflip-windows-v<version>.zip`)
   - Trang tải Studio (`https://giaiphapsangtao.com/studio/vocab`)
   - Danh sách artifacts đã upload + kích thước từng file.

## Cấu trúc output

```
build/release/
├── vocabflip-v<version>.apk           # upload lên CẢ GitHub Release và B2
└── vocabflip-windows-v<version>.zip   # upload lên CẢ GitHub Release và B2

../../alpha-studio/public/vocab/       # bản build Flutter Web (--base-href "/vocab/")
```

Trên B2 (bucket `alpha-studio`):

```
vocabflip-app/
├── version.json
└── releases/
    ├── vocabflip-v<version>.apk
    └── vocabflip-windows-v<version>.zip
```

## Lưu ý quan trọng

- **Bảo mật `.env`**: `tools/vocabflip/.env` nằm trong `pubspec.yaml` assets nên mọi biến trong đó đều lộ diện ở client. Chỉ lưu `GITHUB_TOKEN` và `B2_*` trong `alpha-studio-backend/.env` hoặc `.env.release`.
- **Tên file asset**: `AppVersion.fromJson()` và `routes/vocab.js` nhận diện Windows ZIP qua điều kiện tên chứa `windows` + kết thúc bằng `.zip`, và Android APK qua đuôi `.apk`. Giữ nguyên quy ước `vocabflip-windows-v<version>.zip` và `vocabflip-v<version>.apk`.
- **Data size**: Các từ điển SQLite (`en_vi_dict.db`, `zh_vi_dict.db`, `ja_vi_dict.db`, `chinese_dict.db`, `stroke_data.db`) được bundle vào `assets/`, nên APK và Windows ZIP khá lớn.
- **Giới hạn 200MB cho upload B2**: `upload-b2.ps1` dùng `b2_upload_file` một phần (tối đa 200MB mỗi file).
- **Tự động giữ 3 bản mới nhất trên B2**: `upload-b2.ps1` tự xóa các file `.apk`/`.zip` của phiên bản cũ hơn 3 bản gần nhất trên B2 để tiết kiệm dung lượng.

## Chạy từng bước thủ công

Nếu chỉ cần build một hoặc vài nền tảng (không release):

```powershell
powershell -ExecutionPolicy Bypass -File ".agents\skills\build-and-release\scripts\build.ps1" -Version "<version>" -Targets "windows,android,web"
```

Nếu cần release mà đã build sẵn:

```powershell
powershell -ExecutionPolicy Bypass -File ".agents\skills\build-and-release\scripts\release.ps1" -Version "<version>" -Title "<title>" -Notes "<notes>" -SkipBuild
```

Nếu chỉ cần đẩy lại bản tải lên B2 (GitHub Release đã có sẵn):

```powershell
powershell -ExecutionPolicy Bypass -File ".agents\skills\build-and-release\scripts\upload-b2.ps1" -Version "<version>" -Title "<title>" -Notes "<notes>" -ReleaseUrl "https://github.com/LittleKai/vocab-flip/releases/tag/v<version>"
```
