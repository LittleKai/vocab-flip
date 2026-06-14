# Các tính năng Luyện viết còn lại

Tài liệu này chỉ liệt kê các phần quan trọng của Writing Practice vẫn chưa được triển khai hoặc chưa được áp dụng sau các phase hiện tại. Các hạng mục đã hoàn thành không được liệt kê lại. Hỗ trợ nền tảng web không nằm trong phạm vi tính năng này.

Thang điểm "mức độ nên áp dụng" dùng thang 10: `10/10` là nên làm sớm vì ảnh hưởng trực tiếp tới giá trị học tập hoặc độ hoàn chỉnh sản phẩm; `1/10` là chỉ nên làm khi có nhu cầu cụ thể.

## 1. Luyện viết từ gồm nhiều ký tự

Trạng thái: ĐÃ HOÀN THÀNH (Phase 6).

Mức độ nên áp dụng: 10/10.

Hiện tại Writing Practice đã xử lý chuỗi ký tự của `card.front`.

Phần đã hoàn thành:
- Tách `card.front` thành chuỗi grapheme/character có dữ liệu nét.
- Luyện từng ký tự theo thứ tự trong từ.
- Bỏ qua ký tự không có dữ liệu nét như dấu câu, khoảng trắng, Latin text.
- Chỉ đánh giá flashcard sau khi hoàn thành toàn bộ các ký tự được hỗ trợ.
- Hiển thị tiến trình ký tự hiện tại, ký tự đã xong, và ký tự bị bỏ qua.

## 2. Độ khó thích ứng và mức độ châm chước

Trạng thái: ĐÃ HOÀN THÀNH (Phase 7).

Mức độ nên áp dụng: 8/10.

Hiện tại `StrokeValidationService` dùng các ngưỡng cấu hình động qua `StrokeValidationOptions`.

Phần đã hoàn thành:
- Tách các ngưỡng validation thành profile rõ ràng: nhẹ, tiêu chuẩn, nghiêm ngặt.
- Cho phép người dùng đổi profile trong phiên luyện viết.
- Đảm bảo chế độ nhẹ không cho qua lỗi sai thứ tự nét hoặc sai hướng nét.
- Điều chỉnh chấm điểm theo profile nhưng không thay đổi FSRS hoặc `ReviewRating` core.
- Thêm phản hồi native nhẹ như haptic feedback trên nền tảng hỗ trợ.

## 3. Bộ so khớp nâng cao kiểu Inkstone

Trạng thái: chưa có SPEC triển khai chi tiết.

Mức độ nên áp dụng: 6/10.

Bộ validation hiện tại đã kiểm tra thứ tự nét, hướng nét, khoảng cách, độ dài và hình dạng bằng các phép đo hình học. Phần nâng cao hơn vẫn chưa được tự triển khai lại.

Phần còn lại:

- Phát hiện góc bằng thuật toán kiểu ShortStraw.
- Căn chỉnh đoạn nét bằng dynamic programming segment alignment.
- Dọn dẹp đoạn thừa, móc nét, hoặc nét kéo quá dài.
- So khớp partial/component-aware cho các trường hợp người dùng viết tắt hoặc viết theo cụm nét.
- Nhận diện sai thứ tự linh hoạt hơn nhưng vẫn giữ mục tiêu học đúng stroke order.

Lưu ý: không được copy mã từ Inkstone vì ràng buộc GPLv3. Nếu làm phần này, cần tự triển khai thuật toán bằng Dart và có test độc lập.

## 4. Phân tích chữ viết tay lưu trữ lâu dài

Trạng thái: chưa có SPEC triển khai chi tiết.

Mức độ nên áp dụng: 7/10.

Hiện tại kết quả luyện viết chỉ được quy đổi thành `ReviewRating` để đi qua luồng học hiện có. App chưa lưu lịch sử lỗi chi tiết theo ký tự hoặc theo nét.

Phần còn lại:

- Lưu lỗi sai theo từng ký tự.
- Lưu lỗi sai theo từng nét: sai hướng, sai thứ tự, quá ngắn, lệch điểm đầu/cuối, lệch hình dạng.
- Theo dõi xu hướng độ chính xác theo thời gian.
- Mở rộng review log hoặc thêm bảng analytics riêng cho handwriting.
- Thiết kế migration SQLite rõ ràng trước khi thay đổi schema.

## 5. Giao diện siêu dữ liệu KanjiVG

Trạng thái: chưa có SPEC triển khai chi tiết.

Mức độ nên áp dụng: 4/10.

Tính năng này hữu ích cho học Kanji chuyên sâu, nhưng chưa cần cho luồng luyện viết nét cơ bản.

Phần còn lại:

- Làm nổi bật bộ thủ hoặc thành phần cấu tạo.
- Hiển thị metadata như `kvg:element` và `kvg:type` khi dữ liệu nguồn hỗ trợ.
- Cho phép học hoặc ôn theo thành phần cấu tạo của ký tự.
- Kết nối metadata với UI mà không phá vỡ luồng luyện viết chung cho tiếng Trung và tiếng Nhật.

## 6. Cập nhật dữ liệu nét theo gói hoặc từ xa

Trạng thái: chưa được ưu tiên.

Mức độ nên áp dụng: 3/10.

Hiện tại dữ liệu nét được đóng gói offline trong `assets/stroke_data.db`. Đây là hướng đơn giản và ổn định nhất cho bản hiện tại.

Phần còn lại nếu sau này cần:

- Tách dữ liệu nét thành các gói theo locale hoặc cấp độ.
- Cập nhật dữ liệu nét độc lập với binary ứng dụng.
- Kiểm tra checksum/version của gói dữ liệu.
- Cache dữ liệu tải về mà không làm chậm lookup offline.

## 7. Tinh chỉnh trải nghiệm trực quan ngoài điều khiển lõi

Trạng thái: một phần được lên kế hoạch trong Phase 7, phần còn lại chưa có SPEC riêng.

Mức độ nên áp dụng: 5/10.

Luồng hiện tại đã có animation mẫu, hint, reset và feedback cơ bản. Các cải tiến sau chỉ nên làm sau khi multi-character flow và leniency ổn định.

Phần còn lại:

- Chuyển cảnh thành công/thất bại mượt hơn.
- Dựng nét bút nhạy với lực nhấn khi thiết bị hỗ trợ.
- Phản hồi âm thanh tùy chọn.
- Gợi ý nâng cao như mũi tên hướng nét, đánh số điểm bắt đầu, hoặc highlight vùng sai.
- Tối ưu bố cục cho màn hình nhỏ, text scale lớn, và chuỗi ký tự dài.
