# Các tính năng Luyện viết được hoãn lại và chưa áp dụng

Tài liệu này liệt kê các khả năng quan trọng của tính năng Luyện viết (Writing Practice) được cố ý loại bỏ khỏi tài liệu đặc tả (SPEC) triển khai ban đầu, hoặc chỉ được lên kế hoạch cho các giai đoạn sau. Tài liệu này tồn tại để đảm bảo Người xây dựng (Builder) không tự ý mở rộng phạm vi (scope creep) trong quá trình triển khai các tệp tài liệu giai đoạn (phase files).

## Ghi chú Đánh giá Gói thư viện (Package Evaluation Notes)

- `path_drawing` chỉ được khuyến nghị cho việc phân tích cú pháp (parsing) đường dẫn SVG. Nó không thay thế bộ dựng nét (renderer) hoặc bộ xác thực (validator) tự tùy chỉnh.
- `kanji_drawing_animation` không được chọn làm bộ dựng nét cốt lõi vì nó tập trung vào Kanji/KanjiVG, không hỗ trợ rộng rãi cho việc luyện tập tiếng Trung/Kana, và không xác thực nét vẽ tay.
- `svg_drawing_animation` hữu ích cho các hoạt ảnh đường nét SVG chung, nhưng VocabFlip cần dữ liệu trung vị (median) của từng nét vẽ, cắt vùng hiển thị (clipping), lớp phủ người dùng (user overlay), và tính năng xác thực.
- Các thư viện `signature`, `flutter_signature_pad`, `scribble`, và `flutter_drawing_board` không được chọn cho lớp nhập liệu (input layer) ban đầu. Chúng ghi nhận tốt việc vẽ tự do, nhưng ứng dụng cần luồng điểm vẽ (point stream) chính xác của từng nét và được chuẩn hóa về cùng một không gian tọa độ với dữ liệu nét vẽ.

## Các tính năng quan trọng chưa được áp dụng trong tài liệu đặc tả (SPEC) ban đầu

### Bộ dữ liệu nét vẽ đầy đủ cho môi trường sản phẩm (Full production stroke dataset)

Các giai đoạn ban đầu sử dụng một cơ sở dữ liệu fixture nhỏ được tích hợp sẵn để thử nghiệm hành vi của ứng dụng. Việc chuyển đổi toàn bộ dữ liệu từ animCJK/hanzi-writer-data được ấn định cho Giai đoạn 5 (Phase 5).

Lý do hoãn lại: việc chuyển đổi dữ liệu đi kèm với các rủi ro riêng về giấy phép, kích thước tệp, chất lượng và xác thực dữ liệu.

### Bộ so khớp nâng cao kiểu Inkstone (Inkstone-style advanced matcher)

Bộ xác thực ban đầu sử dụng các chỉ số đo lường kiểu Hanzi Writer: khoảng cách điểm bắt đầu/kết thúc, hướng vẽ, khoảng cách trung bình, tỷ lệ độ dài và khoảng cách hình dạng tương tự Frechet.

Chưa được áp dụng:
- Thuật toán phát hiện góc ShortStraw.
- Căn chỉnh đoạn bằng quy hoạch động (Dynamic programming segment alignment).
- Dọn dẹp các đoạn thừa/móc nét (Hook/dangling segment cleanup).
- So khớp từng phần nhận biết phím tắt/thành phần (Shortcut/component-aware partial matching).
- So khớp sai thứ tự linh hoạt hơn.

Lý do hoãn lại: Inkstone sử dụng giấy phép GPLv3, do đó không thể sao chép mã trực tiếp, và thuật toán cần phải được tự triển khai lại và kiểm thử độc lập.

### Phân tích chữ viết tay lưu trữ lâu dài (Persistent handwriting analytics)

Chưa được áp dụng:
- Lịch sử lỗi sai theo từng ký tự.
- Theo dõi các nét vẽ yếu theo từng nét.
- Xu hướng độ chính xác theo thời gian.
- Mở rộng nhật ký đánh giá (review log) cho các chỉ số dành riêng cho chữ viết tay.

