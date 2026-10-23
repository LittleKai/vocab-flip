import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/local/database/deck_dao.dart';
import 'package:vocabflip/data/models/deck.dart';
import 'package:vocabflip/data/remote/mongo/mongo_private_deck_service.dart';
import 'package:vocabflip/data/remote/mongo/mongo_public_library_service.dart';

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'API_URL=https://example.test/api'));
  test(
      'public card transport failure propagates rather than importing empty deck',
      () async {
    final dio = Dio()..httpClientAdapter = _FailureAdapter();
    await expectLater(
        MongoPublicLibraryService(dio: dio).getFlashcards('public'),
        throwsA(isA<DioException>()));
  });
  test('web unlink persists explicit null fields', () async {
    final service = _DeckService();
    final dao = DeckDao(mongoService: service, isWeb: true);
    await dao.updateFields(
        'deck', {'linked_public_deck_id': null, 'linked_version': null});
    final saved = await dao.getById('deck');
    expect(saved!.linkedPublicDeckId, isNull);
    expect(saved.linkedVersion, isNull);
  });
}

class _FailureAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) async =>
      ResponseBody.fromString('{}', 503);
  @override
  void close({bool force = false}) {}
}

class _DeckService extends MongoPrivateDeckService {
  Deck deck = Deck(
      id: 'deck',
      name: 'Imported',
      sourceLanguage: 'en',
      linkedPublicDeckId: 'public',
      linkedVersion: 2);
  @override
  Future<Deck?> getDeckById(String id) async => deck;
  @override
  Future<Deck?> updateDeck(Deck updated) async => deck = updated;
}
