import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbPath = Directory.current.path + '/assets/en_vi_dict.db';
  var db = await databaseFactoryFfi.openDatabase(dbPath);
  var res3 = await db.query('words', where: 'word = ?', whereArgs: ['tree']);
  var rawDef = res3.first['definition'].toString().trim();
  
  // PASTE PARSER LOGIC HERE
  String? phonetic;
  List meanings = [];
  
  final lines = rawDef.split('\n');
  String currentPartOfSpeech = '';
  List currentDefs = [];

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('@')) {
      var text = line.substring(1).trim();
      final phoneticMatch = RegExp(r'(/[^\/]+/)').firstMatch(text);
      if (phoneticMatch != null) {
        phonetic = phoneticMatch.group(1);
        text = text.replaceAll(phoneticMatch.group(1)!, '').trim();
        if (text.toLowerCase() == 'tree') {
          text = '';
        }
      }
      if (text.isNotEmpty) {
        if (text.startsWith('/')) {
          phonetic = text;
        } else {
          if (currentDefs.isNotEmpty) {
            meanings.add({'pos': currentPartOfSpeech, 'defs': List.from(currentDefs)});
            currentDefs.clear();
          }
          currentPartOfSpeech = text;
        }
      }
    } else if (line.startsWith('*')) {
      if (currentDefs.isNotEmpty) {
        meanings.add({'pos': currentPartOfSpeech, 'defs': List.from(currentDefs)});
        currentDefs.clear();
      }
      currentPartOfSpeech = line.substring(1).trim();
    } else if (line.startsWith('-')) {
      var text = line.substring(1).trim();
      if (text.isNotEmpty) {
        currentDefs.add({'def': text, 'ex': null});
      }
    } else if (line.startsWith('=')) {
      var text = line.substring(1).trim();
      final plusIndex = text.indexOf('+');
      if (plusIndex != -1) {
        text = text.replaceAll('+', ' - ');
      }
      if (currentDefs.isNotEmpty) {
        final lastDef = currentDefs.last;
        currentDefs[currentDefs.length - 1] = {
          'def': lastDef['def'],
          'ex': (lastDef['ex'] == null) ? text : '\${lastDef["ex"]}\n$text',
        };
      } else {
        currentDefs.add({'def': text, 'ex': null});
      }
    } else if (line.startsWith('!')) {
      var text = line.substring(1).trim();
      if (currentDefs.isNotEmpty) {
        meanings.add({'pos': currentPartOfSpeech, 'defs': List.from(currentDefs)});
        currentDefs.clear();
      }
      currentPartOfSpeech = 'Thành ngữ: $text';
    } else {
      if (currentDefs.isNotEmpty) {
        final lastDef = currentDefs.last;
        if (lastDef['ex'] == null) {
          currentDefs[currentDefs.length - 1] = {
            'def': '\${lastDef["def"]}\n$line',
            'ex': null,
          };
        } else {
          currentDefs[currentDefs.length - 1] = {
            'def': lastDef['def'],
            'ex': '\${lastDef["ex"]}\n$line',
          };
        }
      } else {
        currentDefs.add({'def': line, 'ex': null});
      }
    }
  }

  if (currentDefs.isNotEmpty) {
    meanings.add({'pos': currentPartOfSpeech, 'defs': currentDefs});
  }
  
  print("Phonetic: $phonetic");
  print("Meanings: $meanings");

  await db.close();
}