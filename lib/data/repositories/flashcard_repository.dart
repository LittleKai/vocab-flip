import '../local/database/flashcard_dao.dart';
import '../models/flashcard.dart';
import '../../core/utils/spaced_repetition.dart';

class FlashcardRepository {
  final FlashcardDao _flashcardDao;

  FlashcardRepository({FlashcardDao? flashcardDao})
      : _flashcardDao = flashcardDao ?? FlashcardDao();

  Future<List<Flashcard>> getFlashcardsByDeckId(String deckId) async {
    return await _flashcardDao.getByDeckId(deckId);
  }

  Future<Flashcard?> getFlashcardById(String id) async {
    return await _flashcardDao.getById(id);
  }

  Future<void> createFlashcard(Flashcard flashcard) async {
    await _flashcardDao.insert(flashcard);
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    await _flashcardDao.update(flashcard);
  }

  Future<void> deleteFlashcard(String id) async {
    await _flashcardDao.delete(id);
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
    final result = SM2Algorithm.calculate(
      quality: SM2Algorithm.buttonToQuality(rating),
      repetitions: flashcard.repetitions,
      easinessFactor: flashcard.easinessFactor,
      interval: flashcard.interval,
    );

    final updatedFlashcard = flashcard.copyWith(
      easinessFactor: result.easinessFactor,
      interval: result.interval,
      repetitions: result.repetitions,
      nextReviewDate: result.nextReviewDate,
      lastReviewDate: DateTime.now(),
    );

    await _flashcardDao.update(updatedFlashcard);
    return updatedFlashcard;
  }

  Future<void> createFlashcardsBatch(List<Flashcard> flashcards) async {
    await _flashcardDao.insertBatch(flashcards);
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    return await _flashcardDao.getAll();
  }
}
