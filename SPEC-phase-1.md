# SPEC Phase 1: Core Data Model + Review Logs + Scheduler Abstraction

## Goal
Tách logic SM-2 hiện tại thành một `SchedulerEngine` abstraction interface để sau này dễ nâng cấp lên FSRS. Đảm bảo cấu trúc Data Model sẵn sàng lưu `CardSrsState` và `ReviewLog` tách bạch.

## Context / Constraints
- Cấm phá vỡ logic SM-2 hiện hành (chỉ refactor code).
- `spaced_repetition.dart` đang chứa logic chính.

## Dependencies
- Không.

## Files / Areas To Inspect First
- `lib/core/utils/spaced_repetition.dart`
- `lib/data/models/flashcard.dart`
- `lib/data/models/review_log.dart`

## Steps

### Step 1: Create SchedulerEngine Interface
**Files to modify:**  
- `lib/core/utils/spaced_repetition.dart` (Modify existing)

**Action:**  
- Định nghĩa `abstract class SchedulerEngine`.
- Khai báo hàm `ReviewResult review(CardSrsState state, ReviewRating rating, DateTime now);`
- Đổi SM-2 cũ thành `class SM2Scheduler implements SchedulerEngine`.

**Verify:**  
- Không bị lỗi compile. Logic cũ chạy bình thường thông qua `SM2Scheduler`.

### Step 2: Refactor Flashcard Model to use CardSrsState
**Files to modify:**  
- `lib/data/models/flashcard.dart` (Modify existing)
- `lib/data/models/card_srs_state.dart` (Create new)

**Action:**  
- Tạo model `CardSrsState` chứa các tham số: due_date, interval, ease_factor, reps, lapses.
- Cập nhật `Flashcard` để nhúng `CardSrsState`.

**Verify:**  
- Cập nhật database DAO và JSON toMap/fromMap không bị crash.

## Acceptance Criteria
- Unit tests của Spaced Repetition pass.
- App compile thành công, review thẻ cũ vẫn update next_due bình thường.

## Risks / Notes
- Rủi ro data loss nếu không xử lý DB migration cẩn thận khi refactor model `Flashcard`.

## Builder Handoff Notes
Sử dụng `flutter analyze` sau khi sửa model. Cần migrate cẩn thận trong `AppDatabase`.
