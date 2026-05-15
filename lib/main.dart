import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'data/local/preferences/app_preferences.dart';
import 'data/local/database/chinese_dict_dao.dart';

void main() async {
  // Catch all errors to prevent silent crashes
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    // Load environment variables
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('Environment variables loaded');
    } catch (e) {
      debugPrint('Failed to load .env file: $e');
    }

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize preferences
    final preferences = AppPreferences();
    await preferences.init();

    // Initialize Chinese dictionary database (async, non-blocking)
    try {
      await ChineseDictDao.instance.init();
      debugPrint('Chinese dictionary initialized');
    } catch (e) {
      debugPrint('Failed to initialize Chinese dictionary: $e');
    }

    debugPrint('Starting VocabFlip app...');

    // Run app (UpdateProvider startup check is handled in HomeScreen)
    runApp(VocabFlipApp(preferences: preferences));
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}
