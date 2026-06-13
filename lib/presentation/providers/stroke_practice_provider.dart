import 'package:flutter/widgets.dart';
import '../../core/utils/spaced_repetition.dart';
import '../../data/models/stroke_character.dart';
import '../../data/repositories/stroke_data_repository.dart';
import '../../data/services/stroke_validation_service.dart';

enum StrokePracticeState {
  initial,
  loading,
  error,
  ready,
}

class StrokePracticeProvider extends ChangeNotifier {
  final StrokeDataRepository _repository;
  final StrokeValidationService _validationService;

  StrokePracticeProvider({
    required StrokeDataRepository repository,
    required StrokeValidationService validationService,
  })  : _repository = repository,
        _validationService = validationService;

  StrokePracticeState _state = StrokePracticeState.initial;
  StrokePracticeState get state => _state;

  StrokeCharacter? _currentCharacter;
  StrokeCharacter? get currentCharacter => _currentCharacter;

  int _activeStrokeIndex = 0;
  int get activeStrokeIndex => _activeStrokeIndex;

  int _completedStrokeCount = 0;
  int get completedStrokeCount => _completedStrokeCount;

  int _mistakeCount = 0;
  int get mistakeCount => _mistakeCount;

  StrokeValidationResult? _lastValidationResult;
  StrokeValidationResult? get lastValidationResult => _lastValidationResult;

  int _replayKey = 0;
  int get replayKey => _replayKey;

  Future<void> loadForCard({
    required String text,
    required String sourceLanguage,
  }) async {
    _state = StrokePracticeState.loading;
    _currentCharacter = null;
    _activeStrokeIndex = 0;
    _completedStrokeCount = 0;
    _mistakeCount = 0;
    _lastValidationResult = null;
    notifyListeners();

    try {
      // Typically 'text' might contain multiple characters. For this implementation,
      // we'll try to find stroke data for the first character if it's multiple.
      // Wait, let's just use the first character.
      if (text.isEmpty) {
        _state = StrokePracticeState.error;
        notifyListeners();
        return;
      }

      String searchChar = text.characters.first;
      
      final result = await _repository.lookupCharacter(searchChar, sourceLanguage);
      if (result == null) {
        _state = StrokePracticeState.error;
      } else {
        _currentCharacter = result;
        _state = StrokePracticeState.ready;
      }
    } catch (e) {
      _state = StrokePracticeState.error;
    }
    notifyListeners();
  }

  Future<StrokeValidationResult> submitStroke(List<Offset> points) async {
    if (_currentCharacter == null || _activeStrokeIndex >= _currentCharacter!.strokes.length) {
      const result = StrokeValidationResult.reject(StrokeRejection.wrongOrder); // fallback
      return result;
    }

    final result = _validationService.validateStroke(
      userPoints: points,
      expectedIndex: _activeStrokeIndex,
      character: _currentCharacter!,
    );

    _lastValidationResult = result;

    if (result.accepted) {
      _activeStrokeIndex++;
      _completedStrokeCount++;
    } else {
      _mistakeCount++;
    }

    notifyListeners();
    return result;
  }

  void replayCurrentStroke() {
    _replayKey++;
    notifyListeners();
  }

  void resetPractice() {
    _activeStrokeIndex = 0;
    _completedStrokeCount = 0;
    _mistakeCount = 0;
    _lastValidationResult = null;
    notifyListeners();
  }

  ReviewRating ratingForCompletion() {
    if (_currentCharacter == null || _completedStrokeCount < _currentCharacter!.strokes.length) {
      return ReviewRating.again;
    }

    if (_mistakeCount == 0) return ReviewRating.easy;
    if (_mistakeCount <= 2) return ReviewRating.good;
    if (_mistakeCount <= 5) return ReviewRating.hard;
    return ReviewRating.again;
  }
}
