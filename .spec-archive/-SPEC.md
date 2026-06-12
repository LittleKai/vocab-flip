# SPEC: VocabFlip Full Integration & Roadmap Plan

## Goal
Tích hợp toàn diện các tính năng cốt lõi và nâng cao cho VocabFlip dựa trên nghiên cứu kiến trúc (AnkiAIUtils, OpenTutor, Flashcards OS). Mục tiêu là biến VocabFlip thành công cụ flashcard tích hợp AI và Learning Science mạnh mẽ nhất, trong khi vẫn giữ cấu trúc module sạch sẽ và dễ maintain.

## Source Research Files
- `docs/VOCABFLIP_REFERENCE_FEATURE_RESEARCH.md`
- `docs/VOCABFLIP_DEEP_INTEGRATION_NOTES.md`

---

## Phase Overview

Dưới đây là danh sách toàn bộ các Phase của dự án sau khi đã gỡ bỏ phần Import/Export.

| Phase | File | Goal | Can Run In Parallel | Depends On | Impact |
|---|---|---|---|---|---|
| Phase 1 | `SPEC-phase-1.md` | Core Data Model + Scheduler Abstraction | No | None | P0 (Đã hoàn tất) |
| Phase 2 | `SPEC-phase-2.md` | AI Mnemonic & Explainer API | Yes | Phase 1 | P1 (Đã hoàn tất) |
| Phase 3 | `SPEC-phase-3.md` | Sync Queue & Data Consistency | No | Phase 1 | P1 (Đã hoàn tất) |
| Phase 4 | `SPEC-phase-4.md` (TBD) | Advanced Study Modes (Multiple Choice, Type Answer, Weak Words) | Yes | Phase 1 | P1 (UX/Feature) |
| Phase 5 | `SPEC-phase-5.md` (TBD) | AI Card Generation Pipeline (Text to Deck & Draft Queue) | Yes | Phase 2 | P1 (AI Feature) |
| Phase 6 | `SPEC-phase-6.md` (TBD) | FSRS 4.5 Full Implementation & Migration | Yes | Phase 1 | P2 (Core Tech) |
| Phase 7 | `SPEC-phase-7.md` (TBD) | Analytics & Heatmap Dashboard | Yes | Phase 1 | P2 (UX) |
| Phase 8 | `SPEC-phase-8.md` (TBD) | Advanced Learning Science (Fatigue Detection, Semantic Review) | No | Phase 6 | P3 (Research) |

---

## Dependency Graph & Parallel Execution Recommendation

Vì Phase 1, 2, 3 đã xây xong móng nền vững chắc (Data, Sync, AI API base), nên **Phase 4, 5, 6, 7 hiện tại hoàn toàn độc lập với nhau và CÓ THỂ CHẠY SONG SONG**.

### Các nhóm Phase CÓ THỂ thực hiện song song (Parallelizable):

*   **Nhóm A (UX & Frontend)**: **Phase 4** (Advanced Study Modes) và **Phase 7** (Analytics Dashboard). 
    *   *Lý do*: Hai phase này chủ yếu làm việc trên tầng UI của Flutter (thêm màn hình, vẽ biểu đồ) và chỉ `read` dữ liệu từ database, không làm thay đổi cấu trúc bảng.
*   **Nhóm B (Backend & AI)**: **Phase 5** (AI Card Generation Pipeline).
    *   *Lý do*: Chủ yếu xây dựng các endpoint xử lý Text-to-JSON trên Node.js và một màn hình UI hoàn toàn độc lập (Draft Queue) trên Flutter. Không đụng chạm vào logic học thẻ.
*   **Nhóm C (Core Algorithm)**: **Phase 6** (FSRS 4.5 Implementation).
    *   *Lý do*: Xây dựng class `FSRSScheduler` hoàn toàn độc lập. Chỉ đụng đến file logic toán học và script migration data.

### Các Phase PHẢI thực hiện tuần tự (Sequential):

*   **Phase 8** (Advanced Learning Science) BẮT BUỘC phải đợi **Phase 6** (FSRS) hoàn tất vì thuật toán nhận diện Fatigue (mệt mỏi) và Semantic Review cần lấy ma trận DSR (Difficulty, Stability, Retrievability) của FSRS làm đầu vào.

---

## How Builder Should Proceed

Tuỳ thuộc vào việc bạn có bao nhiêu Agent/Builder:
1.  Nếu bạn làm tuần tự: Hãy gọi `/hybrid-ai-skills:build phase 4` để làm các màn hình ôn tập phong phú trước.
2.  Nếu bạn có nhiều session: 
    - Terminal 1 chạy: `/hybrid-ai-skills:build phase 4` (Làm Study Modes).
    - Terminal 2 chạy: `/hybrid-ai-skills:build phase 5` (Làm AI Card Gen).
    - Terminal 3 chạy: `/hybrid-ai-skills:build phase 6` (Cấy FSRS).

## Verification Summary
- File `SPEC.md` đã được update và archive bản cũ.
- Các Phase 1, 2, 3 đã được hoàn thiện trong thực tế.
- Tầng Database (SQLite/Mongo) và SchedulerEngine abstraction đã có sẵn, đảm bảo không bị conflict khi code các phase tiếp theo.
