# Shared Code Kit — VocabFlip

## Quyết định

VocabFlip đang sống và deploy liên tục; code dùng chung nên được load chung trong app. `formatCompactCount` đã được promote vì hai bản copy có cùng hành vi; các bản `_getCategoryIcon` vẫn khác chữ ký hoặc fallback nên chưa gộp.

## Bản sao cần xem lại

| File | Hàm | Nhận xét |
|---|---|---|
| `lib/presentation/screens/library/public_deck_detail_screen.dart` | `_getCategoryIcon` | Bộ icon cần xem lại trước khi gộp |
| `lib/presentation/widgets/library/public_deck_card.dart` | `_getCategoryIcon` | Bộ icon cần xem lại trước khi gộp |
| `lib/presentation/screens/deck/deck_detail_screen.dart` | `_getCategoryIcon` | Bộ icon khác một phần; cần quyết định fallback trước khi gộp |
| `lib/presentation/screens/library/library_search_screen.dart` | `_getCategoryIcon` | Bộ icon/fallback khác; chưa coi là bản copy tương đương |

## LUẬT PROMOTE

- Viết được hàm dùng lại cho lần sau và đã chạy thật thì chuyển vào `lib/_kit/` ngay trong task đó.
- Đổi tên riêng thành tham số; không giữ bản copy sau khi promote.
- Nếu khác hành vi, chốt chữ ký và fallback trước; không ép một helper chung biết chi tiết của từng màn hình.
- Mỗi caller phải chạy lại sau khi promote.
