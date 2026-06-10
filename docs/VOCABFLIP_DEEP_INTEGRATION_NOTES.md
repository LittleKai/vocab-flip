# VOCABFLIP_DEEP_INTEGRATION_NOTES

## 1. Data Model & Storage Deep Dive

### 1.1 SQLite schema

* `decks`: id, name, description, color, created_at, updated_at, deleted_at, sync_status (INDEX on sync_status)
* `cards`: id, deck_id, type, front_text, back_text, created_at, updated_at, deleted_at, sync_status (INDEX on deck_id, sync_status)
* `card_fields`: id, card_id, field_name, field_value (Purpose: custom fields support)
* `card_srs_state`: card_id, due_date, state, stability, difficulty, elapsed_days, scheduled_days, reps, lapses (FSRS parameters)
* `review_logs`: id, card_id, rating, state, elapsed_days, scheduled_days, review_time, duration_ms
* `study_sessions`: id, deck_id, start_time, end_time, cards_reviewed, correct_count
* `tags`: id, name, color
* `card_tags`: card_id, tag_id
* `media_assets`: id, file_name, file_type, local_path, remote_url, size_bytes, checksum
* `import_jobs`: id, status, source_type, file_path, total_cards, imported_cards, error_log
* `sync_queue`: id, entity_type, entity_id, operation (CREATE/UPDATE/DELETE), timestamp
* `sync_state`: key, last_sync_cursor
* `ai_card_drafts`: id, source_text, prompt_used, front_draft, back_draft, status (pending/accepted/rejected)
* `source_documents`: id, file_name, file_hash, parsed_text

*Migration notes*: Cần migration script để parse `SM-2` parameters cũ thành default `FSRS` parameters. Thêm cột `deleted_at` cho soft delete.

### 1.2 MongoDB schema

* `users`: _id, email, username, roles, credits, created_at
* `cloud_decks`: _id, user_id, name, desc, created_at, updated_at, is_public
* `cloud_cards`: _id, deck_id, user_id, front, back, srs_data, updated_at
* `public_decks`: _id, author_id, original_deck_id, name, description, tags, downloads, average_rating, review_count
* `deck_ratings`: _id, deck_id, user_id, rating, created_at
* `deck_reviews`: _id, deck_id, user_id, comment, rating, created_at
* `deck_reports`: _id, deck_id, user_id, reason, status
* `deck_clone_events`: _id, deck_id, user_id, cloned_at
* `media_assets`: _id, user_id, original_name, b2_key, mime_type, size
* `sync_events`: _id, user_id, cursor, timestamp
* `ai_generation_jobs`: _id, user_id, prompt, status, tokens_used, cost, created_at
* `ai_usage_logs`: _id, user_id, endpoint, tokens, date
* `source_documents`: _id, user_id, hash, content_ref

*Sync Relationship*: `cloud_decks` và `cloud_cards` map 1-1 với local SQLite records. Dùng `updated_at` (cùng epoch server) làm cursor.

---

## 2. Study Modes & Learning Flow Deep Dive

| Study Mode | Source Inspiration | User Flow | Required Data | Scoring Logic | SRS Impact | UI Notes | Priority | Difficulty |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Classic Flip | Anki | Xem Front -> lật Back -> chọn rating | Card Text | 4 nút (Again, Hard, Good, Easy) | Yes | Nút to dễ bấm | P0 | Easy |
| Reverse Card | Flashcards OS | Xem Back -> lật Front | Card Text | Như trên | Yes | Hiển thị tag [Reverse] | P1 | Easy |
| Multiple Choice | Quizlet | Xem câu hỏi -> Chọn 1 trong 4 đáp án | Card Text + 3 distractors | Đúng/Sai (Good/Again) | Yes | Auto-generate distractors bằng AI hoặc lấy card cùng deck | P1 | Medium |
| Type Answer | Anki | Nhập text -> so sánh Diff | Front, Back text | Exact/Fuzzy match -> pass/fail | Yes | Bàn phím ảo auto focus | P1 | Medium |
| AI Quiz Mode | OpenTutor | Chatbot hỏi đáp / trắc nghiệm | Card context + LLM | Đánh giá bởi LLM | No | Giao diện Chat UI | P2 | Hard |
| Weak Words | VocabFlip | Lọc thẻ Lapses > 3 | List of bad cards | Good/Again | No | Tập trung sửa sai | P2 | Easy |

*Giải thích*: Mode Multiple Choice, Type Answer, Classic Flip sẽ cập nhật SRS. Mode Weak Words / AI Quiz Mode chỉ practice thêm không ảnh hưởng due_date.

---

## 3. Deck Sharing / Import / Export Deep Dive

### 3.1 Import formats

| Format | Priority | Parser Needed | Media Support | Difficulty | Notes |
| --- | --- | --- | --- | --- | --- |
| CSV | P1 | Cần (csv_parser) | No | Easy | Cơ bản nhất |
| Anki `.apkg` | P2 | Cần (sqlite/zip) | Yes | Hard | Rất quan trọng để kéo user Anki qua |
| Plain text | P1 | Cần split by \t hoặc \n | No | Easy | Dùng clipboard paste |

