# SPEC Future Roadmap: Phase 4 to 8

Tài liệu này tập hợp tất cả các tính năng nâng cao và ý tưởng nghiên cứu còn lại từ `VOCABFLIP_DEEP_INTEGRATION_NOTES.md` đã được dời sang các phase tương lai. Các phase này có thể được bóc tách thành các file `SPEC-phase-X.md` chi tiết khi đến thời điểm triển khai.

## Phase 4: Advanced Study Modes
**Mục tiêu**: Xoá bỏ sự nhàm chán của việc chỉ lật thẻ (Classic Flip), tăng cường tương tác và ôn tập nhắm mục tiêu.
*   **Multiple Choice Mode**: Sinh 3 đáp án sai (distractors) từ các thẻ cùng bộ (Deck) hoặc cùng Tag.
*   **Type Answer Mode**: Bàn phím ảo, check chuỗi nhập vào với text mặt sau (tích hợp tính năng gõ gần đúng - fuzzy match).
*   **Weak Words Practice**: Một luồng học riêng chỉ query những thẻ có `lapses > 3` và tỷ lệ nhớ (retention) thấp. Không làm thay đổi due date của SM-2/FSRS.

## Phase 5: AI Card Generation Pipeline
**Mục tiêu**: Tự động hoá hoàn toàn việc tạo thẻ, giúp người dùng lười cũng có thẻ để học.
*   **Text/Topic to Deck**: User nhập một đoạn văn (hoặc 1 link bài báo), AI Backend (dùng MiniMax/OpenAI) sẽ tách câu, trích xuất từ vựng, tự dịch nghĩa, tìm phiên âm và gom thành 1 cục JSON schema.
*   **Draft Review Queue**: Giao diện vuốt (Tinder-like) để người dùng duyệt (Approve/Reject) các thẻ do AI sinh ra trước khi lưu chính thức vào DB.

## Phase 6: FSRS 4.5 Full Implementation
**Mục tiêu**: Chuyển đổi hoàn toàn sang thuật toán Spaced Repetition thế hệ mới.
*   Viết thuật toán tính toán ma trận DSR (Difficulty, Stability, Retrievability) của FSRS 4.5.
*   Tạo class `FSRSScheduler implements SchedulerEngine`.
*   Viết Script Migration: Map các thẻ SM-2 cũ (interval, ease) sang tham số mặc định của FSRS một cách an toàn nhất.

## Phase 7: Analytics & Heatmap Dashboard
**Mục tiêu**: Gamification và phân tích dữ liệu học tập.
*   **Study Heatmap**: Biểu đồ lưới (giống contribution của GitHub) hiển thị ở Home.
*   **Thống kê Deck**: Biểu đồ tròn tỷ lệ thẻ (New, Learning, Review, Mature).
*   **Retention Rate Tracking**: Tính toán dựa trên bảng `review_logs`.

## Phase 8: Advanced Learning Science (Nghiên cứu sâu)
**Mục tiêu**: Ứng dụng các paper khoa học mới nhất vào app.
*   **Cognitive Load / Fatigue Detection**: Theo dõi tốc độ lật thẻ và tỷ lệ sai liên tiếp. Nếu user đang "lú" (fatigue), app tự động chuyển sang thẻ dễ hoặc gợi ý nghỉ ngơi.
*   **Knowledge Graph (Semantic Review)**: Nhóm các từ vựng có liên quan ngữ nghĩa (VD: "apple", "banana") để học cùng nhau, hoặc học từ gốc trước khi học từ phái sinh.
