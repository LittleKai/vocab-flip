import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../local/database/stroke_data_dao.dart';
import '../models/stroke_character.dart';

/// Repository wrapping [StrokeDataDao] with locale fallback logic and online CDN backup.
///
/// Locale fallback order:
/// - `ja` → `ja`, then `ja-kana`
/// - `zh` → `zh-Hans`, then `zh-Hant`
/// - Other languages (en, vi, etc.) → `null` immediately
class StrokeDataRepository {
  final StrokeDataDao _dao;

  // In-memory cache for online/web-fetched stroke characters to avoid redundant requests.
  final Map<String, StrokeCharacter> _onlineCache = {};

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
  /// Falls back to Hanzi Writer CDN on web or if not found in offline DB.
  Future<StrokeCharacter?> lookupCharacter(
    String character,
    String sourceLanguage,
  ) async {
    final fallbacks = _localeFallbacks(sourceLanguage);
    if (fallbacks == null) return null;

    // 1. Check in-memory cache first (works across all platforms)
    for (final locale in fallbacks) {
      final cached = _onlineCache['${character}_$locale'];
      if (cached != null) return cached;
    }

    // 2. On native platforms, check the local database first
    if (!kIsWeb) {
      for (final locale in fallbacks) {
        try {
          final result = await _dao.lookup(character: character, locale: locale);
          if (result != null) return result;
        } catch (e) {
          debugPrint('[stroke_data_repository] DAO lookup failed for $character ($locale): $e');
        }
      }
    }

    // 3. Fallback: try fetching online from Hanzi Writer CDNs
    for (final locale in fallbacks) {
      final result = await _lookupCharacterOnline(character, locale);
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

    // Check cache first
    for (final locale in fallbacks) {
      if (_onlineCache.containsKey('${character}_$locale')) return true;
    }

    // Try DB next (on native)
    if (!kIsWeb) {
      for (final locale in fallbacks) {
        if (await _dao.exists(character: character, locale: locale)) return true;
      }
    }

    // Otherwise do a lookup (which will fetch and cache if found)
    final sc = await lookupCharacter(character, sourceLanguage);
    return sc != null;
  }

  /// Fetch character stroke data from Hanzi Writer CDNs.
  Future<StrokeCharacter?> _lookupCharacterOnline(
    String character,
    String locale,
  ) async {
    final cacheKey = '${character}_$locale';
    if (_onlineCache.containsKey(cacheKey)) {
      return _onlineCache[cacheKey];
    }

    try {
      final String url;
      // ja-kana characters are hiragana/katakana. Hanzi Writer JP database does not typically
      // contain kana, but we construct the URL just in case, or default to animCJK-like CDN if needed.
      if (locale == 'ja' || locale == 'ja-kana') {
        url = 'https://cdn.jsdelivr.net/npm/hanzi-writer-data-jp@0/$character.json';
      } else {
        url = 'https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0/$character.json';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final strokes = decoded['strokes'] as List<dynamic>?;
          final medians = decoded['medians'] as List<dynamic>?;

          if (strokes != null && medians != null && strokes.length == medians.length) {
            final formattedStrokes = [];
            for (int i = 0; i < strokes.length; i++) {
              final pathStr = strokes[i] as String;
              final medianArr = medians[i] as List<dynamic>;

              final formattedMedians = [];
              for (final point in medianArr) {
                final p = point as List<dynamic>;
                formattedMedians.add([p[0].toInt(), p[1].toInt()]);
              }

              formattedStrokes.add([
                pathStr,
                formattedMedians,
              ]);
            }

            final sc = StrokeCharacter.fromJson({
              'character': character,
              'locale': locale,
              'source': 'hanzi-writer-cdn',
              'viewBox': [0, 0, 1024, 1024],
              'strokes': formattedStrokes,
            });

            _onlineCache[cacheKey] = sc;
            return sc;
          }
        }
      }
    } catch (e) {
      debugPrint('[stroke_data_repository] Error fetching online for $character ($locale): $e');
    }
    return null;
  }
}
