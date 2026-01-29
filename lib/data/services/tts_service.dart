import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/constants/supported_languages.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isAvailable = true;
  String _currentLanguage = 'en-US';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // setSharedInstance is only available on iOS/macOS
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await _flutterTts.setSharedInstance(true);
      }

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
    } catch (e) {
      // TTS not available on this platform
      _isAvailable = false;
      debugPrint('TTS initialization failed: $e');
    }
  }

  Future<void> setLanguage(SupportedLanguage language) async {
    if (!_isAvailable) return;
    final languageCode = _getLanguageCode(language);
    if (languageCode != _currentLanguage) {
      try {
        await _flutterTts.setLanguage(languageCode);
        _currentLanguage = languageCode;
      } catch (e) {
        debugPrint('TTS setLanguage failed: $e');
      }
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
    if (!_isAvailable) return;

    try {
      if (language != null) {
        await setLanguage(language);
      }

      await stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  Future<void> stop() async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop failed: $e');
    }
  }

  Future<void> pause() async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('TTS pause failed: $e');
    }
  }

  Future<List<dynamic>> getLanguages() async {
    if (!_isAvailable) return [];
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getVoices() async {
    if (!_isAvailable) return [];
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      return [];
    }
  }

  Future<void> setSpeechRate(double rate) async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('TTS setSpeechRate failed: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('TTS setVolume failed: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      debugPrint('TTS setPitch failed: $e');
    }
  }

  bool get isAvailable => _isAvailable;

  void dispose() {
    if (_isAvailable) {
      _flutterTts.stop();
    }
  }
}
