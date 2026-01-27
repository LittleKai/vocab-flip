/// Result from dictionary API lookup
class DictionaryResult {
  final String word;
  final String? phonetic;
  final String? audioUrl;
  final List<DictionaryMeaning> meanings;
  final String? sourceLanguage;

  DictionaryResult({
    required this.word,
    this.phonetic,
    this.audioUrl,
    this.meanings = const [],
    this.sourceLanguage,
  });

  /// Get primary definition
  String? get primaryDefinition {
    if (meanings.isEmpty) return null;
    if (meanings.first.definitions.isEmpty) return null;
    return meanings.first.definitions.first.definition;
  }

  /// Get all definitions as a formatted string
  String get formattedDefinitions {
    final buffer = StringBuffer();
    for (final meaning in meanings) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('(${meaning.partOfSpeech})');
      for (var i = 0; i < meaning.definitions.length; i++) {
        buffer.writeln('${i + 1}. ${meaning.definitions[i].definition}');
        if (meaning.definitions[i].example != null) {
          buffer.writeln('   Ex: ${meaning.definitions[i].example}');
        }
      }
    }
    return buffer.toString().trim();
  }

  /// Get first example sentence
  String? get firstExample {
    for (final meaning in meanings) {
      for (final def in meaning.definitions) {
        if (def.example != null && def.example!.isNotEmpty) {
          return def.example;
        }
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'DictionaryResult(word: $word, phonetic: $phonetic, meanings: ${meanings.length})';
  }
}

class DictionaryMeaning {
  final String partOfSpeech;
  final List<DictionaryDefinition> definitions;
  final List<String> synonyms;
  final List<String> antonyms;

  DictionaryMeaning({
    required this.partOfSpeech,
    this.definitions = const [],
    this.synonyms = const [],
    this.antonyms = const [],
  });
}

class DictionaryDefinition {
  final String definition;
  final String? example;

  DictionaryDefinition({
    required this.definition,
    this.example,
  });
}

/// Result from Jisho API for Japanese words
class JishoResult {
  final String word;
  final String? reading;
  final List<JishoMeaning> meanings;
  final List<String> jlptLevels;
  final bool isCommon;

  JishoResult({
    required this.word,
    this.reading,
    this.meanings = const [],
    this.jlptLevels = const [],
    this.isCommon = false,
  });

  /// Convert to generic DictionaryResult
  DictionaryResult toDictionaryResult() {
    return DictionaryResult(
      word: word,
      phonetic: reading,
      sourceLanguage: 'ja',
      meanings: meanings.map((m) => DictionaryMeaning(
        partOfSpeech: m.partsOfSpeech.join(', '),
        definitions: m.englishDefinitions.map((d) => DictionaryDefinition(
          definition: d,
        )).toList(),
      )).toList(),
    );
  }

  String? get jlptLevel => jlptLevels.isNotEmpty ? jlptLevels.first : null;

  @override
  String toString() {
    return 'JishoResult(word: $word, reading: $reading, jlpt: $jlptLevel)';
  }
}

class JishoMeaning {
  final List<String> partsOfSpeech;
  final List<String> englishDefinitions;
  final List<String> tags;

  JishoMeaning({
    this.partsOfSpeech = const [],
    this.englishDefinitions = const [],
    this.tags = const [],
  });
}
