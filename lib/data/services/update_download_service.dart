import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Download progress information
class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double bytesPerSecond;

  DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    this.bytesPerSecond = 0,
  });

  double get percentage =>
      totalBytes > 0 ? (downloadedBytes / totalBytes) * 100 : 0;

  String get downloadedFormatted => _formatBytes(downloadedBytes);
  String get totalFormatted => _formatBytes(totalBytes);
  String get speedFormatted => '${_formatBytes(bytesPerSecond.round())}/s';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Service to download update files with progress tracking
class UpdateDownloadService {
  final http.Client? _client;

  UpdateDownloadService({http.Client? client}) : _client = client;

  http.Client get client => _client ?? http.Client();

  /// Download a file from URL to temp directory with progress callback
  /// Returns the path to the downloaded file, or null if failed
  Future<String?> downloadUpdate(
    String url, {
    required void Function(DownloadProgress progress) onProgress,
    void Function(String error)? onError,
  }) async {
    try {
      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(Uri.parse(url).path);
      final filePath = path.join(tempDir.path, 'vocabflip_update', fileName);

      // Create directory if needed
      final dir = Directory(path.dirname(filePath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Start download with streaming
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = 'VocabFlip-App';

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final error = 'Download failed: HTTP ${response.statusCode}';
        debugPrint('UpdateDownloadService: $error');
        onError?.call(error);
        return null;
      }

      final totalBytes = response.contentLength ?? 0;
      int downloadedBytes = 0;
      DateTime lastSpeedUpdate = DateTime.now();
      int lastBytes = 0;
      double bytesPerSecond = 0;

      // Create output file
      final file = File(filePath);
      final sink = file.openWrite();

      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;

          // Calculate speed every 500ms
          final now = DateTime.now();
          final elapsed = now.difference(lastSpeedUpdate).inMilliseconds;
          if (elapsed >= 500) {
            bytesPerSecond =
                (downloadedBytes - lastBytes) / (elapsed / 1000);
            lastSpeedUpdate = now;
            lastBytes = downloadedBytes;
          }

          onProgress(DownloadProgress(
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            bytesPerSecond: bytesPerSecond,
          ));
        }

        await sink.flush();
        await sink.close();

        debugPrint('UpdateDownloadService: Downloaded to $filePath');
        return filePath;
      } catch (e) {
        await sink.close();
        // Clean up partial file
        if (await file.exists()) {
          await file.delete();
        }
        rethrow;
      }
    } catch (e) {
      final error = 'Download error: $e';
      debugPrint('UpdateDownloadService: $error');
      onError?.call(error);
      return null;
    }
  }

  /// Clean up old update files
  Future<void> cleanupOldUpdates() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final updateDir = Directory(path.join(tempDir.path, 'vocabflip_update'));

      if (await updateDir.exists()) {
        await updateDir.delete(recursive: true);
        debugPrint('UpdateDownloadService: Cleaned up old updates');
      }
    } catch (e) {
      debugPrint('UpdateDownloadService: Cleanup error: $e');
    }
  }

  void dispose() {
    if (_client != null) {
      _client.close();
    }
  }
}
