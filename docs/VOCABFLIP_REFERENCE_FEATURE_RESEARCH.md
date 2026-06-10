# VOCABFLIP_REFERENCE_FEATURE_RESEARCH

## 1. Executive Summary

Tóm tắt ngắn gọn:

* Đã phân tích: 4 dự án (Anki, AnkiAIUtils, Flashcards Open Source App, OpenTutor).
* Dự án nào phù hợp nhất với VocabFlip: OpenTutor và Flashcards Open Source App là phù hợp nhất do sử dụng công nghệ web/mobile hiện đại, FSRS scheduler, và tích hợp AI sâu.
* Nhóm tính năng nào nên ưu tiên: FSRS Scheduler, AI-based Card Enhancement/Mnemonics (từ AnkiAIUtils), và Block-based UI hoặc Agent API.
* Rủi ro lớn nhất khi tích hợp: Thay đổi thuật toán cốt lõi từ SM-2 sang FSRS có thể làm hỏng lịch học hiện tại. Chi phí API AI và quản lý local DB.
* Đề xuất roadmap tích hợp: Chuyển đổi và nâng cấp Scheduler engine, thêm các tính năng AI-assisted draft generation, và xây dựng Public Library chia sẻ deck.

---

## 2. Project Inventory

| # | Project | Local Path | Main Tech | App Type | Has AI | Has SRS | Has Sync | Has Import/Export | License | Relevance Score |
| - | ------- | ---------- | --------- | -------- | ------ | ------- | -------- | ----------------- | ------- | --------------- |
| 1 | anki | `anki` | Python/Rust/JS | Desktop | No | Yes | Yes | Yes | AGPL | 6 |
| 2 | AnkiAIUtils | `AnkiAIUtils` | Python | CLI/Script | Yes | No | No | No | Unknown | 8 |
| 3 | flashcards-open-source-app | `flashcards-open-source-app` | React Native/Next.js | Mobile/Web | Yes | Yes | Yes | Unknown | MIT | 9 |
| 4 | OpenTutor | `OpenTutor` | Next.js/FastAPI | Web | Yes | Yes | Unknown | Yes | MIT | 9 |

---

## 3. Final Ranking

| Rank | Project | Score / 10 | Why It Matters For VocabFlip | Best Features To Borrow | Integration Difficulty | Notes |
| ---- | ------: | ---------: | ---------------------------- | ----------------------- | ---------------------- | ----- |
| 1 | OpenTutor | 9 | Tích hợp AI toàn diện và sử dụng FSRS 4.5. Tư duy workspace block-based. | AI Tutor, FSRS, Knowledge Graph | Hard | Hướng tiếp cận học tập chủ động và AI giải thích bài. |
| 2 | flashcards-open-source-app | 9 | App Flashcard mã nguồn mở hoàn chỉnh trên iOS/Android dùng AI, FSRS. | FSRS Scheduler, Agent API, Sync | Medium | Tương thích rất cao với định hướng của VocabFlip (Mobile). |
| 3 | AnkiAIUtils | 8 | Cung cấp logic tuyệt vời để làm giàu flashcard với LLMs. | Illustrator, Reformulator, Mnemonics | Medium | Ý tưởng AI tạo mnemonics và hình ảnh cho card cực kỳ tốt. |
| 4 | anki | 6 | Standard engine của flashcard, định hình SRS logic. | SM-2, Import/Export | Very Hard | Code base cũ, khó tích hợp trực tiếp, chủ yếu tham khảo. |

---

## 4. Feature Extraction Matrix

