import 'package:flutter/foundation.dart';
import '../../data/models/imported_deck_link.dart';
import '../../data/models/sync_notification.dart';
import '../../data/models/public_deck.dart';
import '../../data/repositories/public_library_repository.dart';

/// State for sync operations
enum SyncState {
  idle,
  checking,
  syncing,
  success,
  error,
}

/// Update info for a linked deck
class DeckUpdate {
  final ImportedDeckLink link;
  final PublicDeck publicDeck;
  final int cardsDiff;

  DeckUpdate({
    required this.link,
    required this.publicDeck,
  }) : cardsDiff = publicDeck.cardCount - 0; // Would need to fetch local count

  int get versionsBehind => publicDeck.version - link.importedVersion;
}

/// Provider for sync management
class SyncProvider extends ChangeNotifier {
  final PublicLibraryRepository _repository = PublicLibraryRepository();

  // State
  SyncState _state = SyncState.idle;
  List<DeckUpdate> _availableUpdates = [];
  List<SyncNotification> _notifications = [];
  int _unreadCount = 0;
  String? _error;
  String? _syncingDeckId;

  // Getters
  SyncState get state => _state;
  List<DeckUpdate> get availableUpdates => _availableUpdates;
  List<SyncNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUpdates => _availableUpdates.isNotEmpty;
  String? get error => _error;
  String? get syncingDeckId => _syncingDeckId;
  bool get isChecking => _state == SyncState.checking;
  bool get isSyncing => _state == SyncState.syncing;

  /// Check for updates on all imported decks
  Future<void> checkForUpdates() async {
    _state = SyncState.checking;
    _error = null;
    notifyListeners();

    try {
      final updates = await _repository.checkForUpdates();
      _availableUpdates = updates
          .map((u) => DeckUpdate(link: u.link, publicDeck: u.deck))
          .toList();

      _state = SyncState.idle;
    } catch (e) {
      _error = e.toString();
      _state = SyncState.error;
    }

    notifyListeners();
  }

  /// Load notifications
  Future<void> loadNotifications() async {
    try {
      _notifications = await _repository.getAllNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  /// Check if a specific deck has updates
  bool hasUpdateForDeck(String localDeckId) {
    return _availableUpdates.any((u) => u.link.localDeckId == localDeckId);
  }

  /// Get update for a specific deck
  DeckUpdate? getUpdateForDeck(String localDeckId) {
    try {
      return _availableUpdates.firstWhere(
        (u) => u.link.localDeckId == localDeckId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sync a specific deck
  Future<bool> syncDeck(String localDeckId) async {
    _state = SyncState.syncing;
    _syncingDeckId = localDeckId;
    _error = null;
    notifyListeners();

    try {
      await _repository.syncDeck(localDeckId);

      // Remove from available updates
      _availableUpdates = _availableUpdates
          .where((u) => u.link.localDeckId != localDeckId)
          .toList();

      _state = SyncState.success;
      _syncingDeckId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _state = SyncState.error;
      _syncingDeckId = null;
      notifyListeners();
      return false;
    }
  }

  /// Sync all decks with available updates
  Future<void> syncAll() async {
    _state = SyncState.syncing;
    _error = null;
    notifyListeners();

    final toSync = List<DeckUpdate>.from(_availableUpdates);
    final errors = <String>[];

    for (final update in toSync) {
      _syncingDeckId = update.link.localDeckId;
      notifyListeners();

      try {
        await _repository.syncDeck(update.link.localDeckId);
        _availableUpdates = _availableUpdates
            .where((u) => u.link.localDeckId != update.link.localDeckId)
            .toList();
      } catch (e) {
        errors.add('${update.publicDeck.name}: $e');
      }
    }

    _syncingDeckId = null;

    if (errors.isEmpty) {
      _state = SyncState.success;
    } else {
      _error = 'Some syncs failed:\n${errors.join('\n')}';
      _state = SyncState.error;
    }

    notifyListeners();
  }

  /// Unlink a deck from its public source
  Future<void> unlinkDeck(String localDeckId) async {
    try {
      await _repository.unlinkDeck(localDeckId);

      // Remove from available updates
      _availableUpdates = _availableUpdates
          .where((u) => u.link.localDeckId != localDeckId)
          .toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _repository.markNotificationRead(notificationId);

      // Update local state
      _notifications = _notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    try {
      await _repository.markAllNotificationsRead();

      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  /// Get import link for a deck
  Future<ImportedDeckLink?> getImportLink(String localDeckId) =>
      _repository.getImportLink(localDeckId);

  /// Clear error
  void clearError() {
    _error = null;
    _state = SyncState.idle;
    notifyListeners();
  }
}
