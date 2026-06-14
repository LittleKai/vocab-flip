import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/app_version.dart';

/// Service to fetch release information directly from a static JSON metadata file.
class UpdateApi {
  final String metadataUrl;
  final http.Client? _client;

  UpdateApi({
    required this.metadataUrl,
    http.Client? client,
  }) : _client = client;

  http.Client get client => _client ?? http.Client();

  /// Fetch the latest release metadata.
  Future<AppVersion?> getLatestRelease() async {
    try {
      final response = await client.get(
        Uri.parse(metadataUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'VocabFlip-App',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return AppVersion.fromJson(json);
      } else {
        debugPrint(
            'UpdateApi: Failed to fetch update metadata: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('UpdateApi: Error fetching update metadata: $e');
      return null;
    }
  }

  void dispose() {
    if (_client != null) {
      _client.close();
    }
  }
}
