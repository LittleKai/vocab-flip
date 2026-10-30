# Shared Code Kit — VocabFlip

## Quyết định

VocabFlip đang sống và deploy liên tục; code dùng chung nên được load chung trong app. Các hàm đã được promote vào `lib/_kit/formatters.dart`:

- `formatCompactCount(int count)` — định dạng số lượng rút gọn (`K`, `M`).
- `categoryIconFromName(String? iconName)` — ánh xạ tên icon danh mục sang `IconData` (fallback `Icons.category`), dùng chung tại `deck_list_screen.dart`, `deck_detail_screen.dart`, `public_deck_detail_screen.dart` và `public_deck_card.dart`.
- `formatPublicFieldNames(String fields)` — định dạng danh sách trường mặt trước/sau của bộ thẻ công khai (`public_deck_detail_screen.dart`, `public_deck_card.dart`).
- `formatCardFields(List<CardFieldType> fields)` — định dạng danh sách `CardFieldType` của bộ thẻ cá nhân (`deck_list_screen.dart`, `deck_detail_screen.dart`).

## LUẬT PROMOTE

- Viết được hàm dùng lại cho lần sau và đã chạy thật thì chuyển vào `lib/_kit/` ngay trong task đó.
- Đổi tên riêng thành tham số; không giữ bản copy sau khi promote.
- Nếu khác hành vi, chốt chữ ký và fallback trước; không ép một helper chung biết chi tiết của từng màn hình.
- Mỗi caller phải chạy lại sau khi promote.
