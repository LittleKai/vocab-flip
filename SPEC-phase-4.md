# SPEC Phase 4: Advanced Study Modes

## Goal
Phát triển các chế độ ôn tập nâng cao (Multiple Choice, Type Answer, Weak Words Practice) để tránh sự nhàm chán của Classic Flip, giúp người dùng tương tác sâu hơn với từ vựng.

## Context / Constraints
- Data model `Flashcard` đã ổn định.
- Chế độ "Weak Words Practice" KHÔNG được cập nhật due date của thẻ (chỉ học nhồi).
- Phải kế thừa UI từ màn hình Study Session hiện tại.

## Dependencies
- Không có (Độc lập, có thể chạy song song).

## Files / Areas To Inspect First
- `lib/presentation/screens/study/study_screen.dart`
- `lib/presentation/widgets/flashcard/flip_card.dart`
- `lib/data/local/database/flashcard_dao.dart`

## Steps

### Step 1: Thêm Multiple Choice Mode
**Files to modify:** `lib/presentation/widgets/flashcard/multiple_choice_card.dart` (Create new)
**Action:**  
- Tạo UI hiển thị câu hỏi và 4 đáp án.
- Thuật toán random lấy 3 distractors từ các thẻ cùng `deckId`.
**Verify:** Chọn đúng đáp án thì tự động chọn rating Good, sai thì Again.

### Step 2: Thêm Type Answer Mode
**Files to modify:** `lib/presentation/widgets/flashcard/type_answer_card.dart` (Create new)
**Action:**  
- Tạo TextField cho người dùng gõ đáp án. So sánh chuỗi với `back_text` (hoặc `front_text` nếu học ngược).
**Verify:** Focus bàn phím tự động, highlight xanh/đỏ khi gõ đúng/sai.

### Step 3: Tạo luồng Weak Words Practice
**Files to modify:** `lib/presentation/screens/study/weak_words_screen.dart` (Create new)
**Action:**  
- Query `FlashcardDao` lấy thẻ có `lapses > 3`.
- Pass vào luồng Study riêng, ẩn nút lưu kết quả review để không ảnh hưởng SM-2.

## Acceptance Criteria
- Chuyển đổi mượt mà giữa các study mode.
- Multiple choice lấy đủ 4 đáp án hợp lệ.

## Builder Handoff Notes
Các widget study mode nên implement chung một abstract class hoặc interface (ví dụ `StudyCardWidget`) để dễ switch trong `study_screen.dart`.
