/// Utility class to convert Romaji to Hiragana/Katakana and between them
class RomajiConverter {
  RomajiConverter._();

  /// Hiragana to Katakana offset (カ - か = 96)
  static const int _kataHiraOffset = 0x60; // 96

  /// Map of romaji to hiragana
  static const Map<String, String> _romajiToHiragana = {
    // Vowels
    'a': 'あ', 'i': 'い', 'u': 'う', 'e': 'え', 'o': 'お',

    // K-row
    'ka': 'か', 'ki': 'き', 'ku': 'く', 'ke': 'け', 'ko': 'こ',
    'kya': 'きゃ', 'kyu': 'きゅ', 'kyo': 'きょ',

    // S-row
    'sa': 'さ', 'si': 'し', 'shi': 'し', 'su': 'す', 'se': 'せ', 'so': 'そ',
    'sha': 'しゃ', 'shu': 'しゅ', 'sho': 'しょ',
    'sya': 'しゃ', 'syu': 'しゅ', 'syo': 'しょ',

    // T-row
    'ta': 'た', 'ti': 'ち', 'chi': 'ち', 'tu': 'つ', 'tsu': 'つ', 'te': 'て', 'to': 'と',
    'cha': 'ちゃ', 'chu': 'ちゅ', 'cho': 'ちょ',
    'tya': 'ちゃ', 'tyu': 'ちゅ', 'tyo': 'ちょ',

    // N-row
    'na': 'な', 'ni': 'に', 'nu': 'ぬ', 'ne': 'ね', 'no': 'の',
    'nya': 'にゃ', 'nyu': 'にゅ', 'nyo': 'にょ',
    'n': 'ん', "n'": 'ん',

    // H-row
    'ha': 'は', 'hi': 'ひ', 'hu': 'ふ', 'fu': 'ふ', 'he': 'へ', 'ho': 'ほ',
    'hya': 'ひゃ', 'hyu': 'ひゅ', 'hyo': 'ひょ',

    // M-row
    'ma': 'ま', 'mi': 'み', 'mu': 'む', 'me': 'め', 'mo': 'も',
    'mya': 'みゃ', 'myu': 'みゅ', 'myo': 'みょ',

    // Y-row
    'ya': 'や', 'yu': 'ゆ', 'yo': 'よ',

    // R-row
    'ra': 'ら', 'ri': 'り', 'ru': 'る', 're': 'れ', 'ro': 'ろ',
    'rya': 'りゃ', 'ryu': 'りゅ', 'ryo': 'りょ',

    // W-row
    'wa': 'わ', 'wi': 'ゐ', 'we': 'ゑ', 'wo': 'を',

    // G-row (voiced K)
    'ga': 'が', 'gi': 'ぎ', 'gu': 'ぐ', 'ge': 'げ', 'go': 'ご',
    'gya': 'ぎゃ', 'gyu': 'ぎゅ', 'gyo': 'ぎょ',

    // Z-row (voiced S)
    'za': 'ざ', 'zi': 'じ', 'ji': 'じ', 'zu': 'ず', 'ze': 'ぜ', 'zo': 'ぞ',
    'ja': 'じゃ', 'ju': 'じゅ', 'jo': 'じょ',
    'jya': 'じゃ', 'jyu': 'じゅ', 'jyo': 'じょ',
    'zya': 'じゃ', 'zyu': 'じゅ', 'zyo': 'じょ',

    // D-row (voiced T)
    'da': 'だ', 'di': 'ぢ', 'du': 'づ', 'de': 'で', 'do': 'ど',
    'dya': 'ぢゃ', 'dyu': 'ぢゅ', 'dyo': 'ぢょ',

    // B-row (voiced H)
    'ba': 'ば', 'bi': 'び', 'bu': 'ぶ', 'be': 'べ', 'bo': 'ぼ',
    'bya': 'びゃ', 'byu': 'びゅ', 'byo': 'びょ',

    // P-row (half-voiced H)
    'pa': 'ぱ', 'pi': 'ぴ', 'pu': 'ぷ', 'pe': 'ぺ', 'po': 'ぽ',
    'pya': 'ぴゃ', 'pyu': 'ぴゅ', 'pyo': 'ぴょ',

    // Special / Extended sounds
    'vu': 'ゔ',
    'fa': 'ふぁ', 'fi': 'ふぃ', 'fe': 'ふぇ', 'fo': 'ふぉ',
    // Note: 'ti', 'di', 'tu', 'du' are defined in T-row and D-row with standard readings

    // Small kana
    'xa': 'ぁ', 'xi': 'ぃ', 'xu': 'ぅ', 'xe': 'ぇ', 'xo': 'ぉ',
    'xya': 'ゃ', 'xyu': 'ゅ', 'xyo': 'ょ',
    'xtu': 'っ', 'xtsu': 'っ', 'xwa': 'ゎ',
    'la': 'ぁ', 'li': 'ぃ', 'lu': 'ぅ', 'le': 'ぇ', 'lo': 'ぉ',
    'lya': 'ゃ', 'lyu': 'ゅ', 'lyo': 'ょ',
    'ltu': 'っ', 'ltsu': 'っ',

    // Punctuation
    '-': 'ー',
    '.': '。',
    ',': '、',
  };

