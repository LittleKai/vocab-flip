import '../../models/dictionary_result.dart';

abstract class DictionaryApi {
  Future<DictionaryResult?> lookup(String word);
  Future<List<DictionaryResult>> search(String query);
}
