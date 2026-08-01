import '../models/flashcard.dart';

class AdvancedLearningScience {
  static const int fatigueTimeThresholdMs = 1000;
  static const int fatigueConsecutiveWrongThreshold = 5;

  int _consecutiveWrongRapidAnswers = 0;

  /// Semantic Shuffle
  /// Groups or separates cards based on tags so that same tags don't appear consecutively
  List<Flashcard> applySemanticShuffle(List<Flashcard> queue) {
    if (queue.isEmpty) return queue;

    // We do a simple shuffle first
    final List<Flashcard> shuffled = List.from(queue)..shuffle();

    // Then we try to separate cards that share the same tags
    List<Flashcard> result = [];
    List<Flashcard> remaining = List.from(shuffled);

    if (remaining.isNotEmpty) {
      result.add(remaining.removeAt(0));
    }

    while (remaining.isNotEmpty) {
      final lastCard = result.last;
      
      // Find a card that doesn't share tags with the last card
      int bestIndex = 0;
      for (int i = 0; i < remaining.length; i++) {
        final card = remaining[i];
        bool hasSharedTag = false;
        
        for (final tag in card.tags) {
          if (lastCard.tags.contains(tag)) {
            hasSharedTag = true;
            break;
          }
        }
        
        if (!hasSharedTag) {
          bestIndex = i;
          break;
        }
      }
      
      result.add(remaining.removeAt(bestIndex));
    }

    return result;
  }

  /// Evaluates whether the user is fatigued based on their answer speed and correctness
  bool checkFatigue(bool isCorrect, int timeToAnswerMs) {
    if (!isCorrect && timeToAnswerMs < fatigueTimeThresholdMs) {
      _consecutiveWrongRapidAnswers++;
    } else if (isCorrect || timeToAnswerMs > 2000) {
      // Reset if they answered correctly or took time to think
      _consecutiveWrongRapidAnswers = 0;
    }

    return _consecutiveWrongRapidAnswers >= fatigueConsecutiveWrongThreshold;
  }

  void resetFatigue() {
    _consecutiveWrongRapidAnswers = 0;
  }
}
