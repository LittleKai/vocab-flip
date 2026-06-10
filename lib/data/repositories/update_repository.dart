import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version.dart';
import '../remote/api/github_release_api.dart';
import '../services/update_download_service.dart';
import '../services/update_install_service.dart';
import '../local/preferences/app_preferences.dart';

/// Repository for handling app updates
class UpdateRepository {
  final GitHubReleaseApi _api;
  final UpdateDownloadService _downloadService;
  final UpdateInstallService _installService;
  final AppPreferences _preferences;

  UpdateRepository({
    required String owner,
    required String repo,
    required AppPreferences preferences,
    String? metadataUrl,
    GitHubReleaseApi? api,
    UpdateDownloadService? downloadService,
    UpdateInstallService? installService,
  })  : _api = api ??
            GitHubReleaseApi(
              owner: owner,
              repo: repo,
              metadataUrl: metadataUrl,
            ),
        _downloadService = downloadService ?? UpdateDownloadService(),
        _installService = installService ?? UpdateInstallService(),
        _preferences = preferences;

  /// Cached package info
  static PackageInfo? _packageInfo;

  /// Get current app version from package info
  static Future<String> getCurrentVersion() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!.version;
  }

  /// Get current build number from package info
  static Future<int> getCurrentBuildNumber() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return int.tryParse(_packageInfo!.buildNumber) ?? 1;
  }

  /// Synchronous version getter (returns cached or fallback)
  static String get currentVersion => _packageInfo?.version ?? '0.0.0';
  static int get currentBuildNumber =>
      int.tryParse(_packageInfo?.buildNumber ?? '1') ?? 1;

  /// Check if we should auto-check for updates
  bool get shouldAutoCheck {
    if (!_preferences.autoCheckUpdates) {
      debugPrint('UpdateRepository: Auto-check disabled by user');
      return false;
    }

    final lastCheck = _preferences.lastUpdateCheck;
    if (lastCheck == null) {
      debugPrint('UpdateRepository: First time check, proceeding');
      return true;
    }

    // Check every 24 hours
    final hoursSinceCheck = DateTime.now().difference(lastCheck).inHours;
    debugPrint('UpdateRepository: Last check was $hoursSinceCheck hours ago');
    if (hoursSinceCheck < 24) {
      debugPrint(
          'UpdateRepository: Skipping check (less than 24h since last check)');
      return false;
    }
    return true;
  }

  /// Check for available updates
  /// Returns null if no update available or an error occurred
  Future<AppVersion?> checkForUpdates() async {
    try {
      debugPrint('UpdateRepository: Checking for updates...');

      // Get current version from package info
      final currentVer = await getCurrentVersion();
      debugPrint('UpdateRepository: Current version: $currentVer');

      final latestRelease = await _api.getLatestRelease();
      if (latestRelease == null) {
        debugPrint('UpdateRepository: No releases found');
        return null;
      }

      // Update last check time
      await _preferences.setLastUpdateCheck(DateTime.now());

      // Compare versions
      if (!latestRelease.isNewerThan(currentVer)) {
        debugPrint(
            'UpdateRepository: Current version $currentVer is up to date');
        return null;
      }

      // Check if this version was skipped
      final skippedVersion = _preferences.skippedVersion;
      if (skippedVersion == latestRelease.version &&
          !latestRelease.isMandatory) {
        debugPrint(
            'UpdateRepository: Version ${latestRelease.version} was skipped');
        return null;
      }

      debugPrint(
          'UpdateRepository: Update available: ${latestRelease.version} (zip: ${latestRelease.downloadUrl.isNotEmpty}, apk: ${latestRelease.apkDownloadUrl.isNotEmpty})');
      return latestRelease;
    } catch (e) {
      debugPrint('UpdateRepository: Error checking for updates: $e');
      return null;
    }
  }

  /// Download update with progress
  Future<String?> downloadUpdate(
    AppVersion version, {
    required void Function(DownloadProgress progress) onProgress,
    void Function(String error)? onError,
  }) async {
    return _downloadService.downloadUpdate(
      version.downloadUrl,
      onProgress: onProgress,
      onError: onError,
    );
  }

  /// Extract the downloaded update
  Future<String?> extractUpdate(String zipPath) async {
    return _installService.extractUpdate(zipPath);
  }

  /// Verify the update is valid
  Future<bool> verifyUpdate(String extractedPath) async {
    return _installService.verifyUpdate(extractedPath);
  }

  /// Install update and restart app
  Future<bool> installAndRestart(String extractedPath) async {
    return _installService.installAndRestart(extractedPath);
  }

  /// Skip a version (won't prompt again unless mandatory)
  Future<void> skipVersion(String version) async {
    await _preferences.setSkippedVersion(version);
    debugPrint('UpdateRepository: Skipped version $version');
  }

  /// Clean up downloaded files
  Future<void> cleanup() async {
    await _downloadService.cleanupOldUpdates();
  }

  /// Check if platform supports auto-update
  bool get isAutoUpdateSupported => UpdateInstallService.isSupported;

  void dispose() {
    _api.dispose();
    _downloadService.dispose();
  }
}
