import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version.dart';
import '../remote/api/update_api.dart';
import '../services/update_download_service.dart';
import '../services/update_install_service.dart';
import '../local/preferences/app_preferences.dart';

/// Repository for handling app updates
class UpdateRepository {
  final UpdateApi _api;
  final UpdateDownloadService _downloadService;
  final UpdateInstallService _installService;
  final AppPreferences _preferences;

  UpdateRepository({
    required String metadataUrl,
    required AppPreferences preferences,
    UpdateApi? api,
    UpdateDownloadService? downloadService,
    UpdateInstallService? installService,
  })  : _api = api ??
            UpdateApi(
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
    return _preferences.autoCheckUpdates;
  }

  /// Check for available updates
  /// Returns null if no update available or an error occurred
  Future<AppVersion?> checkForUpdates({bool isAutoCheck = false}) async {
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

      // Compare versions
      if (!latestRelease.isNewerThan(currentVer)) {
        debugPrint(
            'UpdateRepository: Current version $currentVer is up to date');
        return null;
      }

      // If it is mandatory, always return the update immediately
      if (latestRelease.isMandatory) {
        debugPrint('UpdateRepository: Mandatory update available: ${latestRelease.version}');
        return latestRelease;
      }

      // Check if this version was skipped (for non-mandatory updates only)
      final skippedVersion = _preferences.skippedVersion;
      if (skippedVersion == latestRelease.version) {
        debugPrint(
            'UpdateRepository: Version ${latestRelease.version} was skipped');
        return null;
      }

      // If it is an automatic check, respect the 24-hour interval
      if (isAutoCheck) {
        final lastCheck = _preferences.lastUpdateCheck;
        if (lastCheck != null) {
          final hoursSinceCheck = DateTime.now().difference(lastCheck).inHours;
          debugPrint('UpdateRepository: Last check/prompt was $hoursSinceCheck hours ago');
          if (hoursSinceCheck < 24) {
            debugPrint(
                'UpdateRepository: Skipping prompt (less than 24h since last prompt)');
            return null;
          }
        }
      }

      // Update last check time only when we actually decide to return/prompt the update
      await _preferences.setLastUpdateCheck(DateTime.now());

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
