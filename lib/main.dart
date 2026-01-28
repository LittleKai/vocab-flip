import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'data/local/preferences/app_preferences.dart';
import 'data/remote/firebase/category_seeder.dart';

/// Global flag to track if Firebase is available
bool isFirebaseInitialized = false;

void main() async {
  // Catch all errors to prevent silent crashes
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    // Initialize Firebase with error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isFirebaseInitialized = true;
      debugPrint('Firebase initialized successfully');

      // Skip category seeding for now - will be done on first library access
      // try {
      //   await CategorySeeder().seedIfNeeded();
      //   debugPrint('Categories seeded successfully');
      // } catch (e) {
      //   debugPrint('Failed to seed categories: $e');
      // }
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize Firebase: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('App will run in offline mode without library features');
    }

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize preferences
    final preferences = AppPreferences();
    await preferences.init();

    debugPrint('Starting VocabFlip app...');

    // Run app
    runApp(VocabFlipApp(preferences: preferences));
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}
