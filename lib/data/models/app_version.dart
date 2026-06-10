/// Model representing an app version from release metadata.
class AppVersion {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String apkDownloadUrl;
  final Map<String, String> releaseNotes;
  final DateTime publishedAt;
  final bool isMandatory;

  AppVersion({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.apkDownloadUrl = '',
    required this.releaseNotes,
    required this.publishedAt,
    this.isMandatory = false,
  });

  /// Parse version string to compare (e.g., "1.2.3" -> [1, 2, 3])
  List<int> get versionParts {
    final cleanVersion = version.replaceAll(RegExp(r'^v'), '');
    return cleanVersion.split('.').map((part) {
      final numPart = part.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(numPart) ?? 0;
    }).toList();
  }

  /// Compare with another version
  /// Returns: 1 if this > other, -1 if this < other, 0 if equal
  int compareTo(AppVersion other) {
    final thisParts = versionParts;
    final otherParts = other.versionParts;

    for (int i = 0; i < 3; i++) {
      final thisVal = i < thisParts.length ? thisParts[i] : 0;
      final otherVal = i < otherParts.length ? otherParts[i] : 0;

      if (thisVal > otherVal) return 1;
      if (thisVal < otherVal) return -1;
    }
    return 0;
  }

  /// Compare with version string
  bool isNewerThan(String otherVersion) {
    final other = AppVersion(
      version: otherVersion,
      buildNumber: 0,
      downloadUrl: '',
      releaseNotes: {},
      publishedAt: DateTime.now(),
    );
    return compareTo(other) > 0;
  }

  /// Get release notes for a specific language, fallback to English
  String getReleaseNotes(String locale) {
    return releaseNotes[locale] ?? releaseNotes['en'] ?? '';
  }

  factory AppVersion.fromGitHubRelease(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? 'v0.0.0';
    final body = json['body'] as String? ?? '';

    // Parse release notes from body
    // Expected format:
    // ## English
    // - Change 1
    // - Change 2
    //
    // ## Vietnamese
    // - Thay doi 1
    // - Thay doi 2
    final releaseNotes = _parseReleaseNotes(body);

    // Check if mandatory update (body contains [MANDATORY])
    final isMandatory = body.contains('[MANDATORY]');

    // Find platform-specific assets
    String downloadUrl = '';
    String apkDownloadUrl = '';
    final assets = json['assets'] as List<dynamic>? ?? [];

    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      final url = asset['browser_download_url'] as String? ?? '';

      // Windows ZIP
      if (name.toLowerCase().contains('windows') && name.endsWith('.zip')) {
        downloadUrl = url;
      }
      // Android APK
      if (name.endsWith('.apk')) {
        apkDownloadUrl = url;
      }
    }

    // Fallback: try to find any ZIP for Windows
    if (downloadUrl.isEmpty) {
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.zip')) {
          downloadUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }
    }

    return AppVersion(
      version: tagName,
      buildNumber: _parseBuildNumber(tagName),
      downloadUrl: downloadUrl,
      apkDownloadUrl: apkDownloadUrl,
      releaseNotes: releaseNotes,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.now(),
      isMandatory: isMandatory,
    );
  }

  static int _parseBuildNumber(String tagName) {
    // Extract build number from tag like v1.2.3+45 or v1.2.3-45
    final buildMatch = RegExp(r'[+\-](\d+)').firstMatch(tagName);
    if (buildMatch != null) {
      return int.tryParse(buildMatch.group(1)!) ?? 0;
    }

    // If no build number, calculate from version
    final cleanVersion = tagName.replaceAll(RegExp(r'^v'), '');
    final parts = cleanVersion.split('.').map((p) {
      final num = p.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(num) ?? 0;
    }).toList();

    if (parts.length >= 3) {
      return parts[0] * 10000 + parts[1] * 100 + parts[2];
    }
    return 0;
  }

  static Map<String, String> _parseReleaseNotes(String body) {
    final notes = <String, String>{};

    // Try to parse multi-language format
    final sections = body.split(RegExp(r'##\s+'));

    for (final section in sections) {
      if (section.trim().isEmpty) continue;

      final lines = section.split('\n');
      final header = lines.first.trim().toLowerCase();

      String langCode = 'en';
      if (header.contains('english') || header.contains('en')) {
        langCode = 'en';
      } else if (header.contains('vietnamese') ||
          header.contains('vi') ||
          header.contains('tieng viet') ||
          header.contains('tiếng việt')) {
        langCode = 'vi';
      } else {
        continue;
      }

      final content = lines.skip(1).join('\n').trim();
      if (content.isNotEmpty) {
        notes[langCode] = content;
      }
    }

    // If no sections found, use entire body as English
    if (notes.isEmpty && body.trim().isNotEmpty) {
      notes['en'] = body.trim();
    }

    return notes;
  }

  Map<String, dynamic> toMap() => {
        'version': version,
        'buildNumber': buildNumber,
        'downloadUrl': downloadUrl,
        'apkDownloadUrl': apkDownloadUrl,
        'releaseNotes': releaseNotes,
        'publishedAt': publishedAt.toIso8601String(),
        'isMandatory': isMandatory,
      };

  @override
  String toString() =>
      'AppVersion(version: $version, buildNumber: $buildNumber)';
}
