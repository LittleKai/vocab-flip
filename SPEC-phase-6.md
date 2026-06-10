# SPEC Phase 6: FSRS 4.5 Full Implementation

## Goal
Thay thế hoàn toàn thuật toán SM-2 bằng thuật toán Spaced Repetition tối ưu nhất hiện nay: FSRS v4.5.

## Context / Constraints
- Tránh làm hỏng lịch sử học (lapses, interval) của người dùng cũ.
- `SchedulerEngine` đã được tách ở Phase 1.

## Dependencies
- None.

## Files / Areas To Inspect First
- `lib/core/utils/spaced_repetition.dart`
- `lib/data/local/database/app_database.dart`

## Steps

### Step 1: Implement FSRS Math Logic
**Files to modify:** `lib/core/utils/fsrs_scheduler.dart` (Create new)
**Action:**  
- Tạo class `FSRSScheduler implements SchedulerEngine`.
- Cài đặt các công thức tính Difficulty (D), Stability (S), Retrievability (R) của chuẩn FSRS 4.5.

### Step 2: Cập nhật CardSrsState
**Files to modify:** `lib/data/models/card_srs_state.dart`
**Action:**  
- Thêm các thuộc tính `stability` (double) và `difficulty` (double) vào state nếu chưa có.

### Step 3: Migration Script cho User cũ
**Files to modify:** `lib/data/local/database/app_database.dart`
**Action:**  
- Viết logic chuyển đổi ngầm: Convert `easinessFactor` và `interval` của SM-2 sang xấp xỉ `stability` và `difficulty` của FSRS để gán vào các thẻ cũ.

## Acceptance Criteria
- Unit Test so sánh khoảng thời gian tạo ra bởi SM-2 và FSRS.
- FSRS phải lên lịch chính xác theo paper gốc.

## Builder Handoff Notes
Nên tìm một thư viện FSRS Dart (nếu có sẵn trên pub.dev) để tích hợp thay vì tự code lại toàn bộ thuật toán toán học phức tạp nhằm tránh bug logic.
