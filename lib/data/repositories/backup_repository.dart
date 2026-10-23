import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/backup_metadata.dart';
import '../models/deck.dart';
import '../api/api_client.dart';
import '../auth/alpha_auth_session.dart';
import '../services/google_drive_service.dart';
import 'deck_repository.dart';
import '../local/database/flashcard_dao.dart';
import '../../core/constants/app_constants.dart';

/// Repository for backup/restore operations using Google Drive
class BackupRepository {
  final GoogleDriveService _driveService;
  final DeckRepository _deckRepository;
  final FlashcardDao _flashcardDao;

  BackupRepository({
    GoogleDriveService? driveService,
    DeckRepository? deckRepository,
    FlashcardDao? flashcardDao,
  })  : _driveService = driveService ?? GoogleDriveService(),
        _deckRepository = deckRepository ?? DeckRepository(),
        _flashcardDao = flashcardDao ?? FlashcardDao();

  bool get isConnected => _driveService.isConnected;
  String? get userEmail => _driveService.userEmail;

  /// Connect to Google Drive
  Future<bool> connect({bool silentOnly = false}) async {
    return await _driveService.connect(silentOnly: silentOnly);
  }

  /// Disconnect from Google Drive
  Future<void> disconnect() async {
    await _driveService.disconnect();
  }

  /// Check current connection status
  Future<bool> checkConnection() async {
    return await _driveService.checkConnection();
  }

  /// Create a full backup of all decks and cards
  Future<BackupMetadata> createBackup({
    void Function(String status, double progress)? onProgress,
  }) async {
    if (!_driveService.isConnected) {
      throw Exception('Not connected to Google Drive');
    }

    onProgress?.call('Preparing data...', 0.1);

    // Get all decks
    final decks = await _deckRepository.getAllDecks();

    // Build export data for all decks
    final deckDataList = <Map<String, dynamic>>[];
    int totalCards = 0;

    for (int i = 0; i < decks.length; i++) {
      final deck = decks[i];
      final cards = await _flashcardDao.getByDeckId(deck.id);
      totalCards += cards.length;
      deckDataList.add(deck.toJson(cards));

      final progress = 0.1 + (0.4 * (i + 1) / decks.length);
      onProgress?.call('Exporting deck ${i + 1}/${decks.length}...', progress);
    }

    onProgress?.call('Building backup...', 0.5);

    // Get app version
    final packageInfo = await PackageInfo.fromPlatform();

    // Create backup data
    final backupData = <String, dynamic>{
      'backup_version': '1.0',
      'app_version': packageInfo.version,
      'created_at': DateTime.now().toIso8601String(),
      'summary': {
        'deck_count': decks.length,
        'card_count': totalCards,
      },
      'data': {
        'version': AppConstants.exportVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'decks': deckDataList,
      },
    };

    onProgress?.call('Uploading to Google Drive...', 0.6);

    // Upload to Google Drive
    final fileId = await _driveService.uploadBackup(backupData);

    if (fileId == null) {
      throw Exception('Failed to upload backup');
    }

    onProgress?.call('Complete!', 1.0);

    return BackupMetadata(
      id: fileId,
      name: 'vocabflip_backup',
      backupVersion: '1.0',
      appVersion: packageInfo.version,
      createdAt: DateTime.now(),
      deckCount: decks.length,
      cardCount: totalCards,
    );
  }

  /// List all available backups
  Future<List<BackupMetadata>> listBackups() async {
    if (!_driveService.isConnected) {
      throw Exception('Not connected to Google Drive');
    }

    final files = await _driveService.listBackups();
    final backups = <BackupMetadata>[];

    for (final file in files) {
      try {
        // Get metadata from file
        final metadata = await _driveService.getBackupMetadata(file.id);
        if (metadata != null) {
          backups.add(BackupMetadata.fromJson(metadata,
              fileId: file.id, size: file.size));
        } else {
          // Fallback to basic info from file
          backups.add(BackupMetadata(
            id: file.id,
            name: file.name,
            backupVersion: 'Unknown',
            appVersion: 'Unknown',
            createdAt: file.createdAt,
            deckCount: 0,
            cardCount: 0,
            fileSize: file.size,
          ));
        }
      } catch (e) {
        debugPrint('Error getting metadata for ${file.id}: $e');
        // Add with basic info on error
        backups.add(BackupMetadata(
          id: file.id,
          name: file.name,
          backupVersion: 'Unknown',
          appVersion: 'Unknown',
          createdAt: file.createdAt,
          deckCount: 0,
          cardCount: 0,
          fileSize: file.size,
        ));
      }
    }

    return backups;
  }

