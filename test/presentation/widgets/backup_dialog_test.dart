import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vocabflip/data/models/backup_metadata.dart';
import 'package:vocabflip/data/repositories/backup_repository.dart';
import 'package:vocabflip/l10n/app_localizations.dart';
import 'package:vocabflip/presentation/providers/backup_provider.dart';
import 'package:vocabflip/presentation/screens/settings/backup_screen.dart';
import 'package:vocabflip/presentation/widgets/backup/backup_progress_dialog.dart';
import 'package:vocabflip/presentation/widgets/dialogs/standard_dialog.dart';

class _BackupProvider extends BackupProvider {
  Completer<BackupMetadata?>? creation;

  @override
  Future<BackupMetadata?> createBackup() =>
      creation?.future ?? Future.value(null);

  @override
  bool get isConnected => true;
  @override
  BackupStatus get status => BackupStatus.connected;
  @override
  bool get isBusy => false;
  @override
  List<BackupMetadata> get backups => [
        BackupMetadata(
          id: 'backup',
          name: 'backup',
          backupVersion: '1',
          appVersion: '1',
          createdAt: DateTime(2026, 10, 22),
          deckCount: 1,
          cardCount: 1,
        )
      ];

  RestoreMode? selected;
  @override
  Future<RestoreResult?> restoreBackup(
    String backupId, {
    Future<RestoreMode?> Function()? onConflict,
  }) async {
    selected = await onConflict!();
    return const RestoreResult(
        success: false, decksRestored: 0, cardsRestored: 0, decksSkipped: 0);
  }
}

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: home,
    );

Future<void> _animate(WidgetTester tester) async {
  // Native Rive headers animate continuously, so settling never finishes.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => dotenv.testLoad(fileInput: ''));
  testWidgets('repeated confirmation taps close only the dialog',
      (tester) async {
    var callbacks = 0;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showStandardDialog<bool>(
                  context: context,
                  title: 'Confirm',
                  primaryButtonText: 'Proceed',
                  onPrimaryPressed: () => callbacks++,
                ),
                child: const Text('Open dialog'),
              ),
            ),
          )),
          child: const Text('Open page'),
        ),
      ),
    )));
    await tester.tap(find.text('Open page'));
    await _animate(tester);
    await tester.tap(find.text('Open dialog'));
    await _animate(tester);
    final confirm = tester.widget<ElevatedButton>(find.ancestor(
      of: find.text('Proceed'),
      matching: find.byType(ElevatedButton),
    ));
    // Repeated activation can arrive before the closing route is disposed.
    confirm.onPressed!();
    confirm.onPressed!();
    await _animate(tester);
    expect(callbacks, 1);
    expect(find.text('Open dialog'), findsOneWidget);
  });

  testWidgets('non-dismissible progress ignores Back', (tester) async {
    await tester.pumpWidget(_app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showStandardDialog<void>(
            context: context,
            title: 'Progress',
            barrierDismissible: false,
            customContent: const Text('Working'),
          ),
          child: const Text('Open'),
        ),
      ),
    )));
    await tester.tap(find.text('Open'));
    await _animate(tester);
    await tester.binding.handlePopRoute();
    await _animate(tester);
    expect(find.text('Working'), findsOneWidget);
  });

  for (final overlay in [false, true]) {
    testWidgets(
        'backup completion closes only its progress (overlay: $overlay)',
        (tester) async {
      final provider = _BackupProvider();
      if (overlay) provider.creation = Completer<BackupMetadata?>();
      addTearDown(provider.dispose);
      await tester.pumpWidget(ChangeNotifierProvider<BackupProvider>.value(
        value: provider,
        child: _app(const BackupScreen()),
      ));
      await _animate(tester);
      await tester.tap(find.text('Create Backup'));
      // Progress animates continuously; advance frames rather than settling it.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      if (overlay) {
        final context = tester.element(find.byType(BackupScreen));
        showStandardDialog<void>(
          context: context,
          title: 'Another dialog',
          primaryButtonText: 'Close',
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        provider.creation!.complete(null);
      }
      await _animate(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(BackupProgressContent), findsNothing);
      if (overlay) {
        expect(find.text('Another dialog'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await _animate(tester);
      }
      expect(find.byType(BackupScreen), findsOneWidget);
      expect(find.text('Available Backups'), findsOneWidget);
    });
  }

  for (final mode in RestoreMode.values) {
    testWidgets('restore dialog returns $mode and preserves its page',
        (tester) async {
      RestoreMode? selected;
      await tester.pumpWidget(_app(Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      selected = await RestoreConfirmDialog.show(context,
                          backupDate: 'today', deckCount: 1, cardCount: 1);
                    },
                    child: const Text('Open')),
              ))));
      await tester.tap(find.text('Open'));
      await _animate(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final labels = {
        RestoreMode.merge: l10n.restoreModeMerge,
        RestoreMode.replace: l10n.restoreModeReplace,
        RestoreMode.rename: l10n.restoreModeRename,
      };
      await tester.tap(find.text(labels[mode]!));
      await _animate(tester);
      await tester.tap(find.text(l10n.restore));
      await _animate(tester);
      expect(tester.takeException(), isNull);
      expect(selected, mode);
      expect(find.text('Open'), findsOneWidget);
    });
  }

  testWidgets('cancel conflict restore keeps BackupScreen open',
      (tester) async {
    final provider = _BackupProvider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<BackupProvider>.value(
      value: provider,
      child: _app(Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const BackupScreen())),
                child: const Text('Backup page'),
              )))),
    ));
    await tester.tap(find.text('Backup page'));
    await _animate(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await _animate(tester);
    await tester.tap(find.text('Restore'));
    await _animate(tester);
    await tester.tap(find.text('Restore'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Cancel'));
    await _animate(tester);
    expect(tester.takeException(), isNull);
    expect(provider.selected, isNull);
    expect(find.byType(BackupScreen), findsOneWidget);
    expect(find.text('Available Backups'), findsOneWidget);
  });
}
