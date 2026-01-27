import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/deck_repository.dart';
import '../models/deck.dart';
import '../../core/constants/app_constants.dart';

class ImportExportService {
  final DeckRepository _deckRepository;

  ImportExportService({DeckRepository? deckRepository})
      : _deckRepository = deckRepository ?? DeckRepository();

  Future<String> exportDeck(String deckId) async {
    final data = await _deckRepository.exportDeck(deckId);
    final deck = await _deckRepository.getDeckById(deckId);

    if (deck == null) {
      throw Exception('Deck not found');
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Save to temporary file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final safeName = deck.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final filename = '${safeName}_$timestamp${AppConstants.exportFileExtension}';
    final file = File('${directory.path}/$filename');

    await file.writeAsString(jsonString);

    return file.path;
  }

  Future<void> shareDeck(String deckId) async {
    final filePath = await exportDeck(deckId);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'VocabFlip Deck Export',
    );
  }

  Future<Deck?> importDeckFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = File(result.files.first.path!);
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;

    return await _deckRepository.importDeck(json);
  }

  Future<Deck> importDeckFromJson(String jsonString, {bool overwrite = false}) async {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return await _deckRepository.importDeck(json, overwrite: overwrite);
  }

  Future<List<Deck>> exportAllDecks() async {
    final decks = await _deckRepository.getAllDecks();

    final exportData = {
      'version': AppConstants.exportVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'decks': <Map<String, dynamic>>[],
    };

    for (final deck in decks) {
      final deckExport = await _deckRepository.exportDeck(deck.id);
      final deckData = (deckExport['decks'] as List).first;
      (exportData['decks'] as List).add(deckData);
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final filename = 'vocabflip_backup_$timestamp${AppConstants.exportFileExtension}';
    final file = File('${directory.path}/$filename');

    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'VocabFlip Full Backup',
    );

    return decks;
  }

  bool validateImportData(Map<String, dynamic> json) {
    if (!json.containsKey('version')) return false;
    if (!json.containsKey('decks')) return false;

    final decks = json['decks'];
    if (decks is! List || decks.isEmpty) return false;

    final firstDeck = decks.first;
    if (firstDeck is! Map) return false;
    if (!firstDeck.containsKey('name')) return false;
    if (!firstDeck.containsKey('source_language')) return false;

    return true;
  }
}
