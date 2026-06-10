# SPEC Phase 7: Analytics & Heatmap Dashboard

## Goal
Xây dựng màn hình thống kê (Gamification) để tạo động lực cho người dùng, bao gồm Heatmap học tập và biểu đồ tỷ lệ.

## Context / Constraints
- Chỉ thao tác thao tác Read-Only (đọc dữ liệu) từ SQLite.
- Thư viện UI biểu đồ: Có thể dùng `fl_chart`.

## Dependencies
- None.

## Files / Areas To Inspect First
- `lib/presentation/screens/stats/statistics_screen.dart` (Modify existing)
- `pubspec.yaml`

## Steps

### Step 1: Tích hợp thư viện Chart
**Files to modify:** `pubspec.yaml`
**Action:**  
- Thêm package `fl_chart` hoặc tương tự.

### Step 2: Vẽ Study Heatmap (GitHub Contribution Style)
**Files to modify:** `lib/presentation/widgets/stats/study_heatmap.dart` (Create new)
**Action:**  
- Lấy dữ liệu từ bảng `study_sessions` hoặc `review_logs` gom nhóm theo ngày.
- Tô màu xanh đậm nhạt tương ứng với số lượng thẻ đã học trong ngày.

### Step 3: Biểu đồ Deck Breakdown
**Files to modify:** `lib/presentation/widgets/stats/deck_pie_chart.dart` (Create new)
**Action:**  
- Lấy `FlashcardDao`. Vẽ Pie Chart phân loại thẻ: New (reps=0), Learning, Mature (interval > 21).

## Acceptance Criteria
- Giao diện mượt mà, không bị giật lag khi query lượng data lớn.

## Builder Handoff Notes
Nên tính toán và gom nhóm (Group By) dữ liệu ngay tại SQLite Query thay vì load toàn bộ list vào bộ nhớ Dart rồi mới filter.
