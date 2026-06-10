# SPEC Phase 5: AI Card Generation Pipeline

## Goal
Xây dựng luồng tự động tạo bộ thẻ (Deck) từ một đoạn văn bản hoặc link bài báo bằng sức mạnh của AI, kết hợp màn hình duyệt (Draft Queue) trước khi lưu.

## Context / Constraints
- Backend (Express) xử lý logic gọi LLM (OpenAI/MiniMax) để tránh expose API Key ở frontend.
- Phải áp dụng JSON Schema Strict Mode để AI trả về đúng format.

## Dependencies
- Phase 2 (Cơ sở AI API đã có).

## Files / Areas To Inspect First
- `lib/data/api/api_client.dart`
- `server/routes/ai.js` (Backend route)

## Steps

### Step 1: Xây dựng Backend Route Text-to-Deck
**Files to modify:** `server/routes/ai.js` (Modify/Create existing)
**Action:**  
- API `POST /api/ai/generate-deck` nhận chuỗi `text`.
- Prompt ép LLM trích xuất từ vựng, giải nghĩa, phiên âm và trả về mảng `[{"front": "", "back": "", "phonetic": ""}...]`.

### Step 2: Giao diện nhập liệu Frontend
**Files to modify:** `lib/presentation/screens/ai/ai_generator_screen.dart` (Create new)
**Action:**  
- Tạo ô TextField lớn để dán văn bản. Nút "Generate".
- Hiển thị Loading skeleton khi gọi API.

### Step 3: Xây dựng Draft Review Queue (Tinder swipe)
**Files to modify:** `lib/presentation/screens/ai/ai_draft_queue_screen.dart` (Create new)
**Action:**  
- Hứng mảng JSON trả về.
- Hiển thị từng thẻ. Vuốt phải (Approve -> Thêm vào DB local), Vuốt trái (Reject -> Bỏ qua).

## Acceptance Criteria
- AI trả về đúng format mảng từ vựng, không bị crash JSON.
- Có thể lưu thẻ vào một Deck cụ thể sau khi Approve.

## Builder Handoff Notes
Chú ý cấu hình Timeout của API Backend vì việc generate nhiều thẻ có thể mất 10-20 giây. Cần hiện thông báo chờ thân thiện ở Frontend.
