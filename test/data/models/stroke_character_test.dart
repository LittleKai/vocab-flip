import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/stroke_character.dart';

void main() {
  /// Complete valid fixture JSON for 一 (ja).
  Map<String, dynamic> validJson() => {
        'character': '一',
        'locale': 'ja',
        'source': 'fixture',
        'viewBox': [0, 0, 1024, 1024],
        'strokes': [
          {
            'index': 0,
            'path': 'M 100 512 L 924 512 L 924 552 L 100 552 Z',
            'median': [
              [100, 532],
              [924, 532],
            ],
            'type': null,
            'component': null,
          }
        ],
      };

  group('StrokePoint', () {
    test('parses from [x, y] list', () {
      final p = StrokePoint.fromJson([100.0, 200.0]);
      expect(p.x, 100.0);
      expect(p.y, 200.0);
    });

    test('round-trips through toJson', () {
      final p = StrokePoint.fromJson([42, 99]);
      expect(p.toJson(), [42.0, 99.0]);
    });

    test('throws on empty list', () {
      expect(
        () => StrokePoint.fromJson([]),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on single-element list', () {
      expect(
        () => StrokePoint.fromJson([1]),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('StrokeData', () {
    test('parses valid stroke JSON', () {
      final s = StrokeData.fromJson({
        'index': 0,
        'path': 'M 0 0 L 100 100',
        'median': [
          [0, 0],
          [100, 100],
        ],
        'type': null,
        'component': null,
      });
      expect(s.index, 0);
      expect(s.path, 'M 0 0 L 100 100');
      expect(s.median.length, 2);
    });

    test('throws on empty path', () {
      expect(
        () => StrokeData.fromJson({
          'index': 0,
          'path': '',
          'median': [
            [0, 0],
            [1, 1],
          ],
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('non-empty "path"'),
        )),
      );
    });

    test('throws on null path', () {
      expect(
        () => StrokeData.fromJson({
          'index': 0,
          'path': null,
          'median': [
            [0, 0],
            [1, 1],
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on one-point median', () {
      expect(
        () => StrokeData.fromJson({
          'index': 0,
          'path': 'M 0 0 L 1 1',
          'median': [
            [0, 0],
          ],
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('at least 2 points'),
        )),
      );
    });

    test('throws on empty median', () {
      expect(
        () => StrokeData.fromJson({
          'index': 0,
          'path': 'M 0 0 L 1 1',
          'median': [],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on null median', () {
      expect(
        () => StrokeData.fromJson({
          'index': 0,
          'path': 'M 0 0 L 1 1',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('StrokeCharacter', () {
    test('parses full valid fixture JSON', () {
      final sc = StrokeCharacter.fromJson(validJson());
      expect(sc.character, '一');
      expect(sc.locale, 'ja');
      expect(sc.source, 'fixture');
      expect(sc.viewBox, [0, 0, 1024, 1024]);
      expect(sc.strokeCount, 1);
      expect(sc.strokes.first.path,
          'M 100 512 L 924 512 L 924 552 L 100 552 Z');
      expect(sc.strokes.first.median.length, 2);
      expect(sc.strokes.first.median[0].x, 100);
      expect(sc.strokes.first.median[0].y, 532);
    });

    test('round-trips through toJson', () {
      final original = StrokeCharacter.fromJson(validJson());
      final roundTrip = StrokeCharacter.fromJson(original.toJson());
      expect(roundTrip.character, original.character);
      expect(roundTrip.locale, original.locale);
      expect(roundTrip.source, original.source);
      expect(roundTrip.viewBox, original.viewBox);
      expect(roundTrip.strokeCount, original.strokeCount);
      expect(roundTrip.strokes.first.path, original.strokes.first.path);
    });

    test('throws on empty strokes array', () {
      final json = validJson()..['strokes'] = [];
      expect(
        () => StrokeCharacter.fromJson(json),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('non-empty "strokes"'),
        )),
      );
    });

    test('throws on missing character', () {
      final json = validJson()..remove('character');
      expect(
        () => StrokeCharacter.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on missing locale', () {
      final json = validJson()..remove('locale');
      expect(
        () => StrokeCharacter.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on missing source', () {
      final json = validJson()..remove('source');
      expect(
        () => StrokeCharacter.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on invalid viewBox (3 values)', () {
      final json = validJson()..['viewBox'] = [0, 0, 1024];
      expect(
        () => StrokeCharacter.fromJson(json),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('exactly 4 values'),
        )),
      );
    });

    test('throws on out-of-order stroke indexes', () {
      final json = validJson();
      json['strokes'] = [
        {
          'index': 1,
          'path': 'M 0 0 L 1 1',
          'median': [
            [0, 0],
            [1, 1],
          ],
        },
        {
          'index': 0,
          'path': 'M 2 2 L 3 3',
          'median': [
            [2, 2],
            [3, 3],
          ],
        },
      ];
      expect(
        () => StrokeCharacter.fromJson(json),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Stroke index out of order'),
        )),
      );
    });

    test('parses multi-stroke character (日)', () {
      final json = {
        'character': '日',
        'locale': 'ja',
        'source': 'fixture',
        'viewBox': [0, 0, 1024, 1024],
        'strokes': [
          {
            'index': 0,
            'path': 'M 312 162 L 312 862',
            'median': [
              [312, 162],
              [312, 862],
            ],
          },
          {
            'index': 1,
            'path': 'M 312 162 L 712 162',
            'median': [
              [312, 162],
              [712, 162],
            ],
          },
          {
            'index': 2,
            'path': 'M 712 162 L 712 862',
            'median': [
              [712, 162],
              [712, 862],
            ],
          },
          {
            'index': 3,
            'path': 'M 312 512 L 712 512',
            'median': [
              [312, 512],
              [712, 512],
            ],
          },
        ],
      };
      final sc = StrokeCharacter.fromJson(json);
      expect(sc.strokeCount, 4);
      expect(sc.strokes[2].index, 2);
    });

    test('fromDbRow parses data_json column', () {
      final row = {
        'id': 'ja_一',
        'character': '一',
        'locale': 'ja',
        'source': 'fixture',
        'stroke_count': 1,
        'view_box': '0 0 1024 1024',
        'data_json':
            '{"character":"一","locale":"ja","source":"fixture","viewBox":[0,0,1024,1024],"strokes":[{"index":0,"path":"M 100 512 L 924 512","median":[[100,532],[924,532]],"type":null,"component":null}]}',
      };
      final sc = StrokeCharacter.fromDbRow(row);
      expect(sc.character, '一');
      expect(sc.locale, 'ja');
      expect(sc.strokeCount, 1);
    });
  });
}
