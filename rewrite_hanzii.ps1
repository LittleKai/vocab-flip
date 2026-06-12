$file = "lib/data/remote/api/hanzii_api.dart"
$content = Get-Content $file -Raw

$newContent = $content -replace "Future<HanziiResult\?> lookup\(String word\) async {", "Future<HanziiResult?> lookup(String word, {String fetchMode = 'both'}) async {"
$newContent = $newContent -replace "Future<List<HanziiResult>> search\(String query, {int limit = 10}\) async {", "Future<List<HanziiResult>> search(String query, {int limit = 10, String fetchMode = 'both'}) async {"

# Now replace the kIsWeb checks
$oldBody = "(?s)    try \{\s*if \(kIsWeb\) \{.*?return \[\];\s*\}"
$newBody = "    try {
      bool useOnline = false;
      if (fetchMode == 'online') {
        useOnline = true;
      } else if (fetchMode == 'offline') {
        useOnline = false;
      } else {
        useOnline = kIsWeb;
      }

      if (useOnline) {
        try {
          final response = await _apiClient.dio.get('/vocab/dictionary/chinese/search', queryParameters: {'query': query, 'limit': limit});
          if (response.data['success'] == true && response.data['data'] != null) {
            final items = response.data['data'] as List;
            final entries = items.map((data) => ChineseDictEntry(
              id: data['wordId'] ?? 0,
              word: data['word'] ?? '',
              pinyin: data['pinyin'],
              hanViet: data['hanViet'],
              definition: data['definition'] ?? '',
            )).toList();
            debugPrint('[HanziiApi] Found `${entries.length} results (Online)');
            return entries.map((e) => _entryToResult(e)).toList();
          }
        } catch (apiError) {
          debugPrint('[HanziiApi] API Error: $apiError');
          if (fetchMode == 'both' && !kIsWeb) {
             useOnline = false; 
          } else {
             return [];
          }
        }
      }
      
      if (!useOnline && !kIsWeb) {
        final entries = await _dao.search(query, limit: limit);
        debugPrint('[HanziiApi] Found `${entries.length} results (Local)');
        return entries.map((e) => _entryToResult(e)).toList();
      }
      return [];"

# But powershell regex replace is hard. I will just rewrite it in dart.
