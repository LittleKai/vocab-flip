import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileUtils {
  FileUtils._();

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getLocalFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  static Future<File> writeJsonFile(String filename, Map<String, dynamic> data) async {
    final file = await getLocalFile(filename);
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    return file.writeAsString(jsonString);
  }

  static Future<Map<String, dynamic>?> readJsonFile(String filename) async {
    try {
      final file = await getLocalFile(filename);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (_) {
      // File doesn't exist or is invalid
    }
    return null;
  }

  static Future<Map<String, dynamic>?> readJsonFromPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (_) {
      // File doesn't exist or is invalid
    }
    return null;
  }

  static Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
    );
  }

  static Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  static Future<bool> deleteFile(String filename) async {
    try {
      final file = await getLocalFile(filename);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      // Failed to delete
    }
    return false;
  }

  static String generateExportFilename(String deckName) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final safeName = deckName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return '${safeName}_$timestamp.json';
  }
}