  /// Restore from a backup
  Future<RestoreResult> restoreBackup(
    String backupId, {
    Future<RestoreMode?> Function()? onConflict,
    void Function(String status, double progress)? onProgress,
  }) async {
    final owner = AlphaAuthSession().userId;
    final version = ApiClient().sessionVersion;
    void checkSession() {
      if (owner != AlphaAuthSession().userId ||
          version != ApiClient().sessionVersion) {
        throw StateError('Account changed during restore');
      }
    }

    if (!_driveService.isConnected) {
      throw Exception('Not connected to Google Drive');
    }

    onProgress?.call('Downloading backup...', 0.1);

    // Download backup data
    final backupData = await _driveService.downloadBackup(backupId);
    checkSession();
    if (backupData == null) {
      throw Exception('Failed to download backup');
    }

    onProgress?.call('Validating backup...', 0.2);

    // Validate backup format
    final data = backupData['data'] as Map<String, dynamic>?;
    if (data == null || !data.containsKey('decks')) {
      throw Exception('Invalid backup format');
    }

    final decksList = jsonDecode(jsonEncode(data['decks'])) as List<dynamic>;
    final ids = <String>{};
    final cardIds = <String>{};
    for (final value in decksList) {
      final deckData = value as Map<String, dynamic>;
      final deck = Deck.fromJson(deckData);
      deck.toMap();
      for (final card in DeckRepository.parseImportCards(deckData, deck.id)) {
        if (!cardIds.add(card.id)) {
          throw const FormatException('Duplicate card IDs across decks');
        }
      }
      if (!ids.add(deck.id)) throw const FormatException('Duplicate deck IDs');
    }
    if (decksList.isEmpty) {
      return const RestoreResult(
        success: true,
        decksRestored: 0,
        cardsRestored: 0,
        decksSkipped: 0,
      );
    }

    onProgress?.call('Checking for conflicts...', 0.25);
    bool hasConflicts = false;
    for (int i = 0; i < decksList.length; i++) {
      final deckData = decksList[i] as Map<String, dynamic>;
      final deckId = deckData['id'] as String?;
      if (deckId != null && await _deckRepository.deckExists(deckId)) {
        hasConflicts = true;
        break;
      }
    }

    checkSession();
    RestoreMode mode = RestoreMode.merge;
    if (hasConflicts && onConflict != null) {
      final selectedMode = await onConflict();
      checkSession();
      if (selectedMode == null) {
        // User cancelled the restore
        return const RestoreResult(
          success: false,
          decksRestored: 0,
          cardsRestored: 0,
          decksSkipped: 0,
          error: 'Restore cancelled by user',
        );
      }
      mode = selectedMode;
    }

    if (kIsWeb && hasConflicts && mode == RestoreMode.replace) {
      return const RestoreResult(
          success: false,
          decksRestored: 0,
          cardsRestored: 0,
          decksSkipped: 0,
          error: 'Atomic replacement is unavailable on web');
    }

    onProgress?.call('Restoring decks...', 0.3);

    int decksRestored = 0;
    int cardsRestored = 0;
    int decksSkipped = 0;
    String? restoreError;

    for (int i = 0; i < decksList.length; i++) {
      checkSession();
      try {
        final deckData = decksList[i] as Map<String, dynamic>;
        final importData = {
          'version': data['version'] ?? '1.0',
          'decks': [deckData],
        };

        // Check if deck exists
        final deckId = deckData['id'] as String?;
        bool exists = false;
        if (deckId != null) {
          exists = await _deckRepository.deckExists(deckId);
          checkSession();
        }

        if (exists && mode == RestoreMode.merge) {
          decksSkipped++;
          debugPrint('Skipping existing deck: $deckId');
        } else {
          // Rename if mode is rename
          if (exists && mode == RestoreMode.rename) {
            final baseName = deckData['name'] as String? ?? 'Restored Deck';
            // We need a loop to find an available name (we'll just append timestamp or number)
            // The simplest approach without querying all decks is to append the current timestamp
            deckData['name'] =
                '$baseName (${DateTime.now().millisecondsSinceEpoch.toString().substring(8)})';
            // Also need to clear the ID so it's created as a new deck
            deckData.remove('id');
            // Remove deck ID from cards as well so they are inserted as new
            final cards = deckData['cards'] as List<dynamic>?;
            if (cards != null) {
              for (var card in cards) {
                if (card is Map<String, dynamic>) {
                  card.remove('deckId');
                  card.remove('id');
                }
              }
            }
          }

          final deck = await _deckRepository.importDeck(importData,
              overwrite: exists && mode == RestoreMode.replace);
          checkSession();
          decksRestored++;

          final cardCount = (deckData['cards'] as List?)?.length ?? 0;
          cardsRestored += cardCount;

          debugPrint('Restored deck: ${deck.name} with $cardCount cards');
        }
      } catch (e) {
        checkSession();
        restoreError = 'Failed to restore deck ${i + 1}';
        break;
      }

      final progress = 0.3 + (0.7 * (i + 1) / decksList.length);
      onProgress?.call(
          'Restoring deck ${i + 1}/${decksList.length}...', progress);
    }

    onProgress?.call('Complete!', 1.0);

    return RestoreResult(
      success: restoreError == null,
      decksRestored: decksRestored,
      cardsRestored: cardsRestored,
      decksSkipped: decksSkipped,
      error: restoreError,
    );
  }

  /// Delete a backup from Google Drive
  Future<void> deleteBackup(String backupId) async {
    if (!_driveService.isConnected) {
      throw Exception('Not connected to Google Drive');
    }

    await _driveService.deleteBackup(backupId);
  }

  /// Get backup details without full download
  Future<BackupMetadata?> getBackupDetails(String backupId) async {
    if (!_driveService.isConnected) {
      throw Exception('Not connected to Google Drive');
    }

    final metadata = await _driveService.getBackupMetadata(backupId);
    if (metadata == null) return null;

    return BackupMetadata.fromJson(metadata, fileId: backupId);
  }
}

enum RestoreMode {
  merge,
  replace,
  rename,
}

/// Result of a restore operation
class RestoreResult {
  final bool success;
  final int decksRestored;
  final int cardsRestored;
  final int decksSkipped;
  final String? error;

  const RestoreResult({
    required this.success,
    required this.decksRestored,
    required this.cardsRestored,
    required this.decksSkipped,
    this.error,
  });

  @override
  String toString() =>
      'RestoreResult(decks: $decksRestored, cards: $cardsRestored, skipped: $decksSkipped)';
}
