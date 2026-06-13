import '../local/database/stroke_data_dao.dart';
import '../models/stroke_character.dart';

/// Repository wrapping [StrokeDataDao] with locale fallback logic.
///
/// Locale fallback order:
/// - `ja` → `ja`, then `ja-kana`
/// - `zh` → `zh-Hans`, then `zh-Hant`
/// - Other languages (en, vi, etc.) → `null` immediately
class StrokeDataRepository {
  final StrokeDataDao _dao;

  StrokeDataRepository(this._dao);

  /// Returns ordered locale keys to try for a given source language.
  static List<String>? _localeFallbacks(String sourceLanguage) {
    switch (sourceLanguage) {
      case 'ja':
        return const ['ja', 'ja-kana'];
      case 'zh':
        return const ['zh-Hans', 'zh-Hant'];
      default:
        return null;
    }
  }

  /// Look up stroke data for [character] in [sourceLanguage], trying locale
  /// fallbacks in order. Returns `null` for unsupported languages.
  Future<StrokeCharacter?> lookupCharacter(
    String character,
    String sourceLanguage,
  ) async {
    final fallbacks = _localeFallbacks(sourceLanguage);
    if (fallbacks == null) return null;

    for (final locale in fallbacks) {
      final result = await _dao.lookup(character: character, locale: locale);
      if (result != null) return result;
    }
    return null;
  }

  /// Check whether stroke data exists for [character] in [sourceLanguage],
  /// trying locale fallbacks in order.
  Future<bool> hasStrokeData(
    String character,
    String sourceLanguage,
  ) async {
    final fallbacks = _localeFallbacks(sourceLanguage);
    if (fallbacks == null) return false;

    for (final locale in fallbacks) {
      if (await _dao.exists(character: character, locale: locale)) return true;
    }
    return false;
  }
}
