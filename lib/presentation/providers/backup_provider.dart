import 'package:flutter/foundation.dart';
import '../../data/models/backup_metadata.dart';
import '../../data/repositories/backup_repository.dart';

/// Backup operation states
enum BackupStatus {
  idle,
  connecting,
  connected,
  backingUp,
  restoring,
  listing,
  deleting,
  error,
  disconnected,
}

/// Provider for managing Google Drive backup operations
class BackupProvider extends ChangeNotifier {
  final BackupRepository _repository;

  BackupStatus _status = BackupStatus.idle;
  String? _error;
  String? _statusMessage;
  double _progress = 0.0;
  List<BackupMetadata> _backups = [];
  BackupMetadata? _lastBackup;
  RestoreResult? _lastRestoreResult;

  BackupProvider({BackupRepository? repository})
      : _repository = repository ?? BackupRepository();

  // Getters
  BackupStatus get status => _status;
  String? get error => _error;
  String? get statusMessage => _statusMessage;
  double get progress => _progress;
  List<BackupMetadata> get backups => _backups;
  BackupMetadata? get lastBackup => _lastBackup;
  RestoreResult? get lastRestoreResult => _lastRestoreResult;

  bool get isConnected => _repository.isConnected;
  bool get isIdle => _status == BackupStatus.idle || _status == BackupStatus.connected;
  bool get isBusy => _status == BackupStatus.backingUp ||
      _status == BackupStatus.restoring ||
      _status == BackupStatus.connecting ||
      _status == BackupStatus.listing ||
      _status == BackupStatus.deleting;
  String? get userEmail => _repository.userEmail;

  /// Connect to Google Drive
  Future<bool> connect() async {
    _status = BackupStatus.connecting;
    _error = null;
    _statusMessage = 'Connecting to Google Drive...';
    _progress = 0.0;
    notifyListeners();

    try {
      final success = await _repository.connect();

      if (success) {
        _status = BackupStatus.connected;
        _statusMessage = null;
        // Auto-load backups after connecting
        await _loadBackupsInternal();
      } else {
        _status = BackupStatus.disconnected;
        _error = 'Failed to connect to Google Drive';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _status = BackupStatus.error;
      _error = e.toString();
      _statusMessage = null;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from Google Drive
  Future<void> disconnect() async {
    await _repository.disconnect();
    _status = BackupStatus.disconnected;
    _backups = [];
    _lastBackup = null;
    _error = null;
    _statusMessage = null;
    notifyListeners();
  }

  /// Check connection status
  Future<bool> checkConnection() async {
    final connected = await _repository.checkConnection();
    if (!connected && _status == BackupStatus.connected) {
      _status = BackupStatus.disconnected;
      notifyListeners();
    }
    return connected;
  }

  /// Create a new backup
  Future<BackupMetadata?> createBackup() async {
    if (isBusy) return null;

    _status = BackupStatus.backingUp;
    _error = null;
    _progress = 0.0;
    _statusMessage = 'Preparing backup...';
    notifyListeners();

    try {
      final backup = await _repository.createBackup(
        onProgress: (message, progress) {
          _statusMessage = message;
          _progress = progress;
          notifyListeners();
        },
      );

      _lastBackup = backup;
      _backups.insert(0, backup);
      _status = BackupStatus.connected;
      _statusMessage = null;
      _progress = 1.0;
      notifyListeners();

      return backup;
    } catch (e) {
      _status = BackupStatus.error;
      _error = e.toString();
      _statusMessage = null;
      notifyListeners();
      return null;
    }
  }

  /// Load list of available backups
  Future<void> loadBackups() async {
    if (_status == BackupStatus.listing) return;

    _status = BackupStatus.listing;
    _error = null;
    _statusMessage = 'Loading backups...';
    notifyListeners();

    await _loadBackupsInternal();
  }

  Future<void> _loadBackupsInternal() async {
    try {
      _backups = await _repository.listBackups();
      _status = BackupStatus.connected;
      _statusMessage = null;
      notifyListeners();
    } catch (e) {
      _status = BackupStatus.error;
      _error = e.toString();
      _statusMessage = null;
      notifyListeners();
    }
  }

  /// Restore from a backup
  Future<RestoreResult?> restoreBackup(
    String backupId, {
    bool replaceExisting = false,
  }) async {
    if (isBusy) return null;

    _status = BackupStatus.restoring;
    _error = null;
    _progress = 0.0;
    _statusMessage = 'Preparing restore...';
    _lastRestoreResult = null;
    notifyListeners();

    try {
      final result = await _repository.restoreBackup(
        backupId,
        replaceExisting: replaceExisting,
        onProgress: (message, progress) {
          _statusMessage = message;
          _progress = progress;
          notifyListeners();
        },
      );

      _lastRestoreResult = result;
      _status = BackupStatus.connected;
      _statusMessage = null;
      _progress = 1.0;
      notifyListeners();

      return result;
    } catch (e) {
      _status = BackupStatus.error;
      _error = e.toString();
      _statusMessage = null;
      notifyListeners();
      return null;
    }
  }

  /// Delete a backup
  Future<bool> deleteBackup(String backupId) async {
    if (isBusy) return false;

    _status = BackupStatus.deleting;
    _error = null;
    _statusMessage = 'Deleting backup...';
    notifyListeners();

    try {
      await _repository.deleteBackup(backupId);
      _backups.removeWhere((b) => b.id == backupId);
      _status = BackupStatus.connected;
      _statusMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = BackupStatus.error;
      _error = e.toString();
      _statusMessage = null;
      notifyListeners();
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    if (_status == BackupStatus.error) {
      _status = _repository.isConnected ? BackupStatus.connected : BackupStatus.disconnected;
    }
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _status = BackupStatus.idle;
    _error = null;
    _statusMessage = null;
    _progress = 0.0;
    _backups = [];
    _lastBackup = null;
    _lastRestoreResult = null;
    notifyListeners();
  }
}
