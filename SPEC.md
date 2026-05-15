# Goal
Tích hợp ứng dụng Flutter `vocabflip` vào hệ sinh thái của `alpha-studio`. Thay thế hệ thống xác thực và lưu trữ hiện tại bằng API của Alpha Studio, tích hợp hệ thống tín dụng (credit), sử dụng Backblaze B2 để lưu trữ hình ảnh cho thư viện (Tab Library), và chuẩn bị project để có thể nhúng vào web frontend của Alpha Studio thông qua iframe.

# Context
**Backend Target**: `alpha-studio-backend` (Node.js/Express + MongoDB)
**Project hiện tại**: `vocabflip` (Flutter)
**Dependencies cần thiết/cập nhật**:
- `dio` hoặc `http` (gọi REST API của Alpha Studio)
- `flutter_secure_storage` (lưu trữ JWT Token an toàn)
- Đối với Web (tích hợp Iframe): cần thư viện JS interop cơ bản (từ `dart:html` hoặc package `web`) để lắng nghe `window.postMessage`.

**Quy tắc dự án (từ CLAUDE.md)**:
- Simplicity First: Viết code ngắn gọn, không thêm abstraction thừa.
- No new state management: Giữ nguyên Provider (không dùng BLoC, Riverpod nếu chưa có).
- Cấu trúc: `lib/core/`, `lib/data/`, `lib/presentation/`.

# Steps

## Giai đoạn 1: Tích hợp hệ thống Tài khoản & Credit (Auth & Wallet)
1. **Thiết lập API Client**: Tách API client (Dio/Http) trong `lib/data/api/`, cấu hình Interceptor đính kèm `Authorization: Bearer <JWT_TOKEN>`.
2. **Cập nhật AuthRepository**:
   - Thay thế Auth hiện tại (Firebase/Local) bằng việc gọi API:
     - `POST /api/auth/login` (nhận JWT token).
     - `POST /api/auth/register`.
     - `GET /api/auth/me` (nhận profile và `balance` đại diện cho credit).
   - Lưu trữ JWT token bằng `flutter_secure_storage`.
   - **Xác thực**: Có thể đăng nhập và hiển thị thông tin trả về thành công.
3. **Hiển thị Credit & Xử lý nạp**:
   - Thêm trạng thái `balance` vào Auth Provider.
   - Hiển thị số dư Credit (Icon xu/coin) ở Header/Profile của app.
   - Thêm nút "Nạp Credit" chuyển hướng (mở browser) sang link Nạp Credit của `alpha-studio` web.

## Giai đoạn 2: Tích hợp Lưu trữ Backblaze B2 cho Tab Library
1. **Quy trình Upload Ảnh B2**:
   - Bỏ việc lưu trữ hình ảnh/dữ liệu vào ổ cứng/firebase storage cho Tab Library.
   - Viết hàm `uploadImageToB2(File/Bytes)`:
     - Gọi `POST /api/upload/presign` (API của Alpha Studio) lấy `uploadUrl`.
     - Thực hiện HTTP `PUT` đưa raw bytes của file lên `uploadUrl`.
     - Trả về B2 file URL/Key.
2. **Cập nhật dữ liệu Flashcard/Thư viện**:
   - Sửa đổi DAO/Repository phụ trách lưu ảnh của Tab Library. Mỗi khi người dùng chọn ảnh mới, gọi `uploadImageToB2`.
   - Lưu URL trả về từ B2 vào database (qua API Backend hoặc local tuỳ thuộc vào quyết định database chung).
   - **Xác thực**: Chọn ảnh từ máy -> upload thành công -> ảnh render trên app qua URL B2 mới.

## Giai đoạn 3: Chuẩn bị Web Integration (Nhúng vào Alpha Studio Web)
1. **Tích hợp Web Interop (Cross-origin SSO)**:
   - Trong `main.dart` hoặc init logic, thêm listener cho `window.postMessage` (dùng thư viện `web` hoặc `dart:html` với conditional import để tránh lỗi trên Mobile).
   - Bắt event chứa Auth Token được gửi từ Iframe cha (trang web Alpha Studio).
   - Nếu nhận được Token -> Lưu vào secure storage -> Tự động load `GET /api/auth/me` để đăng nhập mà không cần nhập mật khẩu.
2. **Build và Test Web**:
   - Chạy lệnh `flutter build web`.
   - **Xác thực**: Mô phỏng gửi postMessage từ console trình duyệt vào iframe chứa app, app phải tự động đăng nhập.
