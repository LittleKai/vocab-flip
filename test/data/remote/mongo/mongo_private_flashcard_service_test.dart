import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/models/flashcard.dart';
import 'package:vocabflip/data/remote/mongo/mongo_private_flashcard_service.dart';

void main() {
  test('syncFlashcardsBatch falls back to individual create calls on 404',
      () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;
    final service = MongoPrivateFlashcardService(dio: dio);
    final cards = [
      Flashcard(id: 'card-1', deckId: 'deck-1', front: 'one', back: 'mot'),
      Flashcard(id: 'card-2', deckId: 'deck-1', front: 'two', back: 'hai'),
    ];

    final synced = await service.syncFlashcardsBatch('deck-1', cards);

    expect(synced.map((card) => card.id), ['card-1', 'card-2']);
    expect(adapter.paths, [
      '/vocab/my-decks/deck-1/cards/batch',
      '/vocab/my-decks/deck-1/cards',
      '/vocab/my-decks/deck-1/cards',
    ]);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);

    if (options.path.endsWith('/cards/batch')) {
      return ResponseBody.fromString(
        jsonEncode({'success': false, 'message': 'Not found'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    final data = Map<String, dynamic>.from(options.data as Map);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
