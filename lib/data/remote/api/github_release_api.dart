import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/app_version.dart';

/// Service to fetch release information from a GitHub-compatible release API.
class GitHubReleaseApi {
  final String owner;
  final String repo;
  final String? metadataUrl;
  final http.Client? _client;

  GitHubReleaseApi({
    required this.owner,
    required this.repo,
    this.metadataUrl,
    http.Client? client,
  }) : _client = client;

  http.Client get client => _client ?? http.Client();

  /// GitHub API endpoint for latest release
  String get _latestReleaseUrl =>
      metadataUrl ??
      'https://api.github.com/repos/$owner/$repo/releases/latest';

  /// GitHub API endpoint for all releases
  String get _allReleasesUrl =>
      'https://api.github.com/repos/$owner/$repo/releases';

  /// Fetch the latest release metadata.
  Future<AppVersion?> getLatestRelease() async {
    try {
      final response = await client.get(
        Uri.parse(_latestReleaseUrl),
        headers: {
          'Accept': metadataUrl == null
              ? 'application/vnd.github.v3+json'
              : 'application/json',
          'User-Agent': 'VocabFlip-App',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AppVersion.fromGitHubRelease(json);
      } else if (response.statusCode == 404) {
        debugPrint('GitHubReleaseApi: No releases found');
        return null;
      } else {
        debugPrint(
            'GitHubReleaseApi: Failed to fetch release: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('GitHubReleaseApi: Error fetching release: $e');
      return null;
    }
  }

  /// Fetch all releases (useful for finding the correct Windows release)
  Future<List<AppVersion>> getAllReleases({int perPage = 10}) async {
    if (metadataUrl != null) {
      final latest = await getLatestRelease();
      return latest == null ? [] : [latest];
    }

    try {
      final response = await client.get(
        Uri.parse('$_allReleasesUrl?per_page=$perPage'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'VocabFlip-App',
        },
      );

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) =>
                AppVersion.fromGitHubRelease(json as Map<String, dynamic>))
            .where((release) => release.downloadUrl.isNotEmpty)
            .toList();
      } else {
        debugPrint(
            'GitHubReleaseApi: Failed to fetch releases: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('GitHubReleaseApi: Error fetching releases: $e');
      return [];
    }
  }

  /// Get a specific release by tag
  Future<AppVersion?> getReleaseByTag(String tag) async {
    if (metadataUrl != null) {
      final latest = await getLatestRelease();
      if (latest == null) return null;
      final normalizedTag = tag.startsWith('v') ? tag.substring(1) : tag;
      final normalizedLatest = latest.version.startsWith('v')
          ? latest.version.substring(1)
          : latest.version;
      return normalizedLatest == normalizedTag ? latest : null;
    }

    try {
      final response = await client.get(
        Uri.parse(
            'https://api.github.com/repos/$owner/$repo/releases/tags/$tag'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'VocabFlip-App',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AppVersion.fromGitHubRelease(json);
      } else {
        debugPrint(
            'GitHubReleaseApi: Failed to fetch release $tag: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('GitHubReleaseApi: Error fetching release $tag: $e');
      return null;
    }
  }

  void dispose() {
    if (_client != null) {
      _client.close();
    }
  }
}
