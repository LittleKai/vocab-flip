import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/app_version.dart';
import '../../data/repositories/update_repository.dart';
import '../../data/services/update_download_service.dart';
import '../../data/local/preferences/app_preferences.dart';

const _vocabReleaseMetadataUrl =
    'https://cdn.giaiphapsangtao.com/file/alpha-studio/vocabflip-app/version.json';
const _vocabDownloadPageUrl = 'https://giaiphapsangtao.com/studio/vocab';

/// State for the update process
enum UpdateState {
  idle,
  checking,
  updateAvailable,
  downloading,
  extracting,
  installing,
  error,
}

/// Provider for managing app updates
class UpdateProvider extends ChangeNotifier {
  late UpdateRepository _repository;
  late AppPreferences _preferences;
  bool _initialized = false;

  UpdateState _state = UpdateState.idle;
  AppVersion? _availableUpdate;
  DownloadProgress? _downloadProgress;
  String? _error;
  String? _downloadedFilePath;
  String? _extractedPath;

  // Getters
  UpdateState get state => _state;
  AppVersion? get availableUpdate => _availableUpdate;
  DownloadProgress? get downloadProgress => _downloadProgress;
  String? get error => _error;
  bool get isChecking => _state == UpdateState.checking;
  bool get isDownloading => _state == UpdateState.downloading;
  bool get isExtracting => _state == UpdateState.extracting;
  bool get isInstalling => _state == UpdateState.installing;
  bool get hasUpdate => _availableUpdate != null;
  bool get hasError => _state == UpdateState.error;

  String _currentVersion = '...';

  String get currentVersion => _currentVersion;

  /// Whether the platform supports auto-check for updates
  /// Windows: full auto-update (download + install)
  /// Android: check + notify (open download link)
  bool get isAutoUpdateSupported {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isAndroid;
  }

  String get releasesUrl => _vocabDownloadPageUrl;

  /// Open the Studio download page in browser (for platforms without auto-update)
  Future<void> openReleasesPage() async {
    final uri = Uri.parse(releasesUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get autoCheckUpdates =>
      _initialized ? _preferences.autoCheckUpdates : true;

  /// Initialize with preferences (idempotent - safe to call multiple times)
  Future<void> init(AppPreferences preferences) async {
    if (_initialized) return; // Already initialized

    _preferences = preferences;
    _repository = UpdateRepository(
      metadataUrl: _vocabReleaseMetadataUrl,
      preferences: preferences,
    );

    // Load current version from package info
    _currentVersion = await UpdateRepository.getCurrentVersion();
    debugPrint('UpdateProvider: Initialized with version $_currentVersion');

    _initialized = true;
    notifyListeners();
  }

  /// Check if should auto-check on startup
  bool get shouldAutoCheckOnStartup {
    if (!_initialized) return false;
    if (!isAutoUpdateSupported) return false;
    return _repository.shouldAutoCheck;
  }

  /// Set auto-check preference
  Future<void> setAutoCheckUpdates(bool value) async {
    if (!_initialized) return;
    await _preferences.setAutoCheckUpdates(value);
    notifyListeners();
  }

  /// Check for updates
  Future<void> checkForUpdates({bool silent = false}) async {
    if (!_initialized) return;
    if (_state == UpdateState.checking) return;

    _state = UpdateState.checking;
    _error = null;
    if (!silent) notifyListeners();

    try {
      _availableUpdate = await _repository.checkForUpdates();

      if (_availableUpdate != null) {
        _state = UpdateState.updateAvailable;
      } else {
        _state = UpdateState.idle;
      }
    } catch (e) {
      _state = UpdateState.error;
      _error = e.toString();
    }

    notifyListeners();
  }

  /// Download the update
  Future<bool> downloadUpdate() async {
    if (!_initialized) return false;
    if (_availableUpdate == null) return false;
    if (_state == UpdateState.downloading) return false;

    _state = UpdateState.downloading;
    _downloadProgress = null;
    _error = null;
    notifyListeners();

    try {
      _downloadedFilePath = await _repository.downloadUpdate(
        _availableUpdate!,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
        onError: (error) {
          _error = error;
        },
      );

      if (_downloadedFilePath != null) {
        // Proceed to extraction
        return await _extractUpdate();
      } else {
        _state = UpdateState.error;
        _error ??= 'Download failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = UpdateState.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Extract the downloaded update
  Future<bool> _extractUpdate() async {
    if (_downloadedFilePath == null) return false;

    _state = UpdateState.extracting;
    notifyListeners();

    try {
      _extractedPath = await _repository.extractUpdate(_downloadedFilePath!);

      if (_extractedPath == null) {
        _state = UpdateState.error;
        _error = 'Failed to extract update';
        notifyListeners();
        return false;
      }

      // Verify the update
      final isValid = await _repository.verifyUpdate(_extractedPath!);
      if (!isValid) {
        _state = UpdateState.error;
        _error = 'Update verification failed';
        await _repository.cleanup();
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _state = UpdateState.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Install the update and restart
  Future<bool> installAndRestart() async {
    if (!_initialized) return false;
    if (_extractedPath == null) return false;

    _state = UpdateState.installing;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.installAndRestart(_extractedPath!);

      if (success) {
        // Exit the app - the update script will restart it
        exit(0);
      } else {
        _state = UpdateState.error;
        _error = 'Failed to install update';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = UpdateState.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Skip this version
  Future<void> skipVersion() async {
    if (!_initialized) return;
    if (_availableUpdate == null) return;

    await _repository.skipVersion(_availableUpdate!.version);
    _availableUpdate = null;
    _state = UpdateState.idle;
    notifyListeners();
  }

  /// Dismiss the update (for later)
  void dismissUpdate() {
    _state = UpdateState.idle;
    // Keep _availableUpdate so we can show it again if user checks manually
    notifyListeners();
  }

  /// Reset state after error
  void resetState() {
    _state = UpdateState.idle;
    _error = null;
    _downloadProgress = null;
    _downloadedFilePath = null;
    _extractedPath = null;
    notifyListeners();
  }

  /// Cleanup downloaded files
  Future<void> cleanup() async {
    if (!_initialized) return;
    await _repository.cleanup();
  }

  @override
  void dispose() {
    if (_initialized) {
      _repository.dispose();
    }
    super.dispose();
  }
}