  /// Sorted keys by length (longest first) for proper matching
  static final List<String> _sortedKeys = _romajiToHiragana.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  /// Convert romaji string to hiragana
  ///
  /// Example:
  /// ```dart
  /// RomajiConverter.toHiragana('konnichiwa') // returns 'こんにちわ'
  /// RomajiConverter.toHiragana('toukyou') // returns 'とうきょう'
  /// ```
  static String toHiragana(String romaji) {
    if (romaji.isEmpty) return '';

    final input = romaji.toLowerCase();
    final result = StringBuffer();
    var i = 0;

    while (i < input.length) {
      var matched = false;

      // Handle double consonants (small tsu)
      if (i + 1 < input.length) {
        final current = input[i];
        final next = input[i + 1];
        // Check if it's a double consonant (not 'n' followed by vowel or 'y')
        if (current == next &&
            _isConsonant(current) &&
            current != 'n' &&
            current != 'a' && current != 'i' && current != 'u' &&
            current != 'e' && current != 'o') {
          result.write('っ');
          i++;
          continue;
        }
      }

      // Try to match longest sequence first
      for (final key in _sortedKeys) {
        if (i + key.length <= input.length) {
          final substring = input.substring(i, i + key.length);
          if (substring == key) {
            // Special handling for 'n' before vowel or 'y'
            if (key == 'n' && i + 1 < input.length) {
              final nextChar = input[i + 1];
              if (_isVowel(nextChar) || nextChar == 'y') {
                continue; // Don't match single 'n' before vowel/y
              }
            }
            result.write(_romajiToHiragana[key]);
            i += key.length;
            matched = true;
            break;
          }
        }
      }

      // If no match, keep the original character
      if (!matched) {
        result.write(input[i]);
        i++;
      }
    }

    return result.toString();
  }

  /// Check if character is a vowel
  static bool _isVowel(String char) {
    return 'aiueo'.contains(char);
  }

  /// Check if character is a consonant
  static bool _isConsonant(String char) {
    return 'bcdfghjklmnpqrstvwxyz'.contains(char);
  }

  /// Check if the string contains only romaji characters
  static bool isRomaji(String text) {
    if (text.isEmpty) return false;
    // Only contains a-z, A-Z, and common punctuation
    return RegExp(r"^[a-zA-Z\-'.,\s]+$").hasMatch(text);
  }

  /// Check if the string contains Japanese characters (hiragana, katakana, kanji)
  static bool isJapanese(String text) {
    if (text.isEmpty) return false;
    // Hiragana: 3040-309F, Katakana: 30A0-30FF, Kanji: 4E00-9FFF
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(text);
  }

  /// Check if string contains hiragana
  static bool containsHiragana(String text) {
    return RegExp(r'[\u3040-\u309F]').hasMatch(text);
  }

  /// Check if string contains katakana
  static bool containsKatakana(String text) {
    return RegExp(r'[\u30A0-\u30FF]').hasMatch(text);
  }

  /// Convert romaji string to katakana
  ///
  /// Example:
  /// ```dart
  /// RomajiConverter.toKatakana('konnichiwa') // returns 'コンニチワ'
  /// ```
  static String toKatakana(String romaji) {
    final hiragana = toHiragana(romaji);
    return hiraganaToKatakana(hiragana);
  }

  /// Convert hiragana to katakana
  ///
  /// Example:
  /// ```dart
  /// RomajiConverter.hiraganaToKatakana('こんにちは') // returns 'コンニチハ'
  /// ```
  static String hiraganaToKatakana(String text) {
    final buffer = StringBuffer();
    for (final char in text.runes) {
      // Hiragana range: 0x3041 (ぁ) to 0x3096 (ゖ)
      if (char >= 0x3041 && char <= 0x3096) {
        // Convert to katakana by adding offset
        buffer.writeCharCode(char + _kataHiraOffset);
      } else if (char == 0x3099) {
        // Combining voiced mark → keep as is (used with katakana too)
        buffer.writeCharCode(char);
      } else if (char == 0x309A) {
        // Combining semi-voiced mark → keep as is
        buffer.writeCharCode(char);
      } else {
        // Keep other characters as is
        buffer.writeCharCode(char);
      }
    }
    return buffer.toString();
  }

  /// Convert katakana to hiragana
  ///
  /// Example:
  /// ```dart
  /// RomajiConverter.katakanaToHiragana('コンニチハ') // returns 'こんにちは'
  /// ```
  static String katakanaToHiragana(String text) {
    final buffer = StringBuffer();
    for (final char in text.runes) {
      // Katakana range: 0x30A1 (ァ) to 0x30F6 (ヶ)
      if (char >= 0x30A1 && char <= 0x30F6) {
        // Convert to hiragana by subtracting offset
        buffer.writeCharCode(char - _kataHiraOffset);
      } else if (char == 0x30FC) {
        // Katakana prolonged sound mark ー → keep as is (no hiragana equivalent)
        buffer.writeCharCode(char);
      } else {
        // Keep other characters as is
        buffer.writeCharCode(char);
      }
    }
    return buffer.toString();
  }

  /// Smart convert: converts text to target kana type
  /// - Romaji → target kana
  /// - Hiragana ↔ Katakana
  static String convertToKana(String text, {required bool toKatakana}) {
    if (text.isEmpty) return '';

    // If it's romaji, convert directly
    if (isRomaji(text)) {
      return toKatakana ? RomajiConverter.toKatakana(text) : toHiragana(text);
    }

    // If it contains Japanese, convert between kana types
    if (toKatakana) {
      return hiraganaToKatakana(text);
    } else {
      return katakanaToHiragana(text);
    }
  }
}
