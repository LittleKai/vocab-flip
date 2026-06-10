# SPEC Phase 3: Sync Service & Offline-first Hardening

## Goal
Xây dựng cơ chế hàng đợi đồng bộ (Sync Queue) và xử lý Conflict Resolution (Last Write Wins) khi user đồng bộ thiết bị qua Cloud.

## Context / Constraints
- Data local được ưu tiên, sync không được xoá đè data chưa đồng bộ.
- Dùng `updated_at` (server time).

## Dependencies
- Phase 1

## Steps

### Step 1: Implement Sync Queue Table
**Files to modify:**  
- `lib/data/local/database/app_database.dart` (Modify existing)
- `lib/data/local/daos/sync_queue_dao.dart` (Create new)

**Action:**  
- Tạo bảng `sync_queue` lưu mọi operation (CREATE, UPDATE, DELETE).

### Step 2: Refactor Sync Service
**Files to modify:**  
- `lib/data/services/sync_service.dart` (Modify existing)

**Action:**  
- Đọc `sync_queue` để upload lên backend. Cập nhật `last_sync_cursor`.

## Acceptance Criteria
- Mất mạng -> sửa thẻ -> có mạng -> sync lên server thành công không mất data.