### 3.2 VocabFlip package format

File: `export.vocabflipdeck` (Thực chất là ZIP)
Bao gồm:
- `manifest.json`: Chứa metadata (version, deck name, created_at).
- `cards.json`: Chứa list thẻ và tags.
- `media/`: Folder chứa ảnh, audio.

### 3.3 Public Library flow

* Phân quyền (Publish): Người dùng ấn "Publish", backend lưu bản snapshot của deck vào `public_decks`.
* Clone: User khác ấn "Download", backend copy records vào `cloud_decks` của user đó và trả về local qua sync.
* Review/Rate: Cập nhật average rating vào collection `public_decks`.

---

## 4. Pronunciation / Audio / TTS Deep Dive

* System TTS (flutter_tts): Dùng làm mặc định, miễn phí, hỗ trợ đa ngôn ngữ. Phù hợp offline.
* Cloud TTS (Google Cloud/AWS Polly): Chỉ dùng cho thẻ public hoặc premium user do tốn credit.
* Audio files: Hỗ trợ đính kèm file audio từ B2.

* UX trong Card Editor*: Có nút phát âm thanh trên front/back. Tự động phát khi lật thẻ (tuỳ chọn Settings).

---

## 5. Dictionary / Translation / Vocabulary Enrichment Deep Dive

* Data model: Tích hợp API Free Dictionary hoặc dùng AI fallback.
* Flow: User nhập từ -> lookup API -> hiển thị IPA, part of speech, collocations. Nhấn "Add to card" -> Điền tự động vào Card Editor.

---

## 6. AI Card Generation & AI Enhancement Deep Dive

### 6.1 AI generation pipeline
`Input -> Extract -> Generate JSON Drafts -> Validate Schema -> User Review -> Save`

### 6.2 AI use cases

| Use Case | Priority | Input | Output | Prompt Notes | Cost Risk | Hallucination Risk | Implementation Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Generate from Text | P1 | Đoạn văn | List thẻ (JSON) | Yêu cầu định dạng JSON strict | Low | Medium | Dùng model giá rẻ như MiniMax |
| Mnemonic Gen | P1 | Từ vựng | 1 câu mnemonic | Bám sát phát âm tiếng Việt/Anh | Low | Medium | Tham khảo prompt AnkiAIUtils |
| Explain wrong | P2 | Front/Back | Giải thích | Ngắn gọn 2-3 câu | Low | Low | Trong mode AI Quiz |

### 6.3 AI safety and quality
- JSON schema validation: Bắt buộc dùng Structured Outputs của LLM.
- User review queue: Các thẻ AI tạo ra phải nằm ở trạng thái `ai_card_drafts` và chờ user approve mới vào DB học.

---

## 7. Analytics & Personalization Deep Dive

| Metric | Data Source | Formula | UI Placement | Priority | Notes |
| --- | --- | --- | --- | --- | --- |
| Retention rate | review_logs | (Correct / Total reviews) * 100 | Stats Tab | P1 | Thống kê theo tuần |
| Streak | study_sessions | Consecutive days > 0 reviews | Home Screen | P1 | Động lực học tập |
| Weak words | card_srs_state | Lapses > 3 & retention < 50% | Stats Tab | P1 | Gợi ý học lại |

---

## 8. UI/UX Implementation Notes

- **Home**: Dashboard với Streak, Daily Goal, Due cards to-do. Hero banner. (Mobile)
- **Deck List**: Card list UI gọn, vuốt (swipe) để xoá/edit.
- **Card Editor**: WYSIWYG, hỗ trợ attach ảnh (presigned B2 url), pick audio, nút AI auto-fill.
- **Study Session**: Full-screen, tắt navbar, tập trung focus. 4 nút màu phân biệt rõ (Again/Hard/Good/Easy).

---

## 9. Implementation Tasks

### Data Model
### Task 01: Create SQLite Schema Migration
**Goal:** Tạo bảng cho FSRS parameters và tags, media.
**VocabFlip Files To Create/Modify:** `lib/data/local/database/app_database.dart`
**Acceptance Criteria:** SQLite cập nhật không mất dữ liệu cũ.

### Task 02: MongoDB Schema Implementation
**Goal:** Setup mongoose models cho `public_decks` và `sync_events`.
**Acceptance Criteria:** API test tạo public deck thành công.

### Task 03: Update Sync Queue Logic
**Goal:** Lưu mọi thay đổi local vào bảng `sync_queue`.
**VocabFlip Files To Create/Modify:** `lib/data/local/daos/sync_queue_dao.dart`

### Scheduler
### Task 04: Implement FSRSScheduler Engine
**Goal:** Thêm class tính toán FSRS 4.5.
**Reference Projects / Files:** `OpenTutor` (FSRS implementation).

### Task 05: FSRS state persistance
**Goal:** Lưu trạng thái SrsState vào DB sau mỗi lần lật thẻ.

