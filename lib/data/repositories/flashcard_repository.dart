import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../auth/alpha_auth_session.dart';
import '../local/database/flashcard_dao.dart';
import '../local/daos/sync_queue_dao.dart';
import '../models/flashcard.dart';
import '../models/sync_queue_item.dart';
import '../../core/utils/spaced_repetition.dart';
import '../../core/utils/fsrs_scheduler.dart';

class FlashcardRepository {
  final FlashcardDao _flashcardDao;
  final SyncQueueDao _syncQueueDao;

  FlashcardRepository({
    FlashcardDao? flashcardDao,
    SyncQueueDao? syncQueueDao,
  })  : _flashcardDao = flashcardDao ?? FlashcardDao(),
        _syncQueueDao = syncQueueDao ?? SyncQueueDao();

  Future<List<Flashcard>> getFlashcardsByDeckId(String deckId) async {
    return await _flashcardDao.getByDeckId(deckId);
  }

  Future<Flashcard?> getFlashcardById(String id) async {
    return await _flashcardDao.getById(id);
  }

  Future<void> createFlashcard(Flashcard flashcard) async {
    if (!kIsWeb) return _write(flashcard, 'CREATE');
    await _flashcardDao.insert(flashcard);
    await _syncQueueDao.insert(SyncQueueItem(
      id: const Uuid().v4(),
      entityType: 'flashcard',
      entityId: flashcard.id,
      operation: 'CREATE',
      payload: jsonEncode(flashcard.toMap()),
    ));
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    if (!kIsWeb) return _write(flashcard, 'UPDATE');
    await _flashcardDao.update(flashcard);
    await _syncQueueDao.insert(SyncQueueItem(
      id: const Uuid().v4(),
      entityType: 'flashcard',
      entityId: flashcard.id,
      operation: 'UPDATE',
      payload: jsonEncode(flashcard.toMap()),
    ));
  }

  Future<void> deleteFlashcard(String id) async {
    if (!kIsWeb) {
      return _syncQueueDao.writeEntities([
        SyncQueueItem(
            id: const Uuid().v4(),
            entityType: 'flashcard',
            entityId: id,
            operation: 'DELETE')
      ], (txn) async {
        await txn.delete(AppConstants.tableFlashcards,
            where: 'id = ?', whereArgs: [id]);
      }, ownerUserId: AlphaAuthSession().userId);
    }
    await _flashcardDao.delete(id);
    await _syncQueueDao.insert(SyncQueueItem(
      id: const Uuid().v4(),
      entityType: 'flashcard',
      entityId: id,
      operation: 'DELETE',
    ));
  }

  Future<List<Flashcard>> getDueFlashcards(String deckId, {int? limit}) async {
    return await _flashcardDao.getDueCards(deckId, limit: limit);
  }

  Future<List<Flashcard>> getNewFlashcards(String deckId, {int? limit}) async {
    return await _flashcardDao.getNewCards(deckId, limit: limit);
  }

  Future<List<Flashcard>> searchFlashcards(String query,
      {String? deckId}) async {
    return await _flashcardDao.search(query, deckId: deckId);
  }

  Future<int> getFlashcardCount(String deckId) async {
    return await _flashcardDao.getCountByDeckId(deckId);
  }

  Future<int> getDueCount(String deckId) async {
    return await _flashcardDao.getDueCountByDeckId(deckId);
  }

  Future<Flashcard> reviewFlashcard(
    Flashcard flashcard,
    ReviewRating rating,
  ) async {
    // Note: FSRSScheduler implements SchedulerEngine
    final SchedulerEngine scheduler = FSRSScheduler();
    final result = scheduler.review(flashcard.srsState, rating, DateTime.now());

    final updatedFlashcard = flashcard.copyWith(
      easinessFactor: result.easinessFactor,
      interval: result.interval,
      repetitions: result.repetitions,
      lapses: result.lapses,
      stability: result.stability,
      difficulty: result.difficulty,
      fsrsState: result.fsrsState,
      fsrsStep: result.fsrsStep,
      nextReviewDate: result.nextReviewDate,
      lastReviewDate: DateTime.now(),
    );

    await updateFlashcard(updatedFlashcard);
    return updatedFlashcard;
  }

  Future<void> _write(Flashcard card, String operation) async {
    await _syncQueueDao.writeEntities([
      SyncQueueItem(
          id: const Uuid().v4(),
          entityType: 'flashcard',
          entityId: card.id,
          operation: operation,
          payload: jsonEncode(card.toMap()))
    ], (txn) async {
      if (operation == 'CREATE') {
        await txn.insert(AppConstants.tableFlashcards, card.toMap());
      } else {
        await txn.update(AppConstants.tableFlashcards, card.toMap(),
            where: 'id = ?', whereArgs: [card.id]);
      }
    }, ownerUserId: AlphaAuthSession().userId);
  }

  Future<void> createFlashcardsBatch(List<Flashcard> flashcards) async {
    if (!kIsWeb) {
      return _syncQueueDao.writeEntities([
        for (final card in flashcards)
          SyncQueueItem(
              id: const Uuid().v4(),
              entityType: 'flashcard',
              entityId: card.id,
              operation: 'CREATE',
              payload: jsonEncode(card.toMap()))
      ], (txn) async {
        for (final card in flashcards) {
          await txn.insert(AppConstants.tableFlashcards, card.toMap());
        }
      }, ownerUserId: AlphaAuthSession().userId);
    }
    await _flashcardDao.insertBatch(flashcards);
    for (var f in flashcards) {
      await _syncQueueDao.insert(SyncQueueItem(
        id: const Uuid().v4(),
        entityType: 'flashcard',
        entityId: f.id,
        operation: 'CREATE',
        payload: jsonEncode(f.toMap()),
      ));
    }
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    return await _flashcardDao.getAll();
  }
}
