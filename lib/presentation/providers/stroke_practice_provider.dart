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

  List<StrokeCharacter> _targets = [];
  List<String> _targetGraphemes = [];

  int _activeCharacterIndex = 0;
  int _supportedCharacterCount = 0;
  int _unsupportedCharacterCount = 0;
  int _totalCompletedCharacters = 0;
  int _totalMistakeCount = 0;
  bool _isWordComplete = false;
  int _practiceGeneration = 0;

  StrokeValidationProfile _validationProfile = StrokeValidationProfile.standard;
  StrokeValidationProfile get validationProfile => _validationProfile;

  void setValidationProfile(StrokeValidationProfile profile) {
    if (_validationProfile != profile) {
      _validationProfile = profile;
      notifyListeners();
    }
  }

  StrokeCharacter? get currentCharacter =>
      _targets.isNotEmpty && _activeCharacterIndex < _targets.length
          ? _targets[_activeCharacterIndex]
          : null;

  String? get activeDisplayCharacter => _targetGraphemes.isNotEmpty &&
          _activeCharacterIndex < _targetGraphemes.length
      ? _targetGraphemes[_activeCharacterIndex]
      : null;

  int get activeCharacterIndex => _activeCharacterIndex;
  int get supportedCharacterCount => _supportedCharacterCount;
  int get unsupportedCharacterCount => _unsupportedCharacterCount;
  int get totalCompletedCharacters => _totalCompletedCharacters;
  bool get isWordComplete => _isWordComplete;

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
    _practiceGeneration++;
    _state = StrokePracticeState.loading;
    _targets = [];
    _targetGraphemes = [];
    _activeCharacterIndex = 0;
    _supportedCharacterCount = 0;
    _unsupportedCharacterCount = 0;
    _totalCompletedCharacters = 0;
    _totalMistakeCount = 0;
    _isWordComplete = false;

    _activeStrokeIndex = 0;
    _completedStrokeCount = 0;
    _mistakeCount = 0;
    _lastValidationResult = null;
    notifyListeners();

    try {
      if (text.isEmpty) {
        _state = StrokePracticeState.error;
        notifyListeners();
        return;
      }

      for (var char in text.characters) {
        if (char.trim().isEmpty) continue; // skip spaces
        final result = await _repository.lookupCharacter(char, sourceLanguage);
        if (result != null) {
          _targets.add(result);
          _targetGraphemes.add(char);
          _supportedCharacterCount++;
        } else {
          _unsupportedCharacterCount++;
        }
      }

      if (_targets.isEmpty) {
        _state = StrokePracticeState.error;
      } else {
        _state = StrokePracticeState.ready;
      }
    } catch (e) {
      _state = StrokePracticeState.error;
    }
    notifyListeners();
  }

  Future<StrokeValidationResult> submitStroke(List<Offset> points) async {
    final generation = _practiceGeneration;
    final char = currentCharacter;
    if (char == null || _activeStrokeIndex >= char.strokes.length) {
      const result =
          StrokeValidationResult.reject(StrokeRejection.wrongOrder); // fallback
      return result;
    }

    final result = _validationService.validateStroke(
      userPoints: points,
      expectedIndex: _activeStrokeIndex,
      character: char,
      profile: _validationProfile,
    );

    _lastValidationResult = result;

    if (result.accepted) {
      _activeStrokeIndex++;
      _completedStrokeCount++;

      if (_completedStrokeCount >= char.strokes.length) {
        _totalCompletedCharacters++;
        _totalMistakeCount += _mistakeCount;

        notifyListeners(); // Show final stroke

        if (_activeCharacterIndex + 1 < _targets.length) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (generation != _practiceGeneration) return result;
          _activeCharacterIndex++;
          _activeStrokeIndex = 0;
          _completedStrokeCount = 0;
          _mistakeCount = 0;
          _lastValidationResult = null;
        } else {
          _isWordComplete = true;
        }
      }
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
    _practiceGeneration++;
    _activeCharacterIndex = 0;
    _totalCompletedCharacters = 0;
    _totalMistakeCount = 0;
    _isWordComplete = false;

    _activeStrokeIndex = 0;
    _completedStrokeCount = 0;
    _mistakeCount = 0;
    _lastValidationResult = null;
    notifyListeners();
  }

  ReviewRating ratingForCompletion() {
    if (!_isWordComplete) {
      return ReviewRating.again;
    }

    if (_totalMistakeCount == 0) return ReviewRating.easy;
    if (_totalMistakeCount <= 2) return ReviewRating.good;
    if (_totalMistakeCount <= 5) return ReviewRating.hard;
    return ReviewRating.again;
  }
}
