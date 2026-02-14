import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for a single Cloudinary account.
class CloudinaryConfig {
  final String cloudName;
  final String uploadPreset;

  const CloudinaryConfig({
    required this.cloudName,
    required this.uploadPreset,
  });

  /// Unsigned upload URL for this account
  String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}

/// Manages multiple Cloudinary accounts for load distribution.
///
/// Reads from .env file:
/// - `CLOUDINARY_CLOUD_NAMES` — comma-separated cloud names
/// - `CLOUDINARY_UPLOAD_PRESETS` — comma-separated upload presets (matched by index)
class CloudinaryAccounts {
  static final CloudinaryAccounts _instance = CloudinaryAccounts._internal();
  factory CloudinaryAccounts() => _instance;
  CloudinaryAccounts._internal();

  final _random = Random();

  List<CloudinaryConfig>? _cachedAccounts;

  /// Parse accounts from .env on first access
  List<CloudinaryConfig> get accounts {
    if (_cachedAccounts != null) return _cachedAccounts!;

    final cloudNames = (dotenv.env['CLOUDINARY_CLOUD_NAMES'] ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final presets = (dotenv.env['CLOUDINARY_UPLOAD_PRESETS'] ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final list = <CloudinaryConfig>[];
    for (int i = 0; i < cloudNames.length; i++) {
      // If fewer presets than names, reuse the last preset
      final preset = i < presets.length ? presets[i] : presets.last;
      list.add(CloudinaryConfig(
        cloudName: cloudNames[i],
        uploadPreset: preset,
      ));
    }

    _cachedAccounts = list;
    return list;
  }

  /// Get a random account for load balancing
  CloudinaryConfig getRandomAccount() {
    if (accounts.isEmpty) {
      throw Exception('No Cloudinary accounts configured. '
          'Add CLOUDINARY_CLOUD_NAMES and CLOUDINARY_UPLOAD_PRESETS to .env');
    }
    return accounts[_random.nextInt(accounts.length)];
  }

  /// Check if any accounts are configured
  bool get isConfigured => accounts.isNotEmpty;
}
