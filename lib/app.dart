import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/deck_provider.dart';
import 'presentation/providers/flashcard_provider.dart';
import 'presentation/providers/study_provider.dart';
import 'presentation/providers/dictionary_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/public_library_provider.dart';
import 'presentation/providers/publish_provider.dart';
import 'presentation/providers/sync_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/update_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/deck/deck_detail_screen.dart';
import 'presentation/screens/deck/create_deck_screen.dart';
import 'presentation/screens/study/study_screen.dart';
import 'presentation/screens/library/public_deck_detail_screen.dart';
import 'presentation/screens/publish/publish_deck_screen.dart';
import 'presentation/screens/publish/manage_published_screen.dart';
import 'presentation/screens/sync/sync_notifications_screen.dart';
import 'data/local/preferences/app_preferences.dart';

class VocabFlipApp extends StatelessWidget {
  final AppPreferences preferences;

  const VocabFlipApp({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeckProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ChangeNotifierProvider(
          create: (_) => StudyProvider(preferences: preferences),
        ),
        ChangeNotifierProvider(
          create: (_) => DictionaryProvider(prefs: preferences),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(preferences: preferences),
        ),
        ChangeNotifierProvider(create: (_) => PublicLibraryProvider()),
        ChangeNotifierProvider(create: (_) => PublishProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(
          create: (_) => UpdateProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'VocabFlip',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // Localization setup
            locale: Locale(settings.locale),
            supportedLocales: const [
              Locale('en'),
              Locale('vi'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/deck':
        final deckId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => DeckDetailScreen(deckId: deckId),
        );
      case '/study':
        final deckId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => StudyScreen(deckId: deckId),
        );
      case '/public-deck':
        final deckId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PublicDeckDetailScreen(deckId: deckId),
        );
      case '/publish':
        final deckId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PublishDeckScreen(deckId: deckId),
        );
      case '/manage-published':
        return MaterialPageRoute(
          builder: (_) => const ManagePublishedScreen(),
        );
      case '/sync-notifications':
        return MaterialPageRoute(
          builder: (_) => const SyncNotificationsScreen(),
        );
      case '/create-deck':
        return MaterialPageRoute(
          builder: (_) => const CreateDeckScreen(),
        );
      default:
        return null;
    }
  }
}
