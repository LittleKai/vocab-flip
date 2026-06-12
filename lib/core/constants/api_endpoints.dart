class ApiEndpoints {
  ApiEndpoints._();

  // Free Dictionary API (English - English definitions)
  static const String freeDictionaryBase = 'https://api.dictionaryapi.dev/api/v2/entries';
  static String freeDictionary(String word) => '$freeDictionaryBase/en/$word';

  // Jisho API (Japanese - English definitions)
  static const String jishoBase = 'https://jisho.org/api/v1/search/words';
  static String jisho(String word) => '$jishoBase?keyword=$word';

  // Laban Dictionary API (English - Vietnamese)
  static const String labanBase = 'https://dict.laban.vn/ajax/find';
  static String laban(String word) =>
      '$labanBase?type=1&query=${Uri.encodeComponent(word)}';

  // Mazii API (Japanese - Vietnamese) - POST API
  static const String maziiSearch = 'https://mazii.net/api/search';

  // Mazii legacy search API (GET)
  static const String maziiBase = 'https://mazii.net/api/search';
  static String mazii(String word, {int limit = 10, int page = 1}) =>
      '$maziiBase/${Uri.encodeComponent(word)}/$limit/$page';

  // Mazii word detail API
  static const String maziiDetailBase = 'https://mazii.net/api/javi';
  static String maziiDetail(int mobileId) => '$maziiDetailBase/$mobileId';

  // chineseDict API (Chinese - Vietnamese) - uses same backend as Mazii
  static const String chineseDictSearch = 'https://mazii.net/api/search';
  static const String chineseDictBase = 'https://mazii.net/api/search';
  static String chineseDict(String word, {int limit = 10, int page = 1}) =>
      '$chineseDictBase/${Uri.encodeComponent(word)}/$limit/$page';

  // chineseDict word detail API
  static const String chineseDictDetailBase = 'https://mazii.net/api/hanzivi';
  static String chineseDictDetail(int mobileId) => '$chineseDictDetailBase/$mobileId';

  // Google Translate (requires API key)
  static const String googleTranslateBase = 'https://translation.googleapis.com/language/translate/v2';
}
