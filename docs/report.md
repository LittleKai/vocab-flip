• ## Báo cáo kỹ thuật: Writing Practice cho VocabFlip

  Kết luận chính: nên dùng pipeline dữ liệu thống nhất từ animCJK + hanzi-writer-data/makemeahanzi, lưu thành một DB riêng stroke_data.db, render bằng Flutter CustomPainter, và port thuật toán validate kiểu Hanzi Writer, có bổ sung ý tưởng segment alignment từ Inkstone ở
  phase sau.

  ## 1. So sánh nguồn dữ liệu

   Nguồn                Ưu điểm                                                                                    Nhược điểm                                                                          Khuyến nghị
  ━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   hanzi-writer-data    JSON mỗi chữ: strokes SVG path + medians; hợp trực tiếp với animation/validation           Chủ yếu Chinese/MakeMeAHanzi; không giải quyết Japanese variant                     Dùng cho zh-Hans/zh-Hant nếu coverage đủ
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────────────────  ──────────────────────────────────────────────────────────────────────────────────  ─────────────────────────────────────────────────────────────────────────
   makemeahanzi         graphics.txt + dictionary.txt; có pinyin, radical, decomposition, matches                  File lớn, format JSONL cần preprocess                                               Dùng làm nguồn raw/backup cho Chinese
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────────────────  ──────────────────────────────────────────────────────────────────────────────────  ─────────────────────────────────────────────────────────────────────────
   animCJK              Có graphicsJa, graphicsJaKana, graphicsZhHans, graphicsZhHant; format gần giống Hanzi      Dữ liệu lớn, một số stroke split đặc biệt                                           Nguồn tốt nhất để đồng nhất Nhật + Trung
                        Writer; có kana
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────────────────  ──────────────────────────────────────────────────────────────────────────────────  ─────────────────────────────────────────────────────────────────────────
   kanjivg              Metadata Kanji rất giàu: kvg:element, kvg:type, stroke number                              SVG path là nét line mở, không có filled outline + median riêng như Hanzi Writer    Dùng bổ sung cho Kanji Nhật/metadata, không làm source validation chính
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────────────────  ──────────────────────────────────────────────────────────────────────────────────  ─────────────────────────────────────────────────────────────────────────
   inkstone             Có app practice hoàn chỉnh, matcher thực chiến                                             GPLv3, không nên copy code trực tiếp vào app nếu license không tương thích          Chỉ học thuật toán, tự viết lại Dart

  Khuyến nghị dữ liệu: ưu tiên animCJK làm source unified vì có Japanese Kanji/Kana và Chinese Simplified/Traditional trong cùng schema character/strokes/medians. Với chữ Trung, có thể merge/compare với hanzi-writer-data để tận dụng ecosystem Hanzi Writer.

  ## 2. Storage & Schema

  Không nên nhét vào ja_vi_dict.db hoặc zh_vi_dict.db. Lý do: khác license, khác vòng đời update, khác schema, và cùng Unicode có glyph/order khác giữa Nhật và Trung.

  Tạo asset DB riêng:

  CREATE TABLE stroke_chars (
    id TEXT PRIMARY KEY,          -- "ja:日", "zh-Hans:日"
    character TEXT NOT NULL,
    locale TEXT NOT NULL,         -- ja, ja-kana, zh-Hans, zh-Hant
    source TEXT NOT NULL,         -- animCJK, hanzi-writer-data, kanjivg
    stroke_count INTEGER NOT NULL,
    view_box TEXT NOT NULL,       -- JSON [0,0,1024,1024]
    data_json TEXT NOT NULL,      -- unified JSON below
    updated_at TEXT
  );
  CREATE INDEX idx_stroke_chars_lookup ON stroke_chars(character, locale);

  Unified JSON:

  {
    "character": "日",
    "locale": "ja",
    "source": "animCJK",
    "viewBox": [0, 0, 1024, 1024],
    "strokes": [
      {
        "index": 0,
        "path": "M ... Z",
        "median": [[121, 393], [193, 372]],
        "type": null,
        "component": null
      }
    ]
  }

  Normalize toàn bộ dữ liệu sang hệ tọa độ Flutter: origin top-left, y tăng xuống dưới, canvas logical 1024x1024.

  ## 3. Flutter Architecture

  Thêm module mới, không đổi FSRS/scheduler:

  - lib/data/models/stroke_character.dart
  - lib/data/local/database/stroke_data_dao.dart
  - lib/data/repositories/stroke_data_repository.dart
  - lib/presentation/providers/stroke_practice_provider.dart
  - lib/presentation/widgets/stroke/stroke_order_painter.dart
  - lib/presentation/widgets/flashcard/writing_practice_card.dart

  Tích hợp vào lib/presentation/screens/study/study_screen.dart:15:

  enum StudyMode {
    classic,
    multipleChoice,
    typeAnswer,
    writingPractice,
  }

  Chỉ hiển thị mode này khi deck source language là ja hoặc zh và StrokeDataRepository tìm thấy dữ liệu cho card.front.

  ## 4. Rendering mẫu

  Nên dùng dependency nhỏ path_drawing để parse SVG path an toàn.

  class StrokeCharacter {
    StrokeCharacter({required this.character, required this.strokes});
    final String character;
    final List<StrokeData> strokes;

    factory StrokeCharacter.fromJson(Map<String, dynamic> json) {
      return StrokeCharacter(
        character: json['character'],
        strokes: (json['strokes'] as List)
            .map((e) => StrokeData.fromJson(e))
            .toList(),
      );
    }
  }

  class StrokeData {
    StrokeData({required this.pathData, required this.median});
    final String pathData;
    final List<Offset> median;

    factory StrokeData.fromJson(Map<String, dynamic> json) {
      return StrokeData(
        pathData: json['path'],
        median: (json['median'] as List)
            .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList(),
      );
    }
  }

  class StrokeOrderPainter extends CustomPainter {
    StrokeOrderPainter(this.character, this.revealed, this.activeProgress);

    final StrokeCharacter character;
    final int revealed;
    final double activeProgress;

    @override
    void paint(Canvas canvas, Size size) {
      final scale = size.shortestSide / 1024.0;
      canvas.save();
      canvas.scale(scale, scale);

      final outlinePaint = Paint()..color = const Color(0xFFE0E0E0);
      final inkPaint = Paint()..color = Colors.black;

      for (var i = 0; i < character.strokes.length; i++) {
        final stroke = character.strokes[i];
        final outline = parseSvgPathData(stroke.pathData);

        if (i < revealed) {
          canvas.drawPath(outline, inkPaint);
        } else {
          canvas.drawPath(outline, outlinePaint);
        }

        if (i == revealed) {
          canvas.save();
          canvas.clipPath(outline);
          final partial = _partialPolyline(stroke.median, activeProgress);
          canvas.drawPath(
            partial,
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.stroke
              ..strokeWidth = 128
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
          canvas.restore();
        }
      }
      canvas.restore();
    }

    Path _partialPolyline(List<Offset> points, double t) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      final count = (points.length * t).clamp(1, points.length).floor();
      for (final p in points.take(count)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    @override
    bool shouldRepaint(covariant StrokeOrderPainter old) => true;
  }

  ## 5. Validation Algorithm

  Port phase 1 từ Hanzi Writer:

  - Deduplicate user points.
  - Normalize pointer points vào canvas 1024.
  - So với stroke expected theo thứ tự hiện tại.
  - Check average distance, start/end distance, direction cosine, length ratio, Fréchet distance.
  - Nếu reversed pass thì báo “sai hướng”.
  - Nếu match stroke sau tốt hơn stroke hiện tại thì báo “sai thứ tự”.

  Pseudo Dart:

  StrokeMatch validateStroke(
    List<Offset> user,
    StrokeCharacter char,
    int expectedIndex,
  ) {
    final expected = char.strokes[expectedIndex].median;
    final clean = dedupe(user);
    if (clean.length < 2) return StrokeMatch.fail('too_short');

    final avg = averageDistanceToPolyline(clean, expected);
    final startOk = distance(clean.first, expected.first) < 250;
    final endOk = distance(clean.last, expected.last) < 250;
    final dirOk = averageCosineSimilarity(clean, expected) > 0;
    final lenOk = polylineLength(clean) / (polylineLength(expected) + 25) > 0.35;
    final shapeOk = frechet(normalize(clean), normalize(expected)) < 0.4;

    final ok = avg < 350 && startOk && endOk && dirOk && lenOk && shapeOk;
    if (ok) return StrokeMatch.ok(score: 1 - (avg / 350));

    final reversed = clean.reversed.toList();
    if (frechet(normalize(reversed), normalize(expected)) < 0.4) {
      return StrokeMatch.fail('backwards');
    }
    return StrokeMatch.fail('inaccurate');
  }

  Inkstone phase 2 nâng cấp: ShortStraw corner detection + dynamic programming segment alignment để bắt hook, shortcuts, và stroke out-of-order mềm hơn. Không copy code GPL; tự viết lại dựa trên mô tả thuật toán.

  ## 6. Study Flow UX

  Trong Study screen:

  - Card front hiển thị chữ lớn, phonetic, nghĩa ngắn.
  - Canvas vuông với guideline mờ.
  - Toolbar icon: play animation, reset, hint, undo.
  - Người học viết từng nét. Đúng nét thì nét chuyển sang màu đen; sai nét fade và hiện hint stroke hiện tại.
  - Hoàn thành chữ: auto rate.
      - 0 lỗi: ReviewRating.easy
      - 1-2 lỗi: ReviewRating.good
      - 3-5 lỗi: ReviewRating.hard
      - nhiều lỗi hoặc bỏ qua: ReviewRating.again

  Provider mới chỉ giữ state practice/canvas/cache; StudyProvider.rateCard vẫn là điểm duy nhất cập nhật FSRS và review log.

  ## 7. Roadmap

  1. Data audit & converter
      - Viết tool convert animCJK graphics*.txt và hanzi-writer-data sang unified JSON.
      - Verify 20 chữ mẫu: 一, 日, 中, kana あ, chữ Trung giản/phồn.

  2. Stroke DB
      - Build assets/stroke_data.db.
      - Thêm DAO/repository read-only giống dictionary DB, không migration user DB.

  3. Renderer
      - Thêm StrokeOrderPainter, animation controller, guideline canvas.
      - Test render bằng widget tests/screenshot smoke nếu khả thi.

  4. Practice input
      - GestureDetector capture pan start/update/end.
      - Draw user stroke bằng CustomPainter.

  5. Validation v1
      - Port Hanzi Writer matching sang Dart.
      - Unit test với synthetic strokes: đúng, sai hướng, sai thứ tự, lệch xa.

  6. Study integration
      - Thêm StudyMode.writingPractice.
      - Thêm l10n EN/VI.
      - Hide mode nếu không có stroke data.

  7. Polish
      - Hint/replay/undo.
      - Cache stroke data per session.
      - Optional Inkstone-style corner matcher cho chữ phức tạp.