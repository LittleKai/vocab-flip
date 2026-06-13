import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/stroke_character.dart';
import 'package:vocabflip/data/repositories/stroke_data_repository.dart';
import 'package:vocabflip/data/local/database/stroke_data_dao.dart';

/// A fake DAO that stores fixture data in-memory for repository tests.
class FakeStrokeDataDao extends StrokeDataDao {
  final Map<String, StrokeCharacter> _store = {};

  void addFixture(StrokeCharacter sc) {
    _store['${sc.character}_${sc.locale}'] = sc;
  }

  @override
  Future<void> init() async {}

  @override
  Future<StrokeCharacter?> lookup({
    required String character,
    required String locale,
  }) async {
    return _store['${character}_$locale'];
  }

  @override
  Future<bool> exists({
    required String character,
    required String locale,
  }) async {
    return _store.containsKey('${character}_$locale');
  }

  @override
  Future<void> close() async {
    _store.clear();
  }
}

StrokeCharacter _makeFixture(String character, String locale) {
  return StrokeCharacter(
    character: character,
    locale: locale,
    source: 'fixture',
    viewBox: const [0, 0, 1024, 1024],
    strokes: [
      const StrokeData(
        index: 0,
        path: 'M 0 0 L 100 100',
        median: [StrokePoint(0, 0), StrokePoint(100, 100)],
      ),
    ],
  );
}

void main() {
  late FakeStrokeDataDao fakeDao;
  late StrokeDataRepository repo;

  setUp(() {
    fakeDao = FakeStrokeDataDao();
    repo = StrokeDataRepository(fakeDao);
  });

  group('lookupCharacter', () {
    test('returns character with exact locale match (ja)', () async {
      fakeDao.addFixture(_makeFixture('一', 'ja'));
      final result = await repo.lookupCharacter('一', 'ja');
      expect(result, isNotNull);
      expect(result!.character, '一');
      expect(result.locale, 'ja');
    });

    test('returns character with exact locale match (zh-Hans)', () async {
      fakeDao.addFixture(_makeFixture('中', 'zh-Hans'));
      final result = await repo.lookupCharacter('中', 'zh');
      expect(result, isNotNull);
      expect(result!.character, '中');
      expect(result.locale, 'zh-Hans');
    });

    test('falls back to zh-Hant when zh-Hans not found', () async {
      fakeDao.addFixture(_makeFixture('中', 'zh-Hant'));
      final result = await repo.lookupCharacter('中', 'zh');
      expect(result, isNotNull);
      expect(result!.locale, 'zh-Hant');
    });

    test('prefers zh-Hans over zh-Hant', () async {
      fakeDao.addFixture(_makeFixture('中', 'zh-Hans'));
      fakeDao.addFixture(_makeFixture('中', 'zh-Hant'));
      final result = await repo.lookupCharacter('中', 'zh');
      expect(result, isNotNull);
      expect(result!.locale, 'zh-Hans');
    });

    test('falls back to ja-kana for Japanese', () async {
      fakeDao.addFixture(_makeFixture('あ', 'ja-kana'));
      final result = await repo.lookupCharacter('あ', 'ja');
      expect(result, isNotNull);
      expect(result!.locale, 'ja-kana');
    });

    test('prefers ja over ja-kana', () async {
      fakeDao.addFixture(_makeFixture('一', 'ja'));
      fakeDao.addFixture(_makeFixture('一', 'ja-kana'));
      final result = await repo.lookupCharacter('一', 'ja');
      expect(result!.locale, 'ja');
    });

    test('returns null for English source language', () async {
      final result = await repo.lookupCharacter('A', 'en');
      expect(result, isNull);
    });

    test('returns null for Vietnamese source language', () async {
      final result = await repo.lookupCharacter('A', 'vi');
      expect(result, isNull);
    });

    test('returns null when character not in any fallback locale', () async {
      final result = await repo.lookupCharacter('龍', 'ja');
      expect(result, isNull);
    });
  });

  group('hasStrokeData', () {
    test('returns true when data exists', () async {
      fakeDao.addFixture(_makeFixture('一', 'ja'));
      expect(await repo.hasStrokeData('一', 'ja'), isTrue);
    });

    test('returns true with zh fallback', () async {
      fakeDao.addFixture(_makeFixture('中', 'zh-Hans'));
      expect(await repo.hasStrokeData('中', 'zh'), isTrue);
    });

    test('returns false for unsupported language', () async {
      expect(await repo.hasStrokeData('hello', 'en'), isFalse);
    });

    test('returns false when character missing', () async {
      expect(await repo.hasStrokeData('龍', 'zh'), isFalse);
    });
  });
}
