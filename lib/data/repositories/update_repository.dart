import 'package:flutter/foundation.dart';
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
    GitHubReleaseApi? api,
    UpdateDownloadService? downloadService,
    UpdateInstallService? installService,
  })  : _api = api ?? GitHubReleaseApi(owner: owner, repo: repo),
        _downloadService = downloadService ?? UpdateDownloadService(),
        _installService = installService ?? UpdateInstallService(),
        _preferences = preferences;

  /// Current app version
  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 1;

  /// Check if we should auto-check for updates
  bool get shouldAutoCheck {
    if (!_preferences.autoCheckUpdates) return false;

    final lastCheck = _preferences.lastUpdateCheck;
    if (lastCheck == null) return true;

    // Check every 24 hours
    final hoursSinceCheck = DateTime.now().difference(lastCheck).inHours;
    return hoursSinceCheck >= 24;
  }

  /// Check for available updates
  /// Returns null if no update available or an error occurred
  Future<AppVersion?> checkForUpdates() async {
    try {
      debugPrint('UpdateRepository: Checking for updates...');

      final latestRelease = await _api.getLatestRelease();
      if (latestRelease == null) {
        debugPrint('UpdateRepository: No releases found');
        return null;
      }

      // Update last check time
      await _preferences.setLastUpdateCheck(DateTime.now());

      // Compare versions
      if (!latestRelease.isNewerThan(currentVersion)) {
        debugPrint(
            'UpdateRepository: Current version $currentVersion is up to date');
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

      // Check if download URL is available for Windows
      if (latestRelease.downloadUrl.isEmpty) {
        debugPrint('UpdateRepository: No Windows download available');
        return null;
      }

      debugPrint(
          'UpdateRepository: Update available: ${latestRelease.version}');
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