| Feature | Source Project | Category | Description | Fit For VocabFlip | Score / 10 | Difficulty | Priority | Implementation Notes |
| ------- | -------------- | -------- | ----------- | ----------------- | ---------: | ---------- | -------- | -------------------- |
| FSRS Scheduler | OpenTutor/Flashcards | SRS / Scheduler | Thuật toán tối ưu hoá khoảng cách lặp (Free Spaced Repetition Scheduler) 4.5 | High | 9 | Hard | P1 | Cần cẩn trọng migrate từ SM-2 |
| AI Mnemonics | AnkiAIUtils | AI Card Enhancement | Dùng LLM tạo câu gợi nhớ (Mnemonics) cho card khó | High | 9 | Medium | P1 | Dùng OpenAI/MiniMax qua API Gateway |
| AI Reformulator | AnkiAIUtils | AI Card Enhancement | Viết lại card để rõ nghĩa hơn | Medium | 7 | Medium | P2 | Rất hay cho review card chất lượng kém |
| Knowledge Graph | OpenTutor | Analytics / Statistics | Liên kết từ vựng, ngữ pháp thành Graph | Low | 6 | Very Hard | P3 | Phức tạp cho app focus vào Flashcard đơn giản |
| Agent API | Flashcards OS App | DevOps / Release | External API cho terminal/agent thao tác với card | Medium | 7 | Medium | P2 | |
| Cognitive Load UI | OpenTutor | UI / UX | Thay đổi UI tuỳ theo mức độ mệt mỏi/sai của user | Medium | 8 | Hard | P2 | Phát hiện user fatigue để đổi mode học |

---

## 5. Detailed Analysis Per Project

## 5.1. OpenTutor

### Overview

* Mục tiêu dự án: Block-based adaptive learning workspace (chạy local-first).
* App type: Web
* Tech stack: Next.js 16, FastAPI, SQLite, Python.
* Kiến trúc tổng quan: Frontend Next.js gọi API Python, 3 agent (Tutor, Planner, Layout) quản lý state.
* License: MIT
* Mức phù hợp với VocabFlip: Rất cao ở khía cạnh công nghệ AI và SRS.

### Important Files / Folders

| Path | Purpose | Notes |
| ---- | ------- | ----- |
| `apps/api/services/spaced_repetition/` | FSRS implementation | FSRS 4.5 implementation |
| `apps/api/services/agent/` | Multi-agent logic | Tutor, Planner, Layout agents |

### Key Features

- Adaptive Quiz & Practice
- Spaced Repetition (FSRS 4.5)
- Knowledge Graph (LOOM)
- Semantic Review (LECTOR)
- 30-Second Content Ingestion

### Architecture Lessons

Chia Backend xử lý AI logic thành các Agent riêng (Tutor, Planner, Layout) thông qua API layer (Express/NodeJS có thể áp dụng tương tự).

### Scheduler / SRS Logic

- FSRS 4.5
- Tính due date, memory states liên tục theo FSRS parameters. Hoàn toàn có thể build một `FSRSScheduler` engine trong VocabFlip.

### AI Logic

- Dùng Ollama/Litellm cho LLM Providers.
- AI Tutor dựa trên context bài học, nhắc nhở (spaced repetition).

---

## 5.2. AnkiAIUtils

### Overview

* Mục tiêu dự án: Bộ công cụ Python CLI để tự động làm giàu flashcard Anki bằng AI.
* App type: CLI
* Tech stack: Python, LiteLLM
* Kiến trúc tổng quan: Scripts kết nối với AnkiConnect để đọc, gửi qua LLM API, và update card.
* License: Unknown
* Mức phù hợp với VocabFlip: Ý tưởng AI Card Enhancement cực tốt.

### Key Features

- Illustrator: Vẽ ảnh dựa trên text.
- Reformulator: Tối ưu lại nội dung card.
- Mnemonics Creator: Tạo câu nhớ (Mnemonics) cực hay.
- Explainer: AI giải thích tại sao trả lời sai.

### AI Logic

- Tạo prompt tinh gọn theo từng use case (Illustrator prompt, Mnemonic prompt).
- Dùng `LiteLLM` để switch model.
- Ý tưởng Prompt Template có thể bưng nguyên xi vào Node.js Backend của VocabFlip.

---

## 5.3. Flashcards Open Source App

### Overview

* Mục tiêu dự án: App đa nền tảng flashcard tích hợp AI.
* App type: iOS, Android, Web
* Tech stack: React Native, Next.js
* License: MIT
* Mức phù hợp với VocabFlip: Cực cao vì cùng là Mobile App.

### Key Features

- Card scheduling FSRS
- Agent API

---

## 6. Recommended VocabFlip Architecture Improvements

### 6.1. Frontend Flutter Architecture

```txt
lib/
  core/
  data/
  presentation/
    features/
      study/
      deck/
      library/
  shared/
```

