import re

filepath = 'lib/data/remote/api/chinese_dict_api.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'package:lpinyin/lpinyin.dart' not in content:
    content = content.replace("import '../../api/api_client.dart';", "import '../../api/api_client.dart';\nimport 'package:lpinyin/lpinyin.dart';")

# Convert word in lookup
old_lookup = '''  Future<ChineseDictResult?> lookup(String word, {String fetchMode = 'both'}) async {
    debugPrint('[ChineseDictApi] lookup: "" (fetchMode: )');'''
new_lookup = '''  Future<ChineseDictResult?> lookup(String word, {String fetchMode = 'both'}) async {
    final String searchWord = ChineseHelper.convertToSimplifiedChinese(word);
    debugPrint('[ChineseDictApi] lookup: "" -> "" (fetchMode: )');'''
content = content.replace(old_lookup, new_lookup)

# Replace remaining 'word' with 'searchWord'
old_lookup_body = '''          final response = await _apiClient.dio.get('/vocab/dictionary/chinese/lookup', queryParameters: {'word': word});'''
new_lookup_body = '''          final response = await _apiClient.dio.get('/vocab/dictionary/chinese/lookup', queryParameters: {'word': searchWord});'''
content = content.replace(old_lookup_body, new_lookup_body)

old_lookup_db = '''        final entry = await _dao.lookup(word);'''
new_lookup_db = '''        final entry = await _dao.lookup(searchWord);'''
content = content.replace(old_lookup_db, new_lookup_db)

# Convert query in search
old_search = '''  Future<List<ChineseDictResult>> search(String query, {int limit = 10, String fetchMode = 'both'}) async {
    debugPrint('[ChineseDictApi] search: "" (limit: , fetchMode: )');'''
new_search = '''  Future<List<ChineseDictResult>> search(String query, {int limit = 10, String fetchMode = 'both'}) async {
    final String searchQuery = ChineseHelper.convertToSimplifiedChinese(query);
    debugPrint('[ChineseDictApi] search: "" -> "" (limit: , fetchMode: )');'''
content = content.replace(old_search, new_search)

old_search_body = '''          final response = await _apiClient.dio.get('/vocab/dictionary/chinese/search', queryParameters: {'query': query, 'limit': limit});'''
new_search_body = '''          final response = await _apiClient.dio.get('/vocab/dictionary/chinese/search', queryParameters: {'query': searchQuery, 'limit': limit});'''
content = content.replace(old_search_body, new_search_body)

old_search_db = '''        final dbEntries = await _dao.search(query, limit: limit);'''
new_search_db = '''        final dbEntries = await _dao.search(searchQuery, limit: limit);'''
content = content.replace(old_search_db, new_search_db)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
