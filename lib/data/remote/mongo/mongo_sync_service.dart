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
  final Dio _dio;
  final Database? _database;
  final MongoPublicLibraryService _libraryService = MongoPublicLibraryService();
  final AlphaAuthSession _authSession = AlphaAuthSession();

  MongoSyncService({Dio? dio, Database? database})
      : _dio = dio ?? ApiClient().dio,
        _database = database;

  Future<Database> get _db async => _database ?? await AppDatabase().database;

  void _checkSession(String userId, int version) {
    if (_authSession.userId != userId || _apiClient.sessionVersion != version) {
      throw StateError('Account changed during import sync');
    }
  }

  Options _options(String userId, int version) => Options(extra: {
        'syncOwnerUserId': userId,
        'sessionVersion': version,
      });

  Future<ImportedDeckLink> recordImport({
    required String publicDeckId,
    required String localDeckId,
    required int importedVersion,
  }) async {
    final userId = _authSession.userId;
    final version = _apiClient.sessionVersion;
    if (userId == null) {
      throw Exception('User must be signed in to import decks');
    }

    try {
      final response = await _dio
          .post('/vocab/imports', options: _options(userId, version), data: {
        'public_deck_id': publicDeckId,
        'local_deck_id': localDeckId,
        'imported_version': importedVersion,
      });

      _checkSession(userId, version);
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

      if (link.userId != userId) throw StateError('Import owner mismatch');
      await _saveLocalLink(link, version);
      return link;
    } on DioException catch (e) {
      _checkSession(userId, version);
      logVocabApiError('recordImport', e);
      final link = ImportedDeckLink(
        id: const Uuid().v4(),
        publicDeckId: publicDeckId,
        localDeckId: localDeckId,
        userId: userId,
        importedVersion: importedVersion,
      );
      await _saveLocalLink(link, version);
      return link;
    }
  }

  Future<ImportedDeckLink?> getImportLink(String localDeckId) async {
    final userId = _authSession.userId;
    if (userId == null) return null;
    final version = _apiClient.sessionVersion;
    final local = await _getLocalLinkByLocalDeck(localDeckId);
    _checkSession(userId, version);
    if (local != null) return local;

    try {
      final response = await _dio.get('/vocab/imports/by-local/$localDeckId',
          options: _options(userId, version));
      _checkSession(userId, version);
      final doc = unwrapApiMap(response.data);
      final link = doc == null ? null : ImportedDeckLink.fromMap(doc);
      return link?.userId == userId ? link : null;
    } on DioException catch (e) {
      _checkSession(userId, version);
      if (e.response?.statusCode != 404) {
        logVocabApiError('getImportLink', e);
      }
      return null;
    }
  }

  Future<ImportedDeckLink?> getImportLinkByPublicDeck(
      String publicDeckId) async {
    final userId = _authSession.userId;
    if (userId == null) return null;
    final version = _apiClient.sessionVersion;

    final local = await _getLocalLinkByPublicDeck(publicDeckId);
    _checkSession(userId, version);
    if (local != null) return local;

    try {
      final response = await _dio.get('/vocab/imports/by-public/$publicDeckId',
          options: _options(userId, version));
      _checkSession(userId, version);
      final doc = unwrapApiMap(response.data);
      final link = doc == null ? null : ImportedDeckLink.fromMap(doc);
      return link?.userId == userId ? link : null;
    } on DioException catch (e) {
      _checkSession(userId, version);
      if (e.response?.statusCode != 404 && e.response?.statusCode != 401) {
        logVocabApiError('getImportLinkByPublicDeck', e);
      }
      return null;
    }
  }

  Future<List<ImportedDeckLink>> getAllImportLinks() async {
    final userId = _authSession.userId;
    if (userId == null) return [];
    final version = _apiClient.sessionVersion;
    final local = await _getLocalLinks();
    _checkSession(userId, version);
    if (local.isNotEmpty) return local;

    try {
      final response =
          await _dio.get('/vocab/imports', options: _options(userId, version));
      _checkSession(userId, version);
      return unwrapApiList(response.data)
          .map(ImportedDeckLink.fromMap)
          .where((link) => link.userId == userId)
          .toList();
    } catch (e) {
      _checkSession(userId, version);
      logVocabApiError('getAllImportLinks', e);
      return [];
    }
  }

  Future<List<({ImportedDeckLink link, PublicDeck deck})>>
      checkAllUpdates() async {
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
    final userId = _authSession.userId;
    if (userId == null) {
      throw StateError('Sign in before updating import links');
    }
    final version = _apiClient.sessionVersion;
    final now = DateTime.now();
    try {
      await _dio.patch('/vocab/imports/$linkId',
          options: _options(userId, version),
          data: {
            'imported_version': newVersion,
            'last_synced_at': now.toIso8601String(),
          });
    } catch (e) {
      _checkSession(userId, version);
      logVocabApiError('updateImportLink', e);
    }
    _checkSession(userId, version);

    if (!kIsWeb) {
      final db = await _db;
      _checkSession(userId, version);
      await db.update(
        AppConstants.tableImportedDeckLinks,
        {
          'imported_version': newVersion,
          'last_synced_at': now.toIso8601String(),
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [linkId, userId],
      );
    }
  }

  Future<void> deleteImportLink(String linkId) async {
    final userId = _authSession.userId;
    if (userId == null) {
      throw StateError('Sign in before deleting import links');
    }
    final version = _apiClient.sessionVersion;
    try {
      await _dio.delete('/vocab/imports/$linkId',
          options: _options(userId, version));
    } catch (e) {
      _checkSession(userId, version);
      logVocabApiError('deleteImportLink', e);
    }
    _checkSession(userId, version);

    if (!kIsWeb) {
      final db = await _db;
      _checkSession(userId, version);
      await db.delete(
        AppConstants.tableImportedDeckLinks,
        where: 'id = ? AND user_id = ?',
        whereArgs: [linkId, userId],
      );
    }
  }

  Future<void> setAutoSync(String linkId, bool enabled) async {
    await _dio.patch('/vocab/imports/$linkId', data: {
      'auto_sync': enabled,
    });
  }

  Future<List<SyncNotification>> getUnreadNotifications() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => !n.isRead).toList();
  }

  Future<List<SyncNotification>> getAllNotifications({int limit = 50}) async {
    try {
      final response = await _dio.get(
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
    await _dio.patch('/vocab/sync/notifications/$notificationId/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.post('/vocab/sync/notifications/read-all');
  }

  Future<void> _saveLocalLink(ImportedDeckLink link, int version) async {
    if (kIsWeb) return;
    final db = await _db;
    _checkSession(link.userId, version);
    await db.insert(
      AppConstants.tableImportedDeckLinks,
      link.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ImportedDeckLink?> _getLocalLinkByLocalDeck(String localDeckId) async {
    if (kIsWeb) return null;
    final userId = _authSession.userId;
    final db = await _db;
    final results = await db.query(
      AppConstants.tableImportedDeckLinks,
      where: 'local_deck_id = ? AND user_id = ?',
      whereArgs: [localDeckId, userId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ImportedDeckLink.fromMap(results.first);
  }

  Future<ImportedDeckLink?> _getLocalLinkByPublicDeck(
      String publicDeckId) async {
    if (kIsWeb) return null;
    final userId = _authSession.userId;
    final db = await _db;
    final results = await db.query(
      AppConstants.tableImportedDeckLinks,
      where: 'public_deck_id = ? AND user_id = ?',
      whereArgs: [publicDeckId, userId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ImportedDeckLink.fromMap(results.first);
  }

  Future<List<ImportedDeckLink>> _getLocalLinks() async {
    if (kIsWeb) return [];
    final userId = _authSession.userId;
    final db = await _db;
    final results = await db.query(AppConstants.tableImportedDeckLinks,
        where: 'user_id = ?', whereArgs: [userId]);
    return results.map(ImportedDeckLink.fromMap).toList();
  }
}
