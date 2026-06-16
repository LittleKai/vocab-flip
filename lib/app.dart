import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import 'presentation/providers/backup_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/admin_feedback_provider.dart';
import 'presentation/providers/ai_provider.dart';
import 'presentation/providers/stroke_practice_provider.dart';
import 'presentation/providers/payment_provider.dart';
import 'data/local/database/stroke_data_dao.dart';
import 'data/repositories/stroke_data_repository.dart';
import 'data/services/stroke_validation_service.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/deck/deck_detail_screen.dart';
import 'presentation/screens/deck/create_deck_screen.dart';
import 'presentation/screens/study/study_screen.dart';
import 'presentation/screens/library/public_deck_detail_screen.dart';
import 'presentation/screens/publish/publish_deck_screen.dart';
import 'presentation/screens/publish/manage_published_screen.dart';
import 'presentation/screens/sync/sync_notifications_screen.dart';
import 'presentation/screens/admin/admin_feedback_screen.dart';
import 'presentation/widgets/dialogs/login_dialog.dart';
import 'data/local/preferences/app_preferences.dart';
import 'core/web/web_sso.dart';

class VocabFlipApp extends StatefulWidget {
  final AppPreferences preferences;

  const VocabFlipApp({super.key, required this.preferences});

  @override
  State<VocabFlipApp> createState() => _VocabFlipAppState();
}

class _VocabFlipAppState extends State<VocabFlipApp> {
  late ProfileProvider profileProvider;
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    profileProvider = ProfileProvider(preferences: widget.preferences);
    authProvider = AuthProvider(initialToken: getStoredWebSsoToken())
      ..onSignIn = () {
        if (!kIsWeb) {
          profileProvider.loadFromRemote();
        }
      };

    // Note: StrokeDataDao initializes asynchronously when first used.
    _strokeDataDao = StrokeDataDao();
    _strokeDataRepository = StrokeDataRepository(_strokeDataDao);

    _initWebSso();
  }

  late StrokeDataDao _strokeDataDao;
  late StrokeDataRepository _strokeDataRepository;

  void _initWebSso() {
    setupWebSsoListener(onTokenReceived: (token) async {
      debugPrint('VocabFlipApp: Token received via SSO.');
      await authProvider.applyToken(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
            create: (_) => DeckProvider(preferences: widget.preferences)),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ChangeNotifierProvider(
          create: (_) => StudyProvider(preferences: widget.preferences),
        ),
        ChangeNotifierProvider(
          create: (_) => DictionaryProvider(prefs: widget.preferences),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(preferences: widget.preferences),
        ),
        ChangeNotifierProvider(
            create: (_) =>
                PublicLibraryProvider(preferences: widget.preferences)),
        ChangeNotifierProvider(create: (_) => PublishProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(
          create: (_) => UpdateProvider(),
        ),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider.value(value: profileProvider),
        ChangeNotifierProvider(
          create: (_) => AdminFeedbackProvider(preferences: widget.preferences),
        ),
        ChangeNotifierProvider(
          create: (_) => StrokePracticeProvider(
            repository: _strokeDataRepository,
            validationService: StrokeValidationService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'VocabFlip',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
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
      case '/admin-feedback':
        return MaterialPageRoute(
          builder: (_) => const AdminFeedbackScreen(),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context); // pop the dummy route
              LoginDialog.show(context);
            });
            return const Scaffold(backgroundColor: Colors.transparent);
          },
        );
      default:
        return null;
    }
  }
}
