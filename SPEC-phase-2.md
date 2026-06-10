# SPEC Phase 2: AI Card Studio Foundation (Mnemonic & Explainer)

## Goal
Bổ sung tính năng tạo Câu gợi nhớ (Mnemonic) và Giải thích thẻ sai bằng AI.

## Context / Constraints
- Backend: Express + MongoDB.
- Frontend: Cần thêm nút "Gợi ý nhớ" trên UI.
- API AI: Phải trả về chuẩn JSON, có validate schema.

## Dependencies
- Phase 1 hoàn tất (để data schema card ổn định).

## Files / Areas To Inspect First
- `lib/data/api/api_client.dart`
- Backend source (trong node server)
- `lib/presentation/screens/card_editor_screen.dart` (Nếu có, hoặc cần Create new)

## Steps

### Step 1: Backend AI Endpoint (Express)
**Files to modify:**  
- `server/routes/ai.js` (Create/Modify in backend if exists)

**Action:**  
- Tạo endpoint `POST /api/ai/mnemonic` gọi LLM provider (MiniMax).
- Yêu cầu cấu trúc JSON Schema (ví dụ: `{"mnemonic": "...", "explanation": "..."}`).

**Verify:**  
- Gọi Postman trả về đúng JSON, trả về lỗi 401 nếu thiếu Auth.

### Step 2: Frontend AI Client integration
**Files to modify:**  
- `lib/data/api/api_client.dart` (Modify existing)
- `lib/data/repositories/ai_repository.dart` (Create new)

**Action:**  
- Viết API call đến `/api/ai/mnemonic`.

**Verify:**  
- Unit test mock fetch API pass.

### Step 3: Card Editor UI Integration
**Files to modify:**  
- UI Card Editor (Search component name trong codebase)

**Action:**  
- Thêm icon tia sét. Bấm vào gọi AI, hiện BottomSheet hiển thị Mnemonic. Cho phép user ấn "Add to card".

**Verify:**  
- UI không block main thread khi fetch AI.

## Acceptance Criteria
- Mnemonic tự động chèn vào trường `back_text` (hoặc `note` nếu có) của Flashcard.
- Gọi AI có timeout và error fallback.

## Risks / Notes
- Hallucination: Phải dặn model trả lời ngắn gọn.
- Có nguy cơ cạn credit nếu user spam.

## Builder Handoff Notes
Backend setup route là bắt buộc trước khi gắn UI Frontend.