### Study Modes
### Task 06: Multiple Choice Mode UI
**Goal:** Tạo màn hình trắc nghiệm, hiển thị 4 lựa chọn.

### Task 07: Distractor Generator
**Goal:** Thuật toán ngẫu nhiên bốc 3 đáp án sai từ cùng deck làm distractors.

### Task 08: Type Answer Mode
**Goal:** Màn hình có TextField để gõ đáp án và diff highlight.

### AI
### Task 09: Node.js AI Gateway Endpoint
**Goal:** Route `/api/ai/generate-cards` nhận văn bản, trả JSON.

### Task 10: AI Card Draft Queue UI
**Goal:** Màn hình Flutter cho phép user quẹt (Tinder-like) để approve/reject AI generated cards.

### Task 11: Mnemonic Generator Integration
**Goal:** Nút tia sét "Gợi ý nhớ" trong Card Editor gọi API tạo mnemonic.
**Reference Projects / Files:** `AnkiAIUtils`.

### Task 12: AI Wallet & Credit Middleware
**Goal:** Trừ điểm (credits) user mỗi khi xài tính năng AI trên backend.

### Dictionary
### Task 13: Free Dictionary API Client
**Goal:** Class gọi API từ điển để lấy ví dụ, IPA.

### Task 14: Dictionary UI Widget
**Goal:** Bottom sheet hiện giải nghĩa khi user highlight từ trong app.

### TTS / Audio
### Task 15: flutter_tts Integration
**Goal:** Đọc front_text/back_text bằng `flutter_tts` plugin.

### Task 16: Auto-play Audio Setting
**Goal:** Thêm vào settings tuỳ chọn "Tự động phát âm thanh khi lật thẻ".

### Task 17: Audio Icon UI
**Goal:** Nút bấm phát loa trên từng flashcard.

### Import/Export
### Task 18: CSV Import Wizard
**Goal:** Màn hình mapping column -> front/back khi chọn file CSV.

### Task 19: Anki .apkg Parser Setup
**Goal:** Nghiên cứu và import thư viện unarchive zip, đọc db sqlite Anki.

### Task 20: VocabFlipDeck Exporter
**Goal:** Zip JSON cards và media thành file đuôi `.vocabflipdeck` để chia sẻ.

### Public Library
### Task 21: Publish Deck Flow
**Goal:** Nút "Publish", hiện popup điền mô tả, tags, gọi API backend.

### Task 22: Public Library Search & Filter UI
**Goal:** Màn hình khám phá thẻ thư viện cộng đồng.

### Task 23: Clone Public Deck API
**Goal:** Download JSON deck từ API và insert vào local DB.

### Task 24: Deck Rating & Review UI
**Goal:** Component đánh giá 5 sao cho Public Deck.

### Sync
### Task 25: Conflict Resolution Logic
**Goal:** Xử lý "Last Write Wins" bằng `updated_at` trong sync_service.

### Task 26: Media Upload Queue
**Goal:** Tách việc upload ảnh ra background worker (Dùng presigned url B2).

### Analytics
### Task 27: Study Heatmap Widget
**Goal:** Biểu đồ lịch sử review giống contribution graph GitHub.

### Task 28: Weak Words Extraction
**Goal:** Query SQLite lấy thẻ `lapses > 3` và hiển thị list.

### UI/UX
### Task 29: Settings Screen Revamp
**Goal:** Cấu trúc lại menu Settings (Account, Study, Sync, AI, About).

### Task 30: Loading Skeletons
**Goal:** Thêm shimmer skeletons cho mọi màn hình lúc chờ data/sync.

---

## 10. Final Priority Matrix

| Item | Category | Score / 10 | Priority | Difficulty | Dependency | Suggested Phase | Notes |
| ---- | -------- | ---------: | -------- | ---------- | ---------- | --------------- | ----- |
| FSRS Engine | Scheduler | 9 | P0 | Hard | SQLite Schema | Phase 1 | Cốt lõi của việc review |
| Sync Queue | Sync | 9 | P0 | Hard | MongoDB Schema | Phase 1 | Cốt lõi lưu trữ đám mây |
| Multiple Choice | Study Mode | 8 | P1 | Medium | Deck Data | Phase 2 | Tăng tương tác người dùng |
| CSV Import | Import/Export| 8 | P1 | Easy | Local DB | Phase 2 | Dễ triển khai, lợi ích lớn |
| Mnemonic AI | AI | 9 | P1 | Medium | AI Gateway | Phase 2 | Tính năng "Wow" factor thu hút user |
| Public Library | Library | 8 | P2 | Hard | Backend | Phase 3 | Mở rộng tính năng cộng đồng |
| Heatmap | Analytics | 7 | P2 | Easy | Review Logs | Phase 3 | Giúp user theo dõi tiến độ |
| Anki Import | Import/Export| 7 | P3 | Very Hard| SQLite | Phase 4 | Kéo user Anki qua, phức tạp cao |
