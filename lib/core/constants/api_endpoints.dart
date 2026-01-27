class ApiEndpoints {
  ApiEndpoints._();

  // Free Dictionary API (English)
  static const String freeDictionaryBase = 'https://api.dictionaryapi.dev/api/v2/entries';
  static String freeDictionary(String word) => '$freeDictionaryBase/en/$word';

  // Jisho API (Japanese)
  static const String jishoBase = 'https://jisho.org/api/v1/search/words';
  static String jisho(String word) => '$jishoBase?keyword=$word';

  // Google Translate (requires API key)
  static const String googleTranslateBase = 'https://translation.googleapis.com/language/translate/v2';
}
