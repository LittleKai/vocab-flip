import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/local/preferences/app_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize preferences
  final preferences = AppPreferences();
  await preferences.init();

  // Run app
  runApp(VocabFlipApp(preferences: preferences));
}
