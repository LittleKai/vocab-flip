import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/cloudinary_config.dart';

/// Result of a Cloudinary upload
class CloudinaryUploadResult {
  final String? url;
  final String? error;
  final bool success;

  const CloudinaryUploadResult({this.url, this.error, required this.success});
}

/// Callback for image upload/download progress
typedef ImageProgressCallback = void Function(int completed, int total, int failed);

/// Service for uploading and downloading images via Cloudinary
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final CloudinaryAccounts _accounts = CloudinaryAccounts();
  static const _maxRetries = 2;
  static const _imageFolder = 'flashcard_images';

  /// Upload a single image to Cloudinary
  /// [localPath] - path to local file
  /// [subfolder] - optional subfolder (e.g. deckId) for organizing images
  Future<CloudinaryUploadResult> uploadImage(
    String localPath, {
    String? subfolder,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      return const CloudinaryUploadResult(
        success: false,
        error: 'File not found',
      );
    }

    final account = _accounts.getRandomAccount();

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(account.uploadUrl));
        request.fields['upload_preset'] = account.uploadPreset;

        if (subfolder != null) {
          request.fields['folder'] = 'vocabflip/$subfolder';
        } else {
          request.fields['folder'] = 'vocabflip';
        }

        request.files.add(await http.MultipartFile.fromPath('file', localPath));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          // Parse the secure_url from response
          final body = response.body;
          final urlMatch = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(body);
          if (urlMatch != null) {
            final url = urlMatch.group(1)!.replaceAll(r'\/', '/');
            return CloudinaryUploadResult(success: true, url: url);
          }
          return const CloudinaryUploadResult(
            success: false,
            error: 'Failed to parse upload response',
          );
        }

        if (attempt == _maxRetries) {
          return CloudinaryUploadResult(
            success: false,
            error: 'Upload failed with status ${response.statusCode}: ${response.body}',
          );
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: attempt + 1));
      } catch (e) {
        if (attempt == _maxRetries) {
          return CloudinaryUploadResult(
            success: false,
            error: 'Upload error: $e',
          );
        }
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }

    return const CloudinaryUploadResult(success: false, error: 'Max retries exceeded');
  }

  /// Upload multiple images sequentially
  /// Returns a map of localPath -> cloudinaryUrl (null if failed)
  Future<Map<String, String?>> uploadImages(
    List<String> paths, {
    String? subfolder,
    ImageProgressCallback? onProgress,
  }) async {
    final results = <String, String?>{};
    int completed = 0;
    int failed = 0;

    for (final path in paths) {
      final result = await uploadImage(path, subfolder: subfolder);
      if (result.success) {
        results[path] = result.url;
      } else {
        results[path] = null;
        failed++;
        debugPrint('CloudinaryService: Failed to upload $path: ${result.error}');
      }
      completed++;
      onProgress?.call(completed, paths.length, failed);
    }

    return results;
  }

  /// Download an image from a URL to local storage
  /// Returns the local file path, or null if failed
  Future<String?> downloadImage(String url, String localDir) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('CloudinaryService: Download failed with status ${response.statusCode}');
        return null;
      }

      // Determine file extension from URL or content-type
      String extension = '.jpg';
      final urlPath = Uri.parse(url).path;
      final urlExt = p.extension(urlPath).toLowerCase();
      if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(urlExt)) {
        extension = urlExt;
      }

      final fileName = '${const Uuid().v4()}$extension';
      final dir = Directory(localDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filePath = p.join(localDir, fileName);
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      debugPrint('CloudinaryService: Download error: $e');
      return null;
    }
  }

  /// Get the local image directory path (same as ImageService uses)
  Future<String> getImageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, _imageFolder));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir.path;
  }

  /// Check if a path is a local file (not a URL)
  static bool isLocalPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return !path.startsWith('http://') && !path.startsWith('https://');
  }

  /// Check if a path is a URL
  static bool isUrl(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
