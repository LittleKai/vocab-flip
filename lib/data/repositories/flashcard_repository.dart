import 'dart:convert';
import 'package:uuid/uuid.dart';
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

  Future<List<Flashcard>> searchFlashcards(String query, {String? deckId}) async {
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

    await _flashcardDao.update(updatedFlashcard);
    await _syncQueueDao.insert(SyncQueueItem(
      id: const Uuid().v4(),
      entityType: 'flashcard',
      entityId: updatedFlashcard.id,
      operation: 'UPDATE',
      payload: jsonEncode(updatedFlashcard.toMap()),
    ));
    return updatedFlashcard;
  }

  Future<void> createFlashcardsBatch(List<Flashcard> flashcards) async {
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
