import re

filepath = 'lib/data/remote/api/chinese_dict_api.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Completely remove online API logic from lookup
old_lookup = '''      bool tryOnline = fetchMode == 'online' || fetchMode == 'both';
      bool tryOffline =
          (fetchMode == 'offline' || fetchMode == 'both') && !kIsWeb;

      debugPrint(
          '[ChineseDictApi] lookup flags - tryOnline: , tryOffline: ');

      ChineseDictResult? apiResult;
      if (tryOnline) {
        try {
          debugPrint(
              '[ChineseDictApi] lookup - Calling API /vocab/dictionary/chinese/lookup');
          final response = await _apiClient.dio.get(
              '/vocab/dictionary/chinese/lookup',
              queryParameters: {'word': searchWord});
          debugPrint(
              '[ChineseDictApi] lookup - API Response Status: ');
          if (response.data['success'] == true &&
              response.data['data'] != null) {
            final data = response.data['data'];
            final entry = ChineseDictEntry(
              id: data['wordId'] ?? 0,
              word: data['word'] ?? '',
              pinyin: data['pinyin'],
              hanViet: data['hanViet'],
              definition: data['definition'] ?? '',
            );
            debugPrint('[ChineseDictApi] Found (REST API): ');
            apiResult = _entryToResult(entry, dataSource: 'REST API');
          } else {
            debugPrint('[ChineseDictApi] API returned no valid data');
          }
        } catch (apiError) {
          debugPrint('[ChineseDictApi] API Error: ');
        }
      }

      ChineseDictResult? dbResult;
      if (tryOffline && apiResult == null) {
        debugPrint('[ChineseDictApi] lookup - Calling SQLite DB');
        final entry = await _dao.lookup(searchWord);
        if (entry == null) {
          debugPrint('[ChineseDictApi] No exact match found (Local DB)');
        } else {
          debugPrint('[ChineseDictApi] Found (Local DB): ');
          dbResult = _entryToResult(entry);
        }
      }

      // Prefer API result, fallback to DB
      return apiResult ?? dbResult;'''

new_lookup = '''      debugPrint('[ChineseDictApi] lookup - Calling SQLite DB');
      final entry = await _dao.lookup(searchWord);
      if (entry == null) {
        debugPrint('[ChineseDictApi] No exact match found (Local DB)');
        return null;
      } else {
        debugPrint('[ChineseDictApi] Found (Local DB): ');
        return _entryToResult(entry);
      }'''

content = content.replace(old_lookup, new_lookup)

old_search = '''      bool tryOnline = fetchMode == 'online' || fetchMode == 'both';
      bool tryOffline =
          (fetchMode == 'offline' || fetchMode == 'both') && !kIsWeb;

      debugPrint(
          '[ChineseDictApi] search flags - tryOnline: , tryOffline: ');

      List<ChineseDictResult> apiResults = [];
      if (tryOnline) {
        try {
          debugPrint(
              '[ChineseDictApi] search - Calling API /vocab/dictionary/chinese/search');
          final response = await _apiClient.dio.get(
              '/vocab/dictionary/chinese/search',
              queryParameters: {'query': searchQuery, 'limit': limit});
          debugPrint(
              '[ChineseDictApi] search - API Response Status: ');
          if (response.data['success'] == true &&
              response.data['data'] != null) {
            final items = response.data['data'] as List;
            final entries = items
                .map((data) => ChineseDictEntry(
                      id: data['wordId'] ?? 0,
                      word: data['word'] ?? '',
                      pinyin: data['pinyin'],
                      hanViet: data['hanViet'],
                      definition: data['definition'] ?? '',
                    ))
                .toList();
            debugPrint(
                '[ChineseDictApi] Found  results (REST API)');
            apiResults = entries
                .map((e) => _entryToResult(e, dataSource: 'REST API'))
                .toList();
          } else {
            debugPrint('[ChineseDictApi] API returned no valid data');
          }
        } catch (apiError) {
          debugPrint('[ChineseDictApi] API Error: ');
        }
      }

      List<ChineseDictResult> dbResults = [];
      if (tryOffline && apiResults.isEmpty) {
        debugPrint('[ChineseDictApi] search - Calling SQLite DB');
        final entries = await _dao.search(searchQuery, limit: limit);
        debugPrint(
            '[ChineseDictApi] Found  results (Local DB)');
        dbResults = entries.map((e) => _entryToResult(e)).toList();
      }

      // Combine and deduplicate
      if (fetchMode == 'both') {
        final Map<String, ChineseDictResult> combined = {};
        for (var r in dbResults) combined[r.word] = r; // DB first
        for (var r in apiResults)
          combined[r.word] = r; // API overrides DB if same word
        debugPrint('[ChineseDictApi] Combined results: ');
        return combined.values.toList();
      }

      return tryOnline && fetchMode == 'online' ? apiResults : dbResults;'''

new_search = '''      debugPrint('[ChineseDictApi] search - Calling SQLite DB');
      final entries = await _dao.search(searchQuery, limit: limit);
      debugPrint('[ChineseDictApi] Found  results (Local DB)');
      return entries.map((e) => _entryToResult(e)).toList();'''

content = content.replace(old_search, new_search)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
