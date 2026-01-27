import 'package:flutter_tts/flutter_tts.dart';
import '../../core/constants/supported_languages.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String _currentLanguage = 'en-US';

  Future<void> init() async {
    if (_isInitialized) return;

    await _flutterTts.setSharedInstance(true);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _isInitialized = true;
  }

  Future<void> setLanguage(SupportedLanguage language) async {
    final languageCode = _getLanguageCode(language);
    if (languageCode != _currentLanguage) {
      await _flutterTts.setLanguage(languageCode);
      _currentLanguage = languageCode;
    }
  }

  String _getLanguageCode(SupportedLanguage language) {
    switch (language) {
      case SupportedLanguage.english:
        return 'en-US';
      case SupportedLanguage.japanese:
        return 'ja-JP';
      case SupportedLanguage.chinese:
        return 'zh-CN';
      case SupportedLanguage.vietnamese:
        return 'vi-VN';
    }
  }

  Future<void> speak(String text, {SupportedLanguage? language}) async {
    if (!_isInitialized) await init();

    if (language != null) {
      await setLanguage(language);
    }

    await stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
  }

  Future<List<dynamic>> getLanguages() async {
    return await _flutterTts.getLanguages;
  }

  Future<List<dynamic>> getVoices() async {
    return await _flutterTts.getVoices;
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
  }

  void dispose() {
    _flutterTts.stop();
  }
}
