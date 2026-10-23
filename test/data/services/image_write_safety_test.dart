import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:vocabflip/data/models/deck.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/repositories/flashcard_repository.dart';
import 'package:vocabflip/data/services/excel_service.dart';
import 'package:vocabflip/data/services/image_service.dart';
import 'package:vocabflip/presentation/providers/flashcard_provider.dart';

class FailingCardRepository extends FlashcardRepository {
  @override
  Future<void> createFlashcard(Flashcard card) async =>
      throw StateError('write failed');
  @override
  Future<void> updateFlashcard(Flashcard card) async =>
      throw StateError('write failed');
  @override
  Future<void> deleteFlashcard(String id) async =>
      throw StateError('write failed');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.testLoad(fileInput: '');
  late Directory sandbox;
  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('vocabflip-image-safety-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => sandbox.path);
  });
  tearDown(() async {
    await sandbox.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
  });

  test('failed card mutations surface failure and retain provider data',
      () async {
    final card = Flashcard(deckId: 'deck', front: 'hello', back: 'xin chao');
    final provider = FlashcardProvider(repository: FailingCardRepository());
    provider.setFlashcards([card]);
    for (final write in [
      () => provider.createFlashcard(card),
      () => provider.updateFlashcard(card),
      () => provider.deleteFlashcard(card.id),
    ]) {
      await expectLater(write(), throwsStateError);
      expect(provider.flashcards.single.id, card.id);
      expect(provider.error, contains('write failed'));
    }
  });

  test('delete only removes managed images, never an external sentinel',
      () async {
    final outside =
        await File(p.join(sandbox.path, 'sentinel.jpg')).writeAsString('keep');
    final ownedDir =
        await Directory(p.join(sandbox.path, 'flashcard_images')).create();
    final owned =
        await File(p.join(ownedDir.path, 'owned.jpg')).writeAsString('image');
    expect(await ImageService().deleteImage(outside.path), isFalse);
    expect(await outside.readAsString(), 'keep');
    expect(await ImageService().deleteImage(owned.path), isTrue);
    expect(await owned.exists(), isFalse);
  });

  test('delete rejects linked image directories pointing outside app storage',
      () async {
    final outside = await Directory(p.join(sandbox.path, 'outside')).create();
    final sentinel =
        await File(p.join(outside.path, 'sentinel.jpg')).writeAsString('keep');
    final link = await Link(p.join(sandbox.path, 'flashcard_images'))
        .create(outside.path);
    expect(await ImageService().deleteImage(p.join(link.path, 'sentinel.jpg')),
        isFalse);
    expect(await sentinel.readAsString(), 'keep');
    await link.delete();
  });

  test('delete rejects an image symlink and traversal out of managed storage',
      () async {
    final ownedDir =
        await Directory(p.join(sandbox.path, 'flashcard_images')).create();
    final sentinel =
        await File(p.join(sandbox.path, 'sentinel.jpg')).writeAsString('keep');
    final link = await Link(p.join(ownedDir.path, 'linked.jpg'))
        .create(sentinel.path);
    expect(await ImageService().deleteImage(link.path), isFalse);
    expect(await ImageService().deleteImage(
        p.join(ownedDir.path, '..', 'sentinel.jpg')), isFalse);
    expect(await sentinel.readAsString(), 'keep');
    expect(await link.exists(), isTrue);
    await link.delete();
  });

  test('XLSX rejects local image paths on both new and existing cards',
      () async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(['Word', 'Phonetic', 'Meaning', 'Image URL']
        .map(TextCellValue.new)
        .toList());
    for (final word in ['new', 'existing']) {
      sheet.appendRow([
        word,
        '',
        'meaning',
        p.join(sandbox.path, 'sentinel.jpg')
      ].map(TextCellValue.new).toList());
    }
    sheet.appendRow(['remote', '', 'meaning', 'https://example.org/image.jpg']
        .map(TextCellValue.new)
        .toList());
    final file = await File(p.join(sandbox.path, 'import.xlsx'))
        .writeAsBytes(excel.encode()!);
    final result = await ExcelService().importExcel(
        file.path,
        Deck(
            id: 'deck',
            name: 'Deck',
            sourceLanguage: 'en',
            targetLanguage: 'vi'),
        [Flashcard(deckId: 'deck', front: 'existing', back: 'old')]);
    expect(result!.newCards.map((c) => c.front), ['remote']);
    expect(result.updatedCards, isEmpty);
    expect(result.errors.length, 2);
  });
}