Lý do hoãn lại: tính năng này yêu cầu thiết kế lại cấu trúc bảng (schema design) và có thể cần di chuyển cơ sở dữ liệu (database migrations) của ứng dụng vượt ngoài phạm vi chế độ học ban đầu.

### Độ khó thích ứng và mức độ châm chước (Adaptive difficulty and leniency)

Chưa được áp dụng:
- Các ngưỡng xác thực cho cấp độ Sơ cấp/Trung cấp/Cao cấp.
- Điều chỉnh ngưỡng động dựa trên kích thước màn hình, loại đầu vào (bút cảm ứng/ngón tay) hoặc lịch sử của người dùng.
- Cách chấm điểm khác nhau cho Kana, chữ Hán (Hanzi) đơn giản và chữ Hán (Kanji) phức tạp.

Lý do hoãn lại: bản triển khai đầu tiên cần thiết lập tính xác thực nhất quán (deterministic validation) trước khi thêm các hành vi thích ứng.

### Tải xuống dữ liệu nét vẽ hoặc các gói mô-đun (Stroke data downloads or modular packs)

Chưa được áp dụng:
- Tải xuống gói dữ liệu nét vẽ theo ngôn ngữ/vùng (locale).
- Cập nhật dữ liệu nét vẽ độc lập với mã nguồn ứng dụng (binary).
- Bộ nhớ đệm (cache) dữ liệu nét vẽ từ xa.

Lý do hoãn lại: tích hợp sẵn dữ liệu ngoại tuyến (offline) sẽ đơn giản hơn và đồng nhất với mô hình tài nguyên từ điển hiện tại của VocabFlip.

### Giao diện người dùng siêu dữ liệu KanjiVG (KanjiVG metadata UI)

Chưa được áp dụng:
- Làm nổi bật bộ thủ/thành phần cấu tạo (Radical/component highlighting).
- Hiển thị các trường `kvg:element` và `kvg:type`.
- Học theo từng thành phần cấu tạo ký tự.

Lý do hoãn lại: siêu dữ liệu KanjiVG rất hữu ích cho phương pháp giảng dạy Kanji tiếng Nhật nhưng không bắt buộc cho chu trình luyện viết chữ viết tay ban đầu.

### Từ gồm nhiều ký tự (Multi-character words)

Chưa được áp dụng:
- Luyện tập từng ký tự trong một từ gồm nhiều ký tự theo thứ tự chuỗi.
- Hoàn thành một phần của các từ ghép.
- Hiển thị nghĩa/chuyển văn bản thành giọng nói (TTS) theo từng ký tự bên trong từ ghép.

Lý do hoãn lại: ở bước đầu tiên chỉ nên luyện tập với `card.front` khi nó tương ứng với một ký tự duy nhất được hỗ trợ. Việc xử lý chuỗi ký tự dài hơn nên được thực hiện sau khi luồng xử lý ký tự đơn lẻ đã hoạt động ổn định.

### Hỗ trợ nền tảng Web (Web support)

Chưa được áp dụng:
- Cơ sở dữ liệu tài nguyên nét vẽ sử dụng SQLite trên môi trường web.
- Tinh chỉnh bút vẽ/con trỏ đặc thù cho trình duyệt.

Lý do hoãn lại: DAO từ điển ngoại tuyến hiện tại vô hiệu hóa cơ sở dữ liệu từ điển cục bộ trên nền tảng web, và cơ sở dữ liệu nét vẽ trước hết nên tuân theo các ràng buộc nền tảng hiện tại của ứng dụng.

### Tinh chỉnh hiệu ứng trực quan ngoài các điều khiển cốt lõi (Visual polish beyond core controls)

Chưa được áp dụng:
- Hoạt ảnh chuyển cảnh thành công/thất bại sinh động hơn ngoài các phản hồi cơ bản.
- Dựng nét bút vẽ nhạy cảm với lực nhấn (pressure-sensitive).
- Phản hồi xúc giác (rung).
- Phản hồi âm thanh.
- Lớp phủ gợi ý nâng cao như mũi tên hoặc đánh số điểm bắt đầu nét vẽ.

Lý do hoãn lại: đây là các cải tiến trải nghiệm người dùng (UX) rất giá trị nhưng không bắt buộc để kiểm chứng hành vi học cốt lõi.
