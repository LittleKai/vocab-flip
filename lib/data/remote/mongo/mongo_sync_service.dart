import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../api/api_client.dart';
import '../../auth/alpha_auth_session.dart';
import '../../local/database/app_database.dart';
import '../../models/imported_deck_link.dart';
import '../../models/public_deck.dart';
import '../../models/public_flashcard.dart';
import '../../models/sync_notification.dart';
import 'mongo_public_library_service.dart';
import 'vocab_api_helpers.dart';

class MongoSyncService {
  final ApiClient _apiClient = ApiClient();
  final MongoPublicLibraryService _libraryService = MongoPublicLibraryService();
  final AlphaAuthSession _authSession = AlphaAuthSession();

  Future<ImportedDeckLink> recordImport({
    required String publicDeckId,
    required String localDeckId,
    required int importedVersion,
  }) async {
    final userId = _authSession.userId;
    if (userId == null) {
      throw Exception('User must be signed in to import decks');
    }

    final response = await _apiClient.dio.post('/vocab/imports', data: {
      'public_deck_id': publicDeckId,
      'local_deck_id': localDeckId,
      'imported_version': importedVersion,
    });

    final doc = unwrapApiMap(response.data);
    final link = doc != null
        ? ImportedDeckLink.fromMap(doc)
        : ImportedDeckLink(
            id: const Uuid().v4(),
            publicDeckId: publicDeckId,
            localDeckId: localDeckId,
            userId: userId,
            importedVersion: importedVersion,
          );

    await _saveLocalLink(link);
    return link;
  }

  Future<ImportedDeckLink?> getImportLink(String localDeckId) async {
    final local = await _getLocalLinkByLocalDeck(localDeckId);
    if (local != null) return local;

    try {
      final response = await _apiClient.dio.get('/vocab/imports/by-local/$localDeckId');
      final doc = unwrapApiMap(response.data);
      return doc == null ? null : ImportedDeckLink.fromMap(doc);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        logVocabApiError('getImportLink', e);
      }
      return null;
    }
  }

  Future<ImportedDeckLink?> getImportLinkByPublicDeck(String publicDeckId) async {
    final local = await _getLocalLinkByPublicDeck(publicDeckId);
    if (local != null) return local;

    try {
      final response = await _apiClient.dio.get('/vocab/imports/by-public/$publicDeckId');
      final doc = unwrapApiMap(response.data);
      return doc == null ? null : ImportedDeckLink.fromMap(doc);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        logVocabApiError('getImportLinkByPublicDeck', e);
      }
      return null;
    }
  }

  Future<List<ImportedDeckLink>> getAllImportLinks() async {
    final local = await _getLocalLinks();
    if (local.isNotEmpty) return local;

    try {
      final response = await _apiClient.dio.get('/vocab/imports');
      return unwrapApiList(response.data)
          .map(ImportedDeckLink.fromMap)
          .toList();
    } catch (e) {
      logVocabApiError('getAllImportLinks', e);
      return [];
    }
  }

  Future<List<({ImportedDeckLink link, PublicDeck deck})>> checkAllUpdates() async {
    final links = await getAllImportLinks();
    final updates = <({ImportedDeckLink link, PublicDeck deck})>[];

    for (final link in links) {
      final deck = await _libraryService.getDeck(link.publicDeckId);
      if (deck != null && link.hasUpdate(deck.version)) {
        updates.add((link: link, deck: deck));
      }
    }

    return updates;
  }

  Future<List<PublicFlashcard>> getPublicFlashcards(String publicDeckId) {
    return _libraryService.getFlashcards(publicDeckId);
  }

  Future<void> updateImportLink({
    required String linkId,
    required int newVersion,
  }) async {
    final now = DateTime.now();
    try {
      await _apiClient.dio.patch('/vocab/imports/$linkId', data: {
        'imported_version': newVersion,
        'last_synced_at': now.toIso8601String(),
      });
    } catch (e) {
      logVocabApiError('updateImportLink', e);
    }

    if (!kIsWeb) {
      final db = await AppDatabase().database;
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
  }

  Future<void> deleteImportLink(String linkId) async {
    try {
      await _apiClient.dio.delete('/vocab/imports/$linkId');
    } catch (e) {
      logVocabApiError('deleteImportLink', e);
    }

    if (!kIsWeb) {
      final db = await AppDatabase().database;
      await db.delete(
        AppConstants.tableImportedDeckLinks,
        where: 'id = ?',
        whereArgs: [linkId],
      );
    }
  }

  Future<void> setAutoSync(String linkId, bool enabled) async {
    await _apiClient.dio.patch('/vocab/imports/$linkId', data: {
      'auto_sync': enabled,
    });
  }

  Future<List<SyncNotification>> getUnreadNotifications() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => !n.isRead).toList();
  }

  Future<List<SyncNotification>> getAllNotifications({int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '/vocab/sync/notifications',
        queryParameters: {'limit': limit},
      );
      return unwrapApiList(response.data)
          .map(SyncNotification.fromMap)
          .toList();
    } catch (e) {
      logVocabApiError('getAllNotifications', e);
      return [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _apiClient.dio.patch('/vocab/sync/notifications/$notificationId/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _apiClient.dio.post('/vocab/sync/notifications/read-all');
  }

  Future<void> _saveLocalLink(ImportedDeckLink link) async {
    if (kIsWeb) return;
    final db = await AppDatabase().database;
    await db.insert(
      AppConstants.tableImportedDeckLinks,
      link.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ImportedDeckLink?> _getLocalLinkByLocalDeck(String localDeckId) async {
    if (kIsWeb) return null;
    final db = await AppDatabase().database;
    final results = await db.query(
      AppConstants.tableImportedDeckLinks,
      where: 'local_deck_id = ?',
      whereArgs: [localDeckId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ImportedDeckLink.fromMap(results.first);
  }

  Future<ImportedDeckLink?> _getLocalLinkByPublicDeck(String publicDeckId) async {
    if (kIsWeb) return null;
    final db = await AppDatabase().database;
    final results = await db.query(
      AppConstants.tableImportedDeckLinks,
      where: 'public_deck_id = ?',
      whereArgs: [publicDeckId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ImportedDeckLink.fromMap(results.first);
  }

  Future<List<ImportedDeckLink>> _getLocalLinks() async {
    if (kIsWeb) return [];
    final db = await AppDatabase().database;
    final results = await db.query(AppConstants.tableImportedDeckLinks);
    return results.map(ImportedDeckLink.fromMap).toList();
  }
}
