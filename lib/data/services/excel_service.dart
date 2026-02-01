import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../models/flashcard.dart';
import '../models/deck.dart';

/// Exception thrown when the Excel file is in use by another process
class ExcelFileInUseException implements Exception {
  final String filePath;
  ExcelFileInUseException(this.filePath);

  @override
  String toString() => 'File is in use: $filePath';
}

/// Result of importing flashcards from Excel
class ExcelImportResult {
  final List<Flashcard> newCards;
  final List<Flashcard> updatedCards;
  final List<String> errors;
  final String? deckIdFromFile;
  final String? deckNameFromFile;

  ExcelImportResult({
    required this.newCards,
    required this.updatedCards,
    required this.errors,
    this.deckIdFromFile,
    this.deckNameFromFile,
  });

  int get totalCards => newCards.length + updatedCards.length;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasNewCards => newCards.isNotEmpty;
  bool get hasUpdatedCards => updatedCards.isNotEmpty;
}

/// Service for Excel import/export operations
class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  // Column headers (English)
  static const String _colWord = 'Word (*)';
  static const String _colPhonetic = 'Phonetic';
  static const String _colMeaning = 'Meaning (*)';
  static const String _colExample = 'Example';
  static const String _colNotes = 'Notes';
  static const String _colTags = 'Tags';
  static const String _colImageUrl = 'Image URL';

  // Column headers (Vietnamese)
  static const String _colWordVi = 'Từ vựng (*)';
  static const String _colPhoneticVi = 'Phiên âm';
  static const String _colMeaningVi = 'Nghĩa (*)';
  static const String _colExampleVi = 'Ví dụ';
  static const String _colNotesVi = 'Ghi chú';
  static const String _colTagsVi = 'Thẻ tag';
  static const String _colImageUrlVi = 'URL Hình ảnh';

  // Metadata keys
  static const String _metaDeckId = 'Deck ID';
  static const String _metaDeckName = 'Deck Name';
  static const String _metaExportDate = 'Export Date';
  static const String _metaCardCount = 'Card Count';

  /// Export deck data to Excel (includes all flashcards)
  /// [locale] should be 'vi' for Vietnamese, 'en' for English
  /// Returns the path to the generated file
  Future<String?> exportDeckToExcel(Deck deck, List<Flashcard> flashcards, {String locale = 'en'}) async {
    try {
      final excel = Excel.createExcel();

      // Create metadata sheet first (will appear first in Excel)
      final metaSheet = excel['_DeckInfo'];
      _addMetadata(metaSheet, deck, flashcards.length, locale);

      // Create data sheet with deck name
      final sheetName = _sanitizeSheetName(deck.name);
      final dataSheet = excel[sheetName];

      // Set column headers with styling
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue100,
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers = _getHeaders(locale);

      for (var i = 0; i < headers.length; i++) {
        final cell = dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Set column widths
      dataSheet.setColumnWidth(0, 25); // Word
      dataSheet.setColumnWidth(1, 20); // Phonetic
      dataSheet.setColumnWidth(2, 40); // Meaning
      dataSheet.setColumnWidth(3, 40); // Example
      dataSheet.setColumnWidth(4, 30); // Notes
      dataSheet.setColumnWidth(5, 20); // Tags
      dataSheet.setColumnWidth(6, 40); // Image URL

      // Add flashcard data
      for (var i = 0; i < flashcards.length; i++) {
        final card = flashcards[i];
        final rowIndex = i + 1;

        dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
            TextCellValue(card.front);
        dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
            TextCellValue(card.frontPhonetic ?? '');
        dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
            TextCellValue(card.back);
        dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
            TextCellValue(card.example ?? '');
        dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
            TextCellValue(card.notes ?? '');
        dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value =
            TextCellValue(card.tags.join(', '));
        dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value =
            TextCellValue(card.effectiveFrontImageUrl ?? '');
      }

      // Add instructions sheet
      final instructionsSheetName = locale == 'vi' ? 'Hướng dẫn' : 'Instructions';
      final instructionsSheet = excel[instructionsSheetName];
      _addInstructions(instructionsSheet, deck.name, locale);

      // Remove default Sheet1 (must be done after creating other sheets)
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Save file
      final bytes = excel.save();
      if (bytes == null) {
        debugPrint('ExcelService: Failed to generate Excel bytes');
        return null;
      }

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_sanitizeFileName(deck.name)}.xlsx';
      final filePath = p.join(directory.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      debugPrint('ExcelService: Exported to $filePath');

      // On Windows, open the folder containing the file
      if (!kIsWeb && Platform.isWindows) {
        await _openFolderInExplorer(directory.path);
      }

      return filePath;
    } on PathAccessException catch (e) {
      debugPrint('ExcelService: File is in use: $e');
      // Rethrow with identifiable error for UI to handle
      throw ExcelFileInUseException(e.path ?? 'unknown');
    } catch (e) {
      debugPrint('ExcelService: Error exporting to Excel: $e');
      return null;
    }
  }

  /// Get column headers based on locale
  List<String> _getHeaders(String locale) {
    if (locale == 'vi') {
      return [
        'Từ vựng (*)',
        'Phiên âm',
        'Nghĩa (*)',
        'Ví dụ',
        'Ghi chú',
        'Thẻ tag',
        'URL Hình ảnh',
      ];
    }
    return [
      _colWord,
      _colPhonetic,
      _colMeaning,
      _colExample,
      _colNotes,
      _colTags,
      _colImageUrl,
    ];
  }

  /// Add metadata sheet with deck information
  void _addMetadata(Sheet sheet, Deck deck, int cardCount, String locale) {
    final labelStyle = CellStyle(bold: true);

    final isVi = locale == 'vi';
    final metadata = [
      [_metaDeckId, deck.id],
      [isVi ? 'Tên bộ thẻ' : _metaDeckName, deck.name],
      [isVi ? 'Ngày xuất' : _metaExportDate, DateTime.now().toIso8601String()],
      [isVi ? 'Số thẻ' : _metaCardCount, cardCount.toString()],
    ];

    for (var i = 0; i < metadata.length; i++) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
      labelCell.value = TextCellValue(metadata[i][0]);
      labelCell.cellStyle = labelStyle;

      final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i));
      valueCell.value = TextCellValue(metadata[i][1]);
    }

    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 40);
  }

  /// Add instructions to the instructions sheet
  void _addInstructions(Sheet sheet, String deckName, String locale) {
    final isVi = locale == 'vi';

    final instructions = isVi
        ? [
            ['VocabFlip - Nhập/Xuất Excel'],
            [''],
            ['Bộ thẻ: $deckName'],
            [''],
            ['LƯU Ý QUAN TRỌNG:'],
            ['  - KHÔNG chỉnh sửa sheet "_DeckInfo" - nó dùng để xác định bộ thẻ'],
            ['  - Khi nhập, các thẻ có "Từ vựng" trùng sẽ được CẬP NHẬT'],
            ['  - Các từ mới sẽ được THÊM vào bộ thẻ'],
            [''],
            ['Các trường bắt buộc:'],
            ['  - Từ vựng (*): Từ hoặc cụm từ cần học (mặt trước thẻ)'],
            ['  - Nghĩa (*): Định nghĩa hoặc bản dịch (mặt sau thẻ)'],
            [''],
            ['Các trường tùy chọn:'],
            ['  - Phiên âm: Hướng dẫn phát âm (IPA hoặc ký hiệu khác)'],
            ['  - Ví dụ: Câu ví dụ sử dụng từ vựng'],
            ['  - Ghi chú: Ghi chú bổ sung hoặc mẹo ghi nhớ'],
            ['  - Thẻ tag: Các tag phân cách bởi dấu phẩy (ví dụ: "động từ, thông dụng")'],
            ['  - URL Hình ảnh: Đường dẫn URL đến hình ảnh cho thẻ'],
          ]
        : [
            ['VocabFlip - Excel Import/Export'],
            [''],
            ['Deck: $deckName'],
            [''],
            ['IMPORTANT:'],
            ['  - Do NOT change the "_DeckInfo" sheet - it identifies the deck'],
            ['  - When importing, cards with matching "Word" will be UPDATED'],
            ['  - New words will be ADDED as new cards'],
            [''],
            ['Required Fields:'],
            ['  - Word (*): The word or phrase to learn (front of card)'],
            ['  - Meaning (*): The definition or translation (back of card)'],
            [''],
            ['Optional Fields:'],
            ['  - Phonetic: Pronunciation guide (IPA or other notation)'],
            ['  - Example: Example sentence using the word'],
            ['  - Notes: Additional notes or memory tips'],
            ['  - Tags: Comma-separated tags (e.g., "verb, common, daily")'],
            ['  - Image URL: URL to an image for the card'],
          ];

    for (var i = 0; i < instructions.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
      cell.value = TextCellValue(instructions[i][0]);
      if (i == 0 || i == 4) {
        cell.cellStyle = CellStyle(bold: true, fontSize: 14);
      } else if (i == 2) {
        cell.cellStyle = CellStyle(bold: true, fontColorHex: ExcelColor.blue700);
      }
    }

    sheet.setColumnWidth(0, 65);
  }

  /// Open folder in Windows Explorer
  Future<void> _openFolderInExplorer(String folderPath) async {
    try {
      await Process.run('explorer.exe', [folderPath]);
    } catch (e) {
      debugPrint('ExcelService: Failed to open folder: $e');
    }
  }

  /// Pick and import an Excel file
  /// Returns null if cancelled or failed
  Future<ExcelImportResult?> pickAndImportExcel(
    Deck deck,
    List<Flashcard> existingCards,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('ExcelService: No file selected');
        return null;
      }

      final file = result.files.first;
      if (file.path == null) {
        debugPrint('ExcelService: File path is null');
        return null;
      }

      return await importExcel(file.path!, deck, existingCards);
    } catch (e) {
      debugPrint('ExcelService: Error picking file: $e');
      return null;
    }
  }

  /// Import flashcards from an Excel file
  /// Updates existing cards if word matches, adds new cards otherwise
  Future<ExcelImportResult?> importExcel(
    String filePath,
    Deck deck,
    List<Flashcard> existingCards,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('ExcelService: File not found: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Read metadata to verify deck
      String? deckIdFromFile;
      String? deckNameFromFile;

      if (excel.tables.containsKey('_DeckInfo')) {
        final metaSheet = excel.tables['_DeckInfo']!;
        for (final row in metaSheet.rows) {
          if (row.length >= 2) {
            final label = row[0]?.value?.toString() ?? '';
            final value = row[1]?.value?.toString() ?? '';
            if (label == _metaDeckId) deckIdFromFile = value;
            if (label == _metaDeckName) deckNameFromFile = value;
          }
        }
      }

      // Find the data sheet (not _DeckInfo or Instructions)
      Sheet? dataSheet;
      for (final sheetName in excel.tables.keys) {
        if (sheetName != '_DeckInfo' && sheetName.toLowerCase() != 'instructions') {
          dataSheet = excel.tables[sheetName];
          break;
        }
      }

      if (dataSheet == null || dataSheet.rows.isEmpty) {
        debugPrint('ExcelService: No data found in Excel file');
        return ExcelImportResult(
          newCards: [],
          updatedCards: [],
          errors: ['No data found in Excel file'],
          deckIdFromFile: deckIdFromFile,
          deckNameFromFile: deckNameFromFile,
        );
      }

      // Find column indices from header row
      final headerRow = dataSheet.rows.first;
      final columnMap = <String, int>{};

      for (var i = 0; i < headerRow.length; i++) {
        final cell = headerRow[i];
        if (cell?.value != null) {
          final header = cell!.value.toString().trim();
          columnMap[header] = i;
        }
      }

      // Get column indices (support both English and Vietnamese headers)
      final wordCol = columnMap[_colWord] ?? columnMap[_colWordVi] ?? columnMap['Word'] ?? 0;
      final phoneticCol = columnMap[_colPhonetic] ?? columnMap[_colPhoneticVi] ?? columnMap['Phonetic'];
      final meaningCol = columnMap[_colMeaning] ?? columnMap[_colMeaningVi] ?? columnMap['Meaning'] ?? 2;
      final exampleCol = columnMap[_colExample] ?? columnMap[_colExampleVi] ?? columnMap['Example'];
      final notesCol = columnMap[_colNotes] ?? columnMap[_colNotesVi] ?? columnMap['Notes'];
      final tagsCol = columnMap[_colTags] ?? columnMap[_colTagsVi] ?? columnMap['Tags'];
      final imageUrlCol = columnMap[_colImageUrl] ?? columnMap[_colImageUrlVi] ?? columnMap['Image URL'];

      final newCards = <Flashcard>[];
      final updatedCards = <Flashcard>[];
      final errors = <String>[];

      // Create a map of existing cards by word (case-insensitive)
      final existingCardsByWord = <String, Flashcard>{};
      for (final card in existingCards) {
        existingCardsByWord[card.front.toLowerCase()] = card;
      }

      // Process data rows (skip header)
      for (var rowIndex = 1; rowIndex < dataSheet.rows.length; rowIndex++) {
        final row = dataSheet.rows[rowIndex];

        try {
          // Get cell values
          final word = _getCellValue(row, wordCol);
          final meaning = _getCellValue(row, meaningCol);

          // Skip empty rows
          if (word.isEmpty && meaning.isEmpty) continue;

          // Validate required fields
          if (word.isEmpty) {
            errors.add('Row ${rowIndex + 1}: Missing word');
            continue;
          }
          if (meaning.isEmpty) {
            errors.add('Row ${rowIndex + 1}: Missing meaning for "$word"');
            continue;
          }

          // Get optional fields
          final phonetic = phoneticCol != null ? _getCellValue(row, phoneticCol) : null;
          final example = exampleCol != null ? _getCellValue(row, exampleCol) : null;
          final notes = notesCol != null ? _getCellValue(row, notesCol) : null;
          final tagsStr = tagsCol != null ? _getCellValue(row, tagsCol) : null;
          final imageUrl = imageUrlCol != null ? _getCellValue(row, imageUrlCol) : null;

          // Parse tags
          final tags = tagsStr?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

          // Check if this word already exists
          final existingCard = existingCardsByWord[word.toLowerCase()];

          if (existingCard != null) {
            // Update existing card
            final updatedCard = existingCard.copyWith(
              front: word,
              frontPhonetic: phonetic?.isNotEmpty == true ? phonetic : null,
              back: meaning,
              example: example?.isNotEmpty == true ? example : null,
              notes: notes?.isNotEmpty == true ? notes : null,
              imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
              tags: tags,
            );
            updatedCards.add(updatedCard);
          } else {
            // Create new card
            final newCard = Flashcard(
              deckId: deck.id,
              front: word,
              frontPhonetic: phonetic?.isNotEmpty == true ? phonetic : null,
              back: meaning,
              example: example?.isNotEmpty == true ? example : null,
              notes: notes?.isNotEmpty == true ? notes : null,
              imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
              tags: tags ?? [],
            );
            newCards.add(newCard);
          }
        } catch (e) {
          errors.add('Row ${rowIndex + 1}: Error processing - $e');
        }
      }

      debugPrint('ExcelService: New: ${newCards.length}, Updated: ${updatedCards.length}');

      return ExcelImportResult(
        newCards: newCards,
        updatedCards: updatedCards,
        errors: errors,
        deckIdFromFile: deckIdFromFile,
        deckNameFromFile: deckNameFromFile,
      );
    } catch (e) {
      debugPrint('ExcelService: Error importing Excel: $e');
      return ExcelImportResult(
        newCards: [],
        updatedCards: [],
        errors: ['Error reading Excel file: $e'],
      );
    }
  }

  /// Get cell value as string
  String _getCellValue(List<Data?> row, int columnIndex) {
    if (columnIndex >= row.length) return '';
    final cell = row[columnIndex];
    if (cell?.value == null) return '';
    return cell!.value.toString().trim();
  }

  /// Sanitize sheet name (max 31 chars, no special chars)
  String _sanitizeSheetName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[\\/*?\[\]:]'), '_');
    return sanitized.length > 31 ? sanitized.substring(0, 31) : sanitized;
  }

  /// Sanitize file name
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
  }
}
