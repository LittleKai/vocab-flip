import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vocabflip/data/remote/api/free_dictionary_api.dart';

void main() {
  test('maps fallback definitions, examples, and related words', () async {
    final api = FreeDictionaryApi(
        client: MockClient((_) async => http.Response(
            jsonEncode([
              {
                'word': 'hello',
                'phonetics': [
                  {'text': '/həˈləʊ/', 'audio': 'https://example.com/hello.mp3'}
                ],
                'meanings': [
                  {
                    'partOfSpeech': 'interjection',
                    'synonyms': ['hi'],
                    'antonyms': ['bye'],
                    'definitions': [
                      {
                        'definition': 'A greeting.',
                        'example': 'Hello, friend!'
                      },
                      {'definition': 'An expression of surprise.'},
                    ]
                  },
                  {
                    'partOfSpeech': 'noun',
                    'definitions': [
                      {'definition': 'A call of greeting.'}
                    ]
                  },
                ],
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'})));
    addTearDown(api.dispose);
    final result = await api.lookup('hello');
    expect(result, isNotNull);
    expect(result!.meanings, hasLength(2));
    expect(result.primaryDefinition, 'A greeting.');
    expect(result.firstExample, 'Hello, friend!');
    expect(result.meanings.first.partOfSpeech, 'interjection');
    expect(result.meanings.first.definitions, hasLength(2));
    expect(result.meanings.first.synonyms, ['hi']);
    expect(result.meanings.first.antonyms, ['bye']);
    expect(result.phonetic, '/həˈləʊ/');
    expect(result.audioUrl, 'https://example.com/hello.mp3');
  });
}
