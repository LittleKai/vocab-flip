import 'package:flutter/foundation.dart';
import '../../local/database/offline_dict_dao.dart';
import '../../models/dictionary_result.dart';

class OfflineStardictApi {
  final OfflineDictDao _dao;
  final String sourceLanguage; // 'en', 'zh', 'ja'

  OfflineStardictApi({
    required OfflineDictDao dao,
    required this.sourceLanguage,
  }) : _dao = dao;

  Future<void> init() async {
    await _dao.init();
  }

  Future<DictionaryResult?> lookup(String word) async {
    debugPrint('[$sourceLanguage Offline API] lookup: "$word"');
    try {
      final entry = await _dao.lookup(word);
      if (entry == null) return null;
      return _parseDefinition(entry);
    } catch (e) {
      debugPrint('[$sourceLanguage Offline API] Error: $e');
      return null;
    }
  }

  Future<List<DictionaryResult>> search(String query, {int limit = 10}) async {
    try {
      final entries = await _dao.search(query, limit: limit);
      return entries.map((e) => _parseDefinition(e)).toList();
    } catch (e) {
      debugPrint('[$sourceLanguage Offline API] Error: $e');
      return [];
    }
  }

  DictionaryResult _parseDefinition(OfflineDictEntry entry) {
    final rawDef = entry.definition.trim();
    String? phonetic;
    List<DictionaryMeaning> meanings = [];
    
    final lines = rawDef.split('\n');
    String currentPartOfSpeech = '';
    List<DictionaryDefinition> currentDefs = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('@')) {
        // Could be category, part of speech or phonetic
        var text = line.substring(1).trim();
        
        // Extract phonetic if present (e.g., "tree /tri:/")
        final phoneticMatch = RegExp(r'(/[^\/]+/)').firstMatch(text);
        if (phoneticMatch != null) {
          phonetic = phoneticMatch.group(1);
          text = text.replaceAll(phoneticMatch.group(1)!, '').trim();
          // If the remaining text is just the word itself, clear it
          if (text.toLowerCase() == entry.word.toLowerCase()) {
            text = '';
          }
        }
        
        if (text.isNotEmpty) {
          if (text.startsWith('/')) {
            phonetic = text;
          } else {
            // Save previous meaning block
            if (currentDefs.isNotEmpty) {
              meanings.add(DictionaryMeaning(
                partOfSpeech: currentPartOfSpeech,
                definitions: List.from(currentDefs),
              ));
              currentDefs.clear();
            }
            currentPartOfSpeech = text;
          }
        }
      } else if (line.startsWith('*')) {
        // Part of speech
        if (currentDefs.isNotEmpty) {
          meanings.add(DictionaryMeaning(
            partOfSpeech: currentPartOfSpeech,
            definitions: List.from(currentDefs),
          ));
          currentDefs.clear();
        }
        currentPartOfSpeech = line.substring(1).trim();
      } else if (line.startsWith('-')) {
        // Definition
        var text = line.substring(1).trim();
        // Japanese/Chinese might have {phonetic} prefix
        final curlyBraceMatch = RegExp(r'^\{([^\}]+)\}\s*,?\s*(.*)$').firstMatch(text);
        if (curlyBraceMatch != null) {
          if (phonetic == null) phonetic = curlyBraceMatch.group(1);
          text = curlyBraceMatch.group(2) ?? '';
        }
        if (text.isNotEmpty) {
          currentDefs.add(DictionaryDefinition(definition: text));
        }
      } else if (line.startsWith('=')) {
        // Example
        var text = line.substring(1).trim();
        final plusIndex = text.indexOf('+');
        if (plusIndex != -1) {
          text = text.replaceAll('+', ' - ');
        }
        if (currentDefs.isNotEmpty) {
          final lastDef = currentDefs.last;
          currentDefs[currentDefs.length - 1] = DictionaryDefinition(
            definition: lastDef.definition,
            example: (lastDef.example == null) ? text : '${lastDef.example}\n$text',
          );
        } else {
          currentDefs.add(DictionaryDefinition(definition: text));
        }
      } else if (line.startsWith('!')) {
        // Idiom
        var text = line.substring(1).trim();
        if (currentDefs.isNotEmpty) {
          meanings.add(DictionaryMeaning(
            partOfSpeech: currentPartOfSpeech,
            definitions: List.from(currentDefs),
          ));
          currentDefs.clear();
        }
        currentPartOfSpeech = 'Thành ngữ: $text';
      } else {
        // Appended text to previous definition or example
        if (currentDefs.isNotEmpty) {
          final lastDef = currentDefs.last;
          if (lastDef.example == null) {
            currentDefs[currentDefs.length - 1] = DictionaryDefinition(
              definition: '${lastDef.definition}\n$line',
            );
          } else {
            currentDefs[currentDefs.length - 1] = DictionaryDefinition(
              definition: lastDef.definition,
              example: '${lastDef.example}\n$line',
            );
          }
        } else {
          currentDefs.add(DictionaryDefinition(definition: line));
        }
      }
    }

    if (currentDefs.isNotEmpty) {
      meanings.add(DictionaryMeaning(
        partOfSpeech: currentPartOfSpeech,
        definitions: currentDefs,
      ));
    }

    // Fallback if no structured meaning was parsed
    if (meanings.isEmpty && rawDef.isNotEmpty) {
      meanings.add(DictionaryMeaning(
        partOfSpeech: '',
        definitions: [DictionaryDefinition(definition: rawDef)],
      ));
    }

    return DictionaryResult(
      word: entry.word,
      phonetic: phonetic,
      sourceLanguage: sourceLanguage,
      meanings: meanings,
      dataSource: 'Offline DB (StarDict)',
    );
  }
}
