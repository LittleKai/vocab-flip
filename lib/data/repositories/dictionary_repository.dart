import '../models/dictionary_result.dart';
import '../remote/api/free_dictionary_api.dart';
import '../remote/api/jisho_api.dart';
import '../../core/constants/supported_languages.dart';

class DictionaryRepository {
  final FreeDictionaryApi _freeDictionaryApi;
  final JishoApi _jishoApi;

  DictionaryRepository({
    FreeDictionaryApi? freeDictionaryApi,
    JishoApi? jishoApi,
  })  : _freeDictionaryApi = freeDictionaryApi ?? FreeDictionaryApi(),
        _jishoApi = jishoApi ?? JishoApi();

  Future<DictionaryResult?> lookup(String word, SupportedLanguage language) async {
    switch (language) {
      case SupportedLanguage.english:
        return await _freeDictionaryApi.lookup(word);
      case SupportedLanguage.japanese:
        final jishoResult = await _jishoApi.lookup(word);
        return jishoResult?.toDictionaryResult();
      case SupportedLanguage.chinese:
        // For Chinese, we would need a different API
        // For now, return null
        return null;
      case SupportedLanguage.vietnamese:
        // Vietnamese is typically the target language
        return null;
    }
  }

  Future<List<DictionaryResult>> search(String query, SupportedLanguage language) async {
    switch (language) {
      case SupportedLanguage.english:
        final result = await _freeDictionaryApi.lookup(query);
        return result != null ? [result] : [];
      case SupportedLanguage.japanese:
        final results = await _jishoApi.search(query);
        return results.map((r) => r.toDictionaryResult()).toList();
      default:
        return [];
    }
  }
}
