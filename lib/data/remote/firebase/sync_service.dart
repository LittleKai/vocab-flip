import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/imported_deck_link.dart';
import '../../models/sync_notification.dart';
import '../../models/public_deck.dart';
import '../../models/public_flashcard.dart';
import '../../local/database/app_database.dart';
import 'firebase_service.dart';
import 'firestore_rest_client.dart';

/// Service for managing deck imports and sync
class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _authService = FirebaseService();
  final FirestoreRestClient _restClient = FirestoreRestClient();
  final AppDatabase _localDb = AppDatabase();

  /// Check if we should use REST API (Windows)
  bool get _useRest => FirestoreRestClient.shouldUseRest;

  String _userImportedDecksPath(String userId) =>
      'users/$userId/${AppConstants.collectionImportedDecks}';

  CollectionReference<Map<String, dynamic>> get _publicDecksRef =>
      _firestore.collection(AppConstants.collectionPublicDecks);

  CollectionReference<Map<String, dynamic>> _userImportedDecksRef(String userId) =>
      _firestore.collection('users').doc(userId).collection(AppConstants.collectionImportedDecks);

  CollectionReference<Map<String, dynamic>> get _syncNotificationsRef =>
      _firestore.collection(AppConstants.collectionSyncNotifications);

  /// Record an import link in Firestore and local DB
  Future<ImportedDeckLink> recordImport({
    required String publicDeckId,
    required String localDeckId,
    required int importedVersion,
  }) async {
    final userId = _authService.userId;
    if (userId == null) {
      throw Exception('User must be signed in to import');
    }

    final link = ImportedDeckLink(
      id: const Uuid().v4(),
      publicDeckId: publicDeckId,
      localDeckId: localDeckId,
      userId: userId,
      importedVersion: importedVersion,
    );

    // Save to Firestore (for cross-device sync)
    if (_useRest) {
      await _restClient.setDocument(
        _userImportedDecksPath(userId),
        link.id,
        link.toMap(),
      );
    } else {
      await _userImportedDecksRef(userId).doc(link.id).set(link.toFirestore());
    }

    // Save to local SQLite where supported.
    if (!kIsWeb) {
      final db = await _localDb.database;
      await db.insert(AppConstants.tableImportedDeckLinks, link.toMap());
    }

    return link;
  }

  /// Get import link for a local deck
  Future<ImportedDeckLink?> getImportLink(String localDeckId) async {
    if (kIsWeb) return null;

    final db = await _localDb.database;
    final results = await db.query(
      AppConstants.tableImportedDeckLinks,
      where: 'local_deck_id = ?',
      whereArgs: [localDeckId],
    );

    if (results.isEmpty) return null;
    return ImportedDeckLink.fromMap(results.first);
  }

  /// Get import link by public deck ID
  Future<ImportedDeckLink?> getImportLinkByPublicDeck(String publicDeckId) async {
    if (kIsWeb) return null;

    final db = await _localDb.database;
    final results = await db.query(
      AppConstants.tableImportedDeckLinks,
      where: 'public_deck_id = ?',
      whereArgs: [publicDeckId],
    );

    if (results.isEmpty) return null;
    return ImportedDeckLink.fromMap(results.first);
  }

  /// Get all imported deck links
  Future<List<ImportedDeckLink>> getAllImportLinks() async {
    if (kIsWeb) return [];

    final db = await _localDb.database;
    final results = await db.query(AppConstants.tableImportedDeckLinks);
    return results.map((map) => ImportedDeckLink.fromMap(map)).toList();
  }

  /// Check if a public deck version has been updated
  Future<bool> hasUpdate(String publicDeckId, int currentVersion) async {
    if (_useRest) {
      try {
        final doc = await _restClient.getDocument(AppConstants.collectionPublicDecks, publicDeckId);
        if (doc == null) return false;
        final deck = PublicDeck.fromMap(doc);
        return deck.version > currentVersion;
      } catch (e) {
        debugPrint('hasUpdate REST error: $e');
        return false;
      }
    }

    final doc = await _publicDecksRef.doc(publicDeckId).get();
    if (!doc.exists) return false;

    final deck = PublicDeck.fromFirestore(doc);
    return deck.version > currentVersion;
  }

  /// Check for updates on all imported decks
  Future<List<({ImportedDeckLink link, PublicDeck deck})>> checkAllUpdates() async {
    final links = await getAllImportLinks();
    final updates = <({ImportedDeckLink link, PublicDeck deck})>[];

    for (final link in links) {
      PublicDeck? deck;

      if (_useRest) {
        try {
          final doc = await _restClient.getDocument(AppConstants.collectionPublicDecks, link.publicDeckId);
          if (doc == null) continue;
          deck = PublicDeck.fromMap(doc);
        } catch (e) {
          debugPrint('checkAllUpdates REST error: $e');
          continue;
        }
      } else {
        final doc = await _publicDecksRef.doc(link.publicDeckId).get();
        if (!doc.exists) continue;
        deck = PublicDeck.fromFirestore(doc);
      }

      if (deck.version > link.importedVersion) {
        updates.add((link: link, deck: deck));
      }
    }

    return updates;
  }

  /// Get flashcards from public deck for sync
  Future<List<PublicFlashcard>> getPublicFlashcards(String publicDeckId) async {
    if (_useRest) {
      try {
        final collectionPath = '${AppConstants.collectionPublicDecks}/$publicDeckId/${AppConstants.collectionPublicFlashcards}';
        final docs = await _restClient.getCollection(
          collectionPath,
          orderBy: [OrderBy('order')],
        );
        return docs.map((doc) => PublicFlashcard.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('getPublicFlashcards REST error: $e');
        return [];
      }
    }

    final snapshot = await _publicDecksRef
        .doc(publicDeckId)
        .collection(AppConstants.collectionPublicFlashcards)
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) => PublicFlashcard.fromFirestore(doc)).toList();
  }

  /// Update the import link after syncing
  Future<void> updateImportLink({
    required String linkId,
    required int newVersion,
  }) async {
    final userId = _authService.userId;
    final now = DateTime.now();

    // Update local SQLite where supported.
    if (!kIsWeb) {
      final db = await _localDb.database;
      await db.update(
        AppConstants.tableImportedDeckLinks,
        {
          'imported_version': newVersion,
          'last_synced_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [linkId],
      );
    }

    // Update Firestore if signed in
    if (userId != null) {
      if (_useRest) {
        await _restClient.updateDocument(
          _userImportedDecksPath(userId),
          linkId,
          {
            'imported_version': newVersion,
            'last_synced_at': now,
          },
        );
      } else {
        await _userImportedDecksRef(userId).doc(linkId).update({
          'imported_version': newVersion,
          'last_synced_at': Timestamp.fromDate(now),
        });
      }
    }
  }

  /// Delete import link (unlink from public deck)
  Future<void> deleteImportLink(String linkId) async {
    final userId = _authService.userId;

    // Delete from local SQLite where supported.
    if (!kIsWeb) {
      final db = await _localDb.database;
      await db.delete(
        AppConstants.tableImportedDeckLinks,
        where: 'id = ?',
        whereArgs: [linkId],
      );
    }

    // Delete from Firestore if signed in
    if (userId != null) {
      if (_useRest) {
        await _restClient.deleteDocument(_userImportedDecksPath(userId), linkId);
      } else {
        await _userImportedDecksRef(userId).doc(linkId).delete();
      }
    }
  }

  /// Toggle auto-sync for an import link
  Future<void> setAutoSync(String linkId, bool enabled) async {
    final userId = _authService.userId;

    // Update local SQLite where supported.
    if (!kIsWeb) {
      final db = await _localDb.database;
      await db.update(
        AppConstants.tableImportedDeckLinks,
        {'auto_sync': enabled ? 1 : 0},
        where: 'id = ?',
        whereArgs: [linkId],
      );
    }

    // Update Firestore if signed in
    if (userId != null) {
      if (_useRest) {
        await _restClient.updateDocument(
          _userImportedDecksPath(userId),
          linkId,
          {'auto_sync': enabled},
        );
      } else {
        await _userImportedDecksRef(userId).doc(linkId).update({
          'auto_sync': enabled,
        });
      }
    }
  }

  // ===== Sync Notifications =====

  /// Get unread sync notifications for current user
  Future<List<SyncNotification>> getUnreadNotifications() async {
    final userId = _authService.userId;
    if (userId == null) return [];

    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(
          AppConstants.collectionSyncNotifications,
          where: [
            QueryFilter.isEqualTo('user_id', userId),
            QueryFilter.isEqualTo('is_read', false),
          ],
          orderBy: [OrderBy('created_at', descending: true)],
          requireAuth: true,
        );
        return docs.map((doc) => SyncNotification.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('getUnreadNotifications REST error: $e');
        return [];
      }
    }

    final snapshot = await _syncNotificationsRef
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) => SyncNotification.fromFirestore(doc)).toList();
  }

  /// Get all sync notifications for current user
  Future<List<SyncNotification>> getAllNotifications({int limit = 50}) async {
    final userId = _authService.userId;
    if (userId == null) return [];

    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(
          AppConstants.collectionSyncNotifications,
          where: [QueryFilter.isEqualTo('user_id', userId)],
          orderBy: [OrderBy('created_at', descending: true)],
          limit: limit,
          requireAuth: true,
        );
        return docs.map((doc) => SyncNotification.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('getAllNotifications REST error: $e');
        return [];
      }
    }

    final snapshot = await _syncNotificationsRef
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => SyncNotification.fromFirestore(doc)).toList();
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    if (_useRest) {
      await _restClient.updateDocument(
        AppConstants.collectionSyncNotifications,
        notificationId,
        {'is_read': true},
      );
      return;
    }

    await _syncNotificationsRef.doc(notificationId).update({
      'is_read': true,
    });
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    final userId = _authService.userId;
    if (userId == null) return;

    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(
          AppConstants.collectionSyncNotifications,
          where: [
            QueryFilter.isEqualTo('user_id', userId),
            QueryFilter.isEqualTo('is_read', false),
          ],
          requireAuth: true,
        );
        for (final doc in docs) {
          await _restClient.updateDocument(
            AppConstants.collectionSyncNotifications,
            doc['id'],
            {'is_read': true},
          );
        }
        return;
      } catch (e) {
        debugPrint('markAllNotificationsRead REST error: $e');
        return;
      }
    }

    final snapshot = await _syncNotificationsRef
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  /// Delete old notifications
  Future<void> deleteOldNotifications({int daysOld = 30}) async {
    final userId = _authService.userId;
    if (userId == null) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    if (_useRest) {
      try {
        // REST API doesn't support lessThan easily, get all and filter
        final docs = await _restClient.getCollection(
          AppConstants.collectionSyncNotifications,
          where: [QueryFilter.isEqualTo('user_id', userId)],
          requireAuth: true,
        );
        for (final doc in docs) {
          final createdAt = doc['created_at'] as DateTime?;
          if (createdAt != null && createdAt.isBefore(cutoffDate)) {
            await _restClient.deleteDocument(
              AppConstants.collectionSyncNotifications,
              doc['id'],
            );
          }
        }
        return;
      } catch (e) {
        debugPrint('deleteOldNotifications REST error: $e');
        return;
      }
    }

    final snapshot = await _syncNotificationsRef
        .where('user_id', isEqualTo: userId)
        .where('created_at', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Sync imported decks from Firestore to local DB (for device sync)
  Future<void> syncImportLinksFromCloud() async {
    if (kIsWeb) return;

    final userId = _authService.userId;
    if (userId == null) return;

    List<ImportedDeckLink> cloudLinks;

    if (_useRest) {
      try {
        final docs = await _restClient.getCollection(_userImportedDecksPath(userId), requireAuth: true);
        cloudLinks = docs.map((doc) => ImportedDeckLink.fromMap(doc)).toList();
      } catch (e) {
        debugPrint('syncImportLinksFromCloud REST error: $e');
        return;
      }
    } else {
      final snapshot = await _userImportedDecksRef(userId).get();
      cloudLinks = snapshot.docs
          .map((doc) => ImportedDeckLink.fromFirestore(doc))
          .toList();
    }

    final db = await _localDb.database;

    for (final link in cloudLinks) {
      // Check if exists locally
      final existing = await db.query(
        AppConstants.tableImportedDeckLinks,
        where: 'id = ?',
        whereArgs: [link.id],
      );

      if (existing.isEmpty) {
        // Insert new link
        await db.insert(AppConstants.tableImportedDeckLinks, link.toMap());
      } else {
        // Update existing link
        await db.update(
          AppConstants.tableImportedDeckLinks,
          link.toMap(),
          where: 'id = ?',
          whereArgs: [link.id],
        );
      }
    }
  }
}
