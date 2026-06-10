# SPEC Phase 8: Advanced Learning Science

## Goal
Áp dụng các công trình nghiên cứu giáo dục mới nhất (nhận diện mệt mỏi - Fatigue và vòng lặp ngữ nghĩa - Semantic Review) để tối ưu hóa não bộ người dùng.

## Context / Constraints
- Rất phức tạp, mang tính chất R&D (nghiên cứu).
- Cần ma trận dữ liệu của FSRS làm nền tảng.

## Dependencies
- Phase 6 (Bắt buộc phải có FSRS).

## Files / Areas To Inspect First
- `lib/core/utils/fsrs_scheduler.dart`
- `lib/data/services/study_service.dart`

## Steps

### Step 1: Cognitive Load Detection (Fatigue)
**Files to modify:** `lib/data/services/study_session_manager.dart` (Create new)
**Action:**  
- Bắt sự kiện: Lấy mốc thời gian answer thẻ (tốc độ).
- Nếu user trả lời sai liên tiếp > 5 thẻ và tốc độ dưới 1s (spam phím), kích hoạt cảnh báo Fatigue: Giảm số lượng thẻ khó xuất hiện, hoặc gợi ý popup nghỉ ngơi 5 phút.

### Step 2: Semantic Review (Knowledge Graph Tối giản)
**Files to modify:** `lib/data/services/study_service.dart`
**Action:**  
- Nhóm các thẻ có cùng Tag lại với nhau khi sắp xếp thẻ sẽ xuất hiện trong ngày.
- Đảo thứ tự sao cho các từ đồng nghĩa/trái nghĩa hoặc chung chủ đề không xuất hiện liên tiếp nhau ngay lập tức để tránh nhầm lẫn.

## Acceptance Criteria
- App có khả năng can thiệp khi user có dấu hiệu học vẹt hoặc mệt.

## Builder Handoff Notes
Tính năng này nên có cờ (Feature Flag) trong Settings để người dùng có thể bật tắt, vì không phải ai cũng thích app tự ý can thiệp vào tiến trình học.
