import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/constants/supported_languages.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isAvailable = true;
  String _currentLanguage = 'en-US';
  bool _isSpeaking = false;
  Set<String> _availableLanguages = {};
  List<Map<String, String>> _availableVoices = [];
  final Map<String, Map<String, String>> _voiceCache = {};

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
        }
      } catch (e) {
        debugPrint('[TTS] getLanguages failed: $e');
      }

      // Get available voices (important for Windows)
      try {
        final voices = await _flutterTts.getVoices;
        if (voices != null) {
          _availableVoices = [];
          for (final voice in voices) {
            if (voice is Map) {
              final name = voice['name']?.toString() ?? '';
              final locale = voice['locale']?.toString() ?? '';
              if (name.isNotEmpty && locale.isNotEmpty) {
                _availableVoices.add({'name': name, 'locale': locale});
              }
            }
          }
          _buildVoiceCache();
        }
      } catch (e) {
        debugPrint('[TTS] getVoices failed: $e');
      }

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
    } catch (e) {
      _isAvailable = false;
      debugPrint('[TTS] Initialization failed: $e');
    }
  }

  void _buildVoiceCache() {
    final languagePrefixes = {
      'en': ['en-US', 'en-GB', 'en'],
      'ja': ['ja-JP', 'ja'],
      'zh': ['zh-CN', 'zh-TW', 'zh'],
      'vi': ['vi-VN', 'vi'],
    };

    for (final entry in languagePrefixes.entries) {
      final langCode = entry.key;
      final prefixes = entry.value;

      for (final prefix in prefixes) {
        final voice = _findVoiceByLocale(prefix);
        if (voice != null) {
          _voiceCache[langCode] = voice;
          break;
        }
      }
    }
  }

  Map<String, String>? _findVoiceByLocale(String locale) {
    final localeLower = locale.toLowerCase();

    // Try exact match first
    for (final voice in _availableVoices) {
      if (voice['locale']?.toLowerCase() == localeLower) {
        return voice;
      }
    }

    // Try prefix match
    for (final voice in _availableVoices) {
      final voiceLocale = voice['locale']?.toLowerCase() ?? '';
      if (voiceLocale.startsWith(localeLower) ||
          localeLower.startsWith(voiceLocale.split('-').first)) {
        return voice;
      }
    }

    return null;
  }

  Future<bool> _setVoiceForLanguage(SupportedLanguage language) async {
    final langCode = language.code;
    final languageCode = _getLanguageCode(language);

    print('[TTS] _setVoiceForLanguage: $langCode -> $languageCode');

    // Try setLanguage first (more reliable on Windows)
    try {
      print('[TTS] Trying setLanguage($languageCode)...');
      final result = await _flutterTts.setLanguage(languageCode);
      print('[TTS] setLanguage result: $result');
      if (result == 1) {
        _currentLanguage = languageCode;

        // Also try to set voice for better quality
        final cachedVoice = _voiceCache[langCode];
        if (cachedVoice != null) {
          try {
            print('[TTS] Setting voice: ${cachedVoice['name']}');
            await _flutterTts.setVoice(cachedVoice);
            print('[TTS] Voice set successfully');
          } catch (e) {
            print('[TTS] setVoice failed (continuing with setLanguage): $e');
          }
        }
        return true;
      }
    } catch (e) {
      print('[TTS] setLanguage failed: $e');
    }

    // Fallback: try setVoice directly
    final voice = _voiceCache[langCode] ??
                  _findVoiceByLocale(languageCode) ??
                  _findVoiceByLocale(langCode);

    if (voice != null) {
      try {
        print('[TTS] Fallback: trying setVoice directly: ${voice['name']}');
        await _flutterTts.setVoice(voice);
        _currentLanguage = voice['locale'] ?? languageCode;
        _voiceCache[langCode] = voice;
        print('[TTS] setVoice succeeded');
        return true;
      } catch (e) {
        print('[TTS] setVoice fallback failed: $e');
      }
    }

    print('[TTS] WARNING: Could not set language/voice for $langCode');
    return false;
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

  bool _isLanguageAvailable(String languageCode) {
    if (_availableLanguages.isEmpty && _availableVoices.isEmpty) {
      return true;
    }

    final code = languageCode.toLowerCase();
    final shortCode = code.split('-').first;

    // Check voices first (more reliable on Windows)
    for (final voice in _availableVoices) {
      final locale = voice['locale']?.toLowerCase() ?? '';
      if (locale == code || locale.startsWith(shortCode)) {
        return true;
      }
    }

    // Check languages
    return _availableLanguages.any((l) =>
      l == code || l.startsWith(shortCode) || l.contains(shortCode)
    );
  }

  /// Check if a language is supported for TTS
  bool isLanguageSupported(SupportedLanguage language) {
    final languageCode = _getLanguageCode(language);
    return _isLanguageAvailable(languageCode);
  }

  /// Get list of unsupported languages from the app's supported languages
  List<SupportedLanguage> getUnsupportedLanguages() {
    if (_availableLanguages.isEmpty && _availableVoices.isEmpty) return [];
    return SupportedLanguage.values
        .where((lang) => !isLanguageSupported(lang))
        .toList();
  }

  bool get isInitialized => _isInitialized;

  Future<void> speak(String text, {SupportedLanguage? language}) async {
    print('[TTS] speak() called: "$text" (${language?.name ?? 'default'})');

    if (!_isInitialized) {
      print('[TTS] Not initialized, calling init()...');
      await init();
    }

    if (!_isAvailable) {
      print('[TTS] TTS not available');
      return;
    }

    if (text.isEmpty) {
      print('[TTS] Text is empty');
      return;
    }

    try {
      if (language != null) {
        final success = await _setVoiceForLanguage(language);
        print('[TTS] _setVoiceForLanguage result: $success');
      }

      if (_isSpeaking) {
        print('[TTS] Stopping previous speech...');
        await _flutterTts.stop();
        _isSpeaking = false;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('[TTS] Calling FlutterTts.speak()...');
      _isSpeaking = true;
      await _flutterTts.speak(text);
      print('[TTS] speak() completed');
    } catch (e) {
      _isSpeaking = false;
      print('[TTS] ERROR speak failed: $e');
    }
  }

  Future<void> stop() async {
    if (!_isAvailable || !_isSpeaking) return;
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('[TTS] stop failed: $e');
    }
  }

  Future<void> pause() async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('[TTS] pause failed: $e');
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
      debugPrint('[TTS] setSpeechRate failed: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('[TTS] setVolume failed: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    if (!_isAvailable) return;
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      debugPrint('[TTS] setPitch failed: $e');
    }
  }

  bool get isAvailable => _isAvailable;

  void dispose() {
    if (_isAvailable) {
      _flutterTts.stop();
    }
  }
}
