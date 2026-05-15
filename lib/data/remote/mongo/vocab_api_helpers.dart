import 'package:flutter/foundation.dart';

Map<String, dynamic> normalizeApiMap(dynamic value) {
  if (value is! Map) return <String, dynamic>{};

  final map = Map<String, dynamic>.from(value);
  final normalized = <String, dynamic>{};

  for (final entry in map.entries) {
    normalized[_toSnakeCase(entry.key)] = entry.value;
  }

  final mongoId = normalized['_id'];
  if (!normalized.containsKey('id') && mongoId != null) {
    normalized['id'] = mongoId.toString();
  }

  return normalized;
}

Map<String, dynamic>? unwrapApiMap(dynamic responseData) {
  final data = _unwrapApiData(responseData);
  if (data is Map) return normalizeApiMap(data);
  return null;
}

List<Map<String, dynamic>> unwrapApiList(dynamic responseData) {
  final data = _unwrapApiData(responseData);
  final list = _findList(data);
  if (list == null) return const [];
  return list.map(normalizeApiMap).toList();
}

dynamic _unwrapApiData(dynamic responseData) {
  if (responseData is Map) {
    final map = Map<String, dynamic>.from(responseData);
    if (map.containsKey('data')) {
      return map['data'];
    }
    return map;
  }
  return responseData;
}

List<dynamic>? _findList(dynamic data) {
  if (data is List) return data;
  if (data is! Map) return null;

  const listKeys = [
    'items',
    'docs',
    'results',
    'decks',
    'flashcards',
    'ratings',
    'links',
    'notifications',
    'categories',
    'data',
  ];

  final map = Map<String, dynamic>.from(data);
  for (final key in listKeys) {
    final value = map[key];
    if (value is List) return value;
  }
  return null;
}

String _toSnakeCase(String key) {
  return key.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match.group(1)}_${match.group(2)}',
  ).toLowerCase();
}

void logVocabApiError(String scope, Object error) {
  debugPrint('Vocab API $scope error: $error');
}
