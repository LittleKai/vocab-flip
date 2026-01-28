import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// REST API client for Firestore - used on Windows where native SDK crashes
class FirestoreRestClient {
  static final FirestoreRestClient _instance = FirestoreRestClient._internal();
  factory FirestoreRestClient() => _instance;
  FirestoreRestClient._internal();

  static const String _projectId = 'vocal-flip';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';
  static const String _apiKey = 'AIzaSyD_nazGJzlQrUSPmsTWZmGDp0Ey7pD6-Rc';

  final FirebaseService _authService = FirebaseService();

  /// Check if we should use REST API (Windows) or native SDK
  static bool get shouldUseRest => !kIsWeb && Platform.isWindows;

  /// Get auth headers with Firebase ID token
  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requireAuth) {
      final token = await _authService.getIdToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Build URL with API key for unauthenticated requests
  String _buildUrl(String path, {Map<String, String>? queryParams}) {
    final params = <String, String>{'key': _apiKey, ...?queryParams};
    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$_baseUrl/$path?$queryString';
  }

  // ============ Document Operations ============

  /// Get a single document
  Future<Map<String, dynamic>?> getDocument(String collectionPath, String documentId) async {
    try {
      final url = _buildUrl('$collectionPath/$documentId');
      final response = await http.get(Uri.parse(url), headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDocument(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('FirestoreRest: getDocument error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('FirestoreRest: getDocument exception: $e');
      return null;
    }
  }

  /// Get all documents in a collection
  Future<List<Map<String, dynamic>>> getCollection(
    String collectionPath, {
    List<QueryFilter>? where,
    List<OrderBy>? orderBy,
    int? limit,
    String? pageToken,
  }) async {
    try {
      // Use structured query for filtering
      if (where != null && where.isNotEmpty) {
        return _runStructuredQuery(collectionPath, where: where, orderBy: orderBy, limit: limit);
      }

      // Simple list for no filters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['pageSize'] = limit.toString();
      if (pageToken != null) queryParams['pageToken'] = pageToken;

      final url = _buildUrl(collectionPath, queryParams: queryParams);
      final response = await http.get(Uri.parse(url), headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>? ?? [];
        return documents.map((doc) => _parseDocument(doc)).whereType<Map<String, dynamic>>().toList();
      } else {
        debugPrint('FirestoreRest: getCollection error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('FirestoreRest: getCollection exception: $e');
      return [];
    }
  }

  /// Run a structured query with filters
  Future<List<Map<String, dynamic>>> _runStructuredQuery(
    String collectionPath, {
    List<QueryFilter>? where,
    List<OrderBy>? orderBy,
    int? limit,
  }) async {
    try {
      final collectionId = collectionPath.split('/').last;
      final parentPath = collectionPath.contains('/')
          ? collectionPath.substring(0, collectionPath.lastIndexOf('/'))
          : null;

      // Build structuredQuery with explicit types to avoid Dart type inference issues
      final structuredQuery = <String, dynamic>{
        'from': <Map<String, dynamic>>[
          <String, dynamic>{'collectionId': collectionId}
        ],
      };

      // Add filters
      if (where != null && where.isNotEmpty) {
        if (where.length == 1) {
          structuredQuery['where'] = _buildFilter(where.first);
        } else {
          structuredQuery['where'] = <String, dynamic>{
            'compositeFilter': <String, dynamic>{
              'op': 'AND',
              'filters': where.map((f) => _buildFilter(f)).toList(),
            }
          };
        }
      }

      // Add orderBy
      if (orderBy != null && orderBy.isNotEmpty) {
        structuredQuery['orderBy'] = orderBy
            .map<Map<String, dynamic>>((o) => <String, dynamic>{
                  'field': <String, dynamic>{'fieldPath': o.field},
                  'direction': o.descending ? 'DESCENDING' : 'ASCENDING',
                })
            .toList();
      }

      // Add limit
      if (limit != null) {
        structuredQuery['limit'] = limit;
      }

      final query = <String, dynamic>{'structuredQuery': structuredQuery};

      final baseQueryUrl = parentPath != null
          ? 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$parentPath:runQuery?key=$_apiKey'
          : 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents:runQuery?key=$_apiKey';

      final response = await http.post(
        Uri.parse(baseQueryUrl),
        headers: await _getHeaders(),
        body: json.encode(query),
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List<dynamic>;
        return results
            .where((r) => r['document'] != null)
            .map((r) => _parseDocument(r['document']))
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        debugPrint('FirestoreRest: structuredQuery error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('FirestoreRest: structuredQuery exception: $e');
      return [];
    }
  }

  Map<String, dynamic> _buildFilter(QueryFilter filter) {
    return {
      'fieldFilter': {
        'field': {'fieldPath': filter.field},
        'op': _getOperator(filter.operator),
        'value': _toFirestoreValue(filter.value),
      }
    };
  }

  String _getOperator(FilterOperator op) {
    switch (op) {
      case FilterOperator.equal:
        return 'EQUAL';
      case FilterOperator.notEqual:
        return 'NOT_EQUAL';
      case FilterOperator.lessThan:
        return 'LESS_THAN';
      case FilterOperator.lessThanOrEqual:
        return 'LESS_THAN_OR_EQUAL';
      case FilterOperator.greaterThan:
        return 'GREATER_THAN';
      case FilterOperator.greaterThanOrEqual:
        return 'GREATER_THAN_OR_EQUAL';
      case FilterOperator.arrayContains:
        return 'ARRAY_CONTAINS';
      case FilterOperator.arrayContainsAny:
        return 'ARRAY_CONTAINS_ANY';
      case FilterOperator.inArray:
        return 'IN';
      case FilterOperator.notIn:
        return 'NOT_IN';
    }
  }

  /// Create a new document
  Future<Map<String, dynamic>?> createDocument(
    String collectionPath,
    Map<String, dynamic> data, {
    String? documentId,
  }) async {
    try {
      final firestoreData = _toFirestoreDocument(data);
      String url;

      if (documentId != null) {
        url = _buildUrl('$collectionPath?documentId=$documentId');
      } else {
        url = _buildUrl(collectionPath);
      }

      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode({'fields': firestoreData}),
      );

      if (response.statusCode == 200) {
        return _parseDocument(json.decode(response.body));
      } else {
        debugPrint('FirestoreRest: createDocument error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('FirestoreRest: createDocument exception: $e');
      return null;
    }
  }

  /// Update a document
  Future<bool> updateDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final firestoreData = _toFirestoreDocument(data);
      final updateMask = data.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
      final url = '$_baseUrl/$collectionPath/$documentId?$updateMask&key=$_apiKey';

      final response = await http.patch(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode({'fields': firestoreData}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('FirestoreRest: updateDocument error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('FirestoreRest: updateDocument exception: $e');
      return false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(String collectionPath, String documentId) async {
    try {
      final url = _buildUrl('$collectionPath/$documentId');
      final response = await http.delete(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: true),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('FirestoreRest: deleteDocument exception: $e');
      return false;
    }
  }

  /// Set a document (create or overwrite)
  Future<bool> setDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      final firestoreData = _toFirestoreDocument(data);
      String url = '$_baseUrl/$collectionPath/$documentId?key=$_apiKey';

      if (merge) {
        final updateMask = data.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
        url = '$url&$updateMask';
      }

      final response = await http.patch(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode({'fields': firestoreData}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('FirestoreRest: setDocument error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('FirestoreRest: setDocument exception: $e');
      return false;
    }
  }

  // ============ Batch Operations ============

  /// Execute batch write operations
  Future<bool> batchWrite(List<BatchOperation> operations) async {
    try {
      final writes = operations.map((op) {
        final documentPath = 'projects/$_projectId/databases/(default)/documents/${op.collectionPath}/${op.documentId}';

        switch (op.type) {
          case BatchOperationType.set:
            return {
              'update': {
                'name': documentPath,
                'fields': _toFirestoreDocument(op.data!),
              }
            };
          case BatchOperationType.update:
            return {
              'update': {
                'name': documentPath,
                'fields': _toFirestoreDocument(op.data!),
              },
              'updateMask': {
                'fieldPaths': op.data!.keys.toList(),
              }
            };
          case BatchOperationType.delete:
            return {
              'delete': documentPath,
            };
        }
      }).toList();

      final url = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents:batchWrite?key=$_apiKey';
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode({'writes': writes}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('FirestoreRest: batchWrite error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('FirestoreRest: batchWrite exception: $e');
      return false;
    }
  }

  // ============ Data Conversion ============

  /// Parse Firestore REST document to Dart map
  Map<String, dynamic>? _parseDocument(Map<String, dynamic> doc) {
    if (!doc.containsKey('fields')) return null;

    final fields = doc['fields'] as Map<String, dynamic>;
    final result = <String, dynamic>{};

    // Extract document ID from name
    if (doc.containsKey('name')) {
      final name = doc['name'] as String;
      result['id'] = name.split('/').last;
    }

    for (final entry in fields.entries) {
      result[entry.key] = _parseValue(entry.value as Map<String, dynamic>);
    }

    return result;
  }

  /// Parse a Firestore value
  dynamic _parseValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) {
      return value['stringValue'];
    } else if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'].toString());
    } else if (value.containsKey('doubleValue')) {
      return value['doubleValue'];
    } else if (value.containsKey('booleanValue')) {
      return value['booleanValue'];
    } else if (value.containsKey('nullValue')) {
      return null;
    } else if (value.containsKey('timestampValue')) {
      return DateTime.parse(value['timestampValue']);
    } else if (value.containsKey('arrayValue')) {
      final array = value['arrayValue']['values'] as List<dynamic>? ?? [];
      return array.map((v) => _parseValue(v as Map<String, dynamic>)).toList();
    } else if (value.containsKey('mapValue')) {
      final fields = value['mapValue']['fields'] as Map<String, dynamic>? ?? {};
      final result = <String, dynamic>{};
      for (final entry in fields.entries) {
        result[entry.key] = _parseValue(entry.value as Map<String, dynamic>);
      }
      return result;
    } else if (value.containsKey('referenceValue')) {
      return value['referenceValue'];
    } else if (value.containsKey('geoPointValue')) {
      return value['geoPointValue'];
    }
    return null;
  }

  /// Convert Dart map to Firestore REST document format
  Map<String, dynamic> _toFirestoreDocument(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      // Skip 'id' field as it's metadata
      if (entry.key == 'id') continue;
      result[entry.key] = _toFirestoreValue(entry.value);
    }
    return result;
  }

  /// Convert a Dart value to Firestore format
  Map<String, dynamic> _toFirestoreValue(dynamic value) {
    if (value == null) {
      return {'nullValue': null};
    } else if (value is String) {
      return {'stringValue': value};
    } else if (value is int) {
      return {'integerValue': value.toString()};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    } else if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((v) => _toFirestoreValue(v)).toList(),
        }
      };
    } else if (value is Map) {
      return {
        'mapValue': {
          'fields': Map.fromEntries(
            value.entries.map((e) => MapEntry(e.key.toString(), _toFirestoreValue(e.value))),
          ),
        }
      };
    } else if (value is ServerTimestamp) {
      return {'timestampValue': DateTime.now().toUtc().toIso8601String()};
    } else if (value is FieldIncrement) {
      // Note: Field transforms need special handling in batch operations
      return {'integerValue': value.incrementBy.toString()};
    }
    return {'stringValue': value.toString()};
  }
}

// ============ Helper Classes ============

enum FilterOperator {
  equal,
  notEqual,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  arrayContains,
  arrayContainsAny,
  inArray,
  notIn,
}

class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  QueryFilter(this.field, this.operator, this.value);

  factory QueryFilter.isEqualTo(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.equal, value);

  factory QueryFilter.isGreaterThan(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.greaterThan, value);

  factory QueryFilter.isLessThan(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.lessThan, value);

  factory QueryFilter.arrayContains(String field, dynamic value) =>
      QueryFilter(field, FilterOperator.arrayContains, value);
}

class OrderBy {
  final String field;
  final bool descending;

  OrderBy(this.field, {this.descending = false});
}

enum BatchOperationType { set, update, delete }

class BatchOperation {
  final BatchOperationType type;
  final String collectionPath;
  final String documentId;
  final Map<String, dynamic>? data;

  BatchOperation.set(this.collectionPath, this.documentId, this.data) : type = BatchOperationType.set;
  BatchOperation.update(this.collectionPath, this.documentId, this.data) : type = BatchOperationType.update;
  BatchOperation.delete(this.collectionPath, this.documentId) : type = BatchOperationType.delete, data = null;
}

/// Marker class for server timestamp
class ServerTimestamp {
  const ServerTimestamp();
}

/// Marker class for field increment
class FieldIncrement {
  final int incrementBy;
  const FieldIncrement(this.incrementBy);
}
