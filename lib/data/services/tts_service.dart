import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/constants/supported_languages.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isAvailable = true;
  String _currentLanguage = 'en-US';
  bool _isSpeaking = false;
  Set<String> _availableLanguages = {};

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // setSharedInstance is only available on iOS/macOS
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await _flutterTts.setSharedInstance(true);
      }

      // Get available languages
      try {
        final languages = await _flutterTts.getLanguages;
        if (languages != null) {
          _availableLanguages = Set<String>.from(
            languages.map((l) => l.toString().toLowerCase()),
          );
          debugPrint('TTS available languages: $_availableLanguages');
        }
      } catch (e) {
        debugPrint('TTS getLanguages failed: $e');
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

  Future<bool> setLanguage(SupportedLanguage language) async {
    if (!_isAvailable) return false;

    final languageCode = _getLanguageCode(language);
    if (languageCode == _currentLanguage) return true;

    // Check if language is available
    if (!_isLanguageAvailable(languageCode)) {
      debugPrint('TTS language not available: $languageCode');
      return false;
    }

    try {
      final result = await _flutterTts.setLanguage(languageCode);
      if (result == 1) {
        _currentLanguage = languageCode;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('TTS setLanguage failed: $e');
      return false;
    }
  }

  bool _isLanguageAvailable(String languageCode) {
    if (_availableLanguages.isEmpty) return true; // Assume available if we couldn't get the list

    final code = languageCode.toLowerCase();
    final shortCode = code.split('-').first;

    // Check exact match or prefix match
    return _availableLanguages.any((l) =>
      l == code ||
      l.startsWith(shortCode) ||
      l.contains(shortCode)
    );
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

  /// Check if a language is supported for TTS
  bool isLanguageSupported(SupportedLanguage language) {
    final languageCode = _getLanguageCode(language);
    final isAvailable = _isLanguageAvailable(languageCode);
    debugPrint('TTS isLanguageSupported: $languageCode -> $isAvailable (available: $_availableLanguages)');
    return isAvailable;
  }

  /// Get list of unsupported languages from the app's supported languages
  List<SupportedLanguage> getUnsupportedLanguages() {
    if (_availableLanguages.isEmpty) return [];

    return SupportedLanguage.values
        .where((lang) => !isLanguageSupported(lang))
        .toList();
  }

  /// Check if TTS is initialized
  bool get isInitialized => _isInitialized;

  Future<void> speak(String text, {SupportedLanguage? language}) async {
    if (!_isInitialized) await init();
    if (!_isAvailable || text.isEmpty) return;

    try {
      if (language != null) {
        final success = await setLanguage(language);
        if (!success) {
          debugPrint('TTS: Language ${language.code} not available, skipping speech');
          return;
        }
      }

      // Stop any ongoing speech first
      if (_isSpeaking) {
        await _flutterTts.stop();
        _isSpeaking = false;
        // Small delay to allow stop to complete
        await Future.delayed(const Duration(milliseconds: 50));
      }

      _isSpeaking = true;
      await _flutterTts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS speak failed: $e');
    }
  }

  Future<void> stop() async {
    if (!_isAvailable || !_isSpeaking) return;
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
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
