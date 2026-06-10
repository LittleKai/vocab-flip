# VOCABFLIP_LOW_IMPACT_BACKLOG

## Purpose
Tập hợp các tính năng chưa cần thiết cho MVP, rủi ro cao, hoặc impact thấp, để tham khảo và làm sau khi dự án ổn định.

## Deferred Feature Matrix

| Feature | Category | Score / 10 | Reason Deferred | Revisit After Phase | Notes |
|---|---|---:|---|---|---|
| FSRS 4.5 Full Migration | Scheduler | 8 | Quá phức tạp và rủi ro ảnh hưởng data hiện tại. Đợi app ổn định user đã. | Phase 3 | Hiện tại chỉ tách interface. |
| Anki `.apkg` Import | Import/Export | 7 | Phức tạp trong việc giải nén và convert db sqlite Anki sang dạng của app. | Phase 3 | CSV/JSON quan trọng hơn cho MVP. |
| Knowledge Graph (LOOM) | Analytics | 6 | Chưa rõ nhu cầu user thực tế. App đang tập trung flashcard cơ bản. | Phase 3 | |
| AI Quiz Mode (Chat) | AI | 6 | Khó kiểm soát context và tốn LLM token. | Phase 3 | |
| Auto-play Cloud TTS | TTS | 5 | Chi phí cloud tốn kém nếu free user lạm dụng. | Phase 3 | Tạm thời dùng System TTS (offline) |

## Deferred By Category

### Advanced Study Modes
- Typing exact match (Fuzzy match tốn kém logic).
- Matching Game (UX phức tạp).

### Advanced Import/Export
- PDF to cards (Nên để user làm ở web/backend AI Gateway riêng, thay vì nhồi vào mobile app).

## Do Not Implement Yet
- Gamification / Bảng xếp hạng thi đua: Không phù hợp với định hướng công cụ học tập cá nhân.
- Multiplayer deck battle: Rủi ro server realtime.

## Future Re-Evaluation Checklist
- App đạt 10k người dùng -> Mở khoá Cloud TTS.
- SM-2 có tỷ lệ report retention kém -> Tiến hành đưa FSRS 4.5 vào.