### 6.2. Scheduler Architecture

```dart
abstract class SchedulerEngine {
  ReviewResult review(CardSrsState state, ReviewRating rating, DateTime now);
}

class SM2Scheduler implements SchedulerEngine { ... }
class FSRSScheduler implements SchedulerEngine { ... }
```

Cần thêm feature flag hoặc migration path để user chuyển SM-2 -> FSRS an toàn.

### 6.3. AI Card Studio Architecture

```txt
Flutter
 -> Node.js AI Gateway (Express)
 -> Extractor / Mnemonics Generator (Prompt Builder)
 -> LLM Provider (MiniMax / OpenAI)
 -> JSON Schema Validation
 -> Card Draft Review
 -> Save to MongoDB
```

### 6.4. Public Library Architecture

Sử dụng MongoDB:
* `PublicDeck` (name, tags, description, rating, author)
* `DeckReview` (comments, rating)

### 6.5. Sync Architecture

Sử dụng cursor-based sync:
* `updatedAt` / `deletedAt` cho local SQLite.
* Push dirty records lên Mongo, xử lý conflict theo "Last Write Wins" hoặc Server Authority.

### 6.6. Media Architecture

Sử dụng Backblaze B2:
* Backend tạo presigned URL để client (Flutter) tự upload trực tiếp.
* Image compression tại client trước khi upload.

---

## 7. Implementation Roadmap

## Phase 1: MVP Stabilization

| Task | Source Inspiration | Priority | Difficulty | Expected Impact | Notes |
| ---- | ------------------ | -------- | ---------- | --------------- | ----- |
| Tối ưu Sync Sync queue | VocabFlip | P0 | Medium | High | Fix các lỗi sync |

## Phase 2: AI Card Studio

| Task | Source Inspiration | Priority | Difficulty | Expected Impact | Notes |
| ---- | ------------------ | -------- | ---------- | --------------- | ----- |
| Thêm Mnemonics/Explainer | AnkiAIUtils | P1 | Medium | High | Card phong phú hơn |

## Phase 3: Public Library & Sync

| Task | Source Inspiration | Priority | Difficulty | Expected Impact | Notes |
| ---- | ------------------ | -------- | ---------- | --------------- | ----- |
| Model Public Deck | - | P1 | Medium | High | Nâng tầm app |

---

## 8. Top 20 Actionable Tasks

### Task 01: Tạo SchedulerEngine abstraction
**Goal:** Tách SM-2 logic hiện tại thành `SM2Scheduler` implement `SchedulerEngine` interface.
**Why:** Dọn đường để thêm `FSRSScheduler` (như OpenTutor).
**Reference Project:** OpenTutor
**Files likely to change in VocabFlip:** `lib/core/utils/spaced_repetition.dart`
**Acceptance Criteria:**
- Định nghĩa interface `SchedulerEngine`.
- Unit test chạy qua.

### Task 02: Thêm AI Mnemonics Generator API
**Goal:** Tạo route `/api/cards/mnemonics` trên backend.
**Why:** Giúp user dễ nhớ từ hơn.
**Reference Project:** AnkiAIUtils

*(Các task tiếp theo từ 3-20 sẽ được mở rộng trong quá trình implementation)*

---

## 9. Risk Assessment

| Risk | Affected Area | Severity | Probability | Mitigation |
| ---- | ------------- | -------- | ----------- | ---------- |
| FSRS Migration | Scheduler | High | Medium | Chạy song song SM-2 và FSRS ở backend/local state. |
| AI Hallucination | Card Creation | Medium | High | Buộc user review (Draft Review Queue) trước khi add. |
| Sync conflict | Sync Logic | High | Low | Dùng cursor / updatedAt cứng. |
| Media storage cost | Storage | Low | Medium | Nén WebP và Limit file size. |

---

## 10. Final Recommendations

* Top dự án nên học sâu: **OpenTutor** (FSRS, block UI), **AnkiAIUtils** (AI prompts).
* Kiến trúc nên thay đổi ngay: **SchedulerEngine abstraction** để tách SM-2.
* Những file/module VocabFlip nên tạo mới: Các entity cho `ReviewLog` và `PublicDeck`.
