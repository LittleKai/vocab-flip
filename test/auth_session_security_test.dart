import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabflip/data/api/api_client.dart';
import 'package:vocabflip/data/auth/alpha_auth_session.dart';
import 'package:vocabflip/data/repositories/auth_repository.dart';
import 'package:vocabflip/presentation/providers/auth_provider.dart';
import 'package:vocabflip/presentation/providers/profile_provider.dart';
import 'package:vocabflip/data/local/preferences/app_preferences.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import 'package:vocabflip/presentation/widgets/dialogs/profile_edit_dialog.dart';

class PendingAdapter implements HttpClientAdapter {
  bool immediate = false;
  final requests = <RequestOptions>[];
  final responses = <Completer<ResponseBody>>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancelFuture) {
    requests.add(options);
    if (immediate)
      return Future.value(
          ResponseBody.fromString('{"data":{"nickname":"B"}}', 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      }));
    final response = Completer<ResponseBody>();
    responses.add(response);
    return response.future;
  }

  Future<void> waitFor(int count) async {
    for (var attempt = 0; attempt < 100 && requests.length < count; attempt++) {
      await tick();
    }
    expect(requests.length, greaterThanOrEqualTo(count));
  }

  void reply(int index, int status, String body) =>
      responses[index].complete(ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: ['application/json']
      }));
  @override
  void close({bool force = false}) {}
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 20));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient api;
  late PendingAdapter adapter;
  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:1/api');
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    api = ApiClient();
    api.onUnauthorized = null;
    await api.clearToken();
    AlphaAuthSession().clear();
    adapter = PendingAdapter();
    api.dio.httpClientAdapter = adapter;
  });
  test('logout prevents delayed getMe from restoring session', () async {
    final repository = AuthRepository();
    await api.setToken('dummy-A');
    final loading = repository.getMe();
    await adapter.waitFor(1);
    final logout = repository.logout();
    await tick();
    await adapter.waitFor(2);
    adapter.reply(1, 200, '{"success":true}');
    await logout;
    adapter.reply(
        0, 200, '{"success":true,"data":{"id":"A","email":"a@example.test"}}');
    expect(await loading, isNull);
    expect(AlphaAuthSession().userId, isNull);
    expect(await api.getToken(), isNull);
  });
  test('old 401 cannot clear new session token', () async {
    await api.setToken('dummy-A');
    final loading = api.dio.get('/vocab/profile').catchError(
        (Object e) => Response<dynamic>(requestOptions: RequestOptions()));
    await adapter.waitFor(1);
    await api.setToken('dummy-B');
    AlphaAuthSession().setUser(userId: 'B');
    adapter.reply(0, 401, '{"success":false}');
    await loading;
    expect(await api.getToken(), 'dummy-B');
    expect(AlphaAuthSession().userId, 'B');
  });
  test('signOut invalidates pending provider refresh', () async {
    final provider = AuthProvider();
    await tick();
    await api.setToken('dummy-A');
    final loading = provider.refreshProfile();
    await adapter.waitFor(1);
    final logout = provider.signOut();
    await tick();
    await adapter.waitFor(2);
    adapter.reply(1, 200, '{"success":true}');
    await logout;
    adapter.reply(
        0, 200, '{"success":true,"data":{"id":"A","email":"a@example.test"}}');
    await loading;
    expect(provider.isAuthenticated, isFalse);
    expect(provider.user, isNull);
    provider.dispose();
  });
  test('profile switches immediately and delayed A response cannot write B',
      () async {
    final preferences = AppPreferences();
    await preferences.init();
    final profile = ProfileProvider(preferences: preferences);
    await api.setToken('dummy-A');
    AlphaAuthSession().setUser(userId: 'A');
    await adapter.waitFor(1);
    await api.setToken('dummy-B');
    AlphaAuthSession().setUser(userId: 'B');
    await adapter.waitFor(2);
    adapter.reply(1, 200,
        '{"data":{"nickname":"B","updated_at":"2026-10-23T10:00:00Z"}}');
    await tick();
    adapter.reply(0, 200,
        '{"data":{"nickname":"A","updated_at":"2026-10-24T10:00:00Z"}}');
    await tick();
    expect(profile.nickname, 'B');
    AlphaAuthSession().clear();
    expect(profile.nickname, isNull);
    profile.dispose();
  });
  test('queue A cannot dispatch using B token', () async {
    await api.setToken('dummy-B');
    AlphaAuthSession().setUser(userId: 'B');
    await expectLater(
        api.dio.post('/vocab/decks',
            options: Options(extra: {'syncOwnerUserId': 'A'})),
        throwsA(isA<DioException>()));
    expect(adapter.requests, isEmpty);
  });
  test('legacy profile never uploads under a newly authenticated account',
      () async {
    final preferences = AppPreferences();
    await preferences.init();
    await preferences.setProfileNickname('unowned legacy');
    await api.setToken('dummy-B');
    final profile = ProfileProvider(preferences: preferences);
    AlphaAuthSession().setUser(userId: 'B');
    expect(profile.nickname, isNull);
    await adapter.waitFor(1);
    adapter.reply(0, 200, '{"data":{"nickname":"B"}}');
    await tick();
    expect(profile.nickname, 'B');
    profile.dispose();
  });
  testWidgets('open A profile form rejects save and avatar after switch to B',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = AppPreferences();
    await tester.runAsync(() => preferences.init());
    final auth = AuthProvider();
    await tester.pump();
    await tester.runAsync(() => api.setToken('dummy-A'));
    await tester.runAsync(
        () => preferences.setProfileJsonFor('A', '{"nickname":"A private"}'));
    AlphaAuthSession().setUser(userId: 'A');
    adapter.immediate = true;
    final profile = ProfileProvider(preferences: preferences);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                const Dialog(child: ProfileEditDialog())),
                        child: const Text('Edit'),
                      ))),
        )));
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('A private'), findsOneWidget);
    final save = tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save'))
        .onPressed!;
    final pick = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Upload image'))
        .onPressed!;
    await tester.runAsync(() => api.setToken('dummy-B'));
    AlphaAuthSession().setUser(userId: 'B');
    save();
    pick();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ProfileEditDialog), findsNothing);
    expect(
        adapter.requests.where((request) => request.method == 'PUT'), isEmpty);
    expect(profile.nickname, isNot('A private'));
    await tester.pumpWidget(const SizedBox());
    profile.dispose();
    auth.dispose();
  });
}
