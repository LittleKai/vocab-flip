import re

filepath = 'lib/data/remote/api/chinese_dict_api.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_offline_lookup = '''      ChineseDictResult? dbResult;
      if (tryOffline) {
        debugPrint('[ChineseDictApi] lookup - Calling SQLite DB');'''

new_offline_lookup = '''      ChineseDictResult? dbResult;
      if (tryOffline && apiResult == null) {
        debugPrint('[ChineseDictApi] lookup - Calling SQLite DB');'''

content = content.replace(old_offline_lookup, new_offline_lookup)

old_offline_search = '''      List<ChineseDictResult> dbResults = [];
      if (tryOffline) {
        debugPrint('[ChineseDictApi] search - Calling SQLite DB');'''

new_offline_search = '''      List<ChineseDictResult> dbResults = [];
      if (tryOffline && apiResults.isEmpty) {
        debugPrint('[ChineseDictApi] search - Calling SQLite DB');'''

content = content.replace(old_offline_search, new_offline_search)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
