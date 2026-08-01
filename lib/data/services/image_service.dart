import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import '../services/cloudinary_service.dart';

/// Service for handling flashcard images
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  static const _imageFolder = 'flashcard_images';
  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  /// Get the directory for storing flashcard images
  Future<Directory> get _imageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, _imageFolder));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  /// Pick an image from the file system
  /// Returns the path to the selected image, or null if cancelled
  Future<String?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          return file.path;
        }
      }
      return null;
    } catch (e) {
      debugPrint('ImageService: Error picking image: $e');
      return null;
    }
  }

  /// Resize an image to fit within maxWidth while maintaining aspect ratio
  /// Returns the resized image bytes
  Future<Uint8List?> resizeImage(String sourcePath, int maxWidth) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('ImageService: Source file does not exist: $sourcePath');
        return null;
      }

      final bytes = await sourceFile.readAsBytes();

      // Decode image in an isolate to avoid UI blocking
      final resizedBytes = await compute(_resizeImageIsolate, _ResizeParams(bytes, maxWidth));
      return resizedBytes;
    } catch (e) {
      debugPrint('ImageService: Error resizing image: $e');
      return null;
    }
  }

  /// Save an image to the app's local storage
  /// If maxWidth is provided, the image will be resized
  /// Returns the local path where the image was saved
  Future<String?> saveImageLocally(String sourcePath, {int? maxWidth}) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('ImageService: Source file does not exist: $sourcePath');
        return null;
      }

      final imageDir = await _imageDirectory;
      final extension = p.extension(sourcePath).toLowerCase();
      final fileName = '${const Uuid().v4()}$extension';
      final destPath = p.join(imageDir.path, fileName);

      if (maxWidth != null) {
        // Resize and save
        final resizedBytes = await resizeImage(sourcePath, maxWidth);
        if (resizedBytes != null) {
          final destFile = File(destPath);
          await destFile.writeAsBytes(resizedBytes);
          debugPrint('ImageService: Resized image saved to: $destPath');
          return destPath;
        } else {
          // Fallback to copying original if resize fails
          await sourceFile.copy(destPath);
          debugPrint('ImageService: Original image copied to: $destPath (resize failed)');
          return destPath;
        }
      } else {
        // Just copy without resizing
        await sourceFile.copy(destPath);
        debugPrint('ImageService: Image saved to: $destPath');
        return destPath;
      }
    } catch (e) {
      debugPrint('ImageService: Error saving image: $e');
      return null;
    }
  }

  /// Delete an image from local storage
  Future<bool> deleteImage(String imagePath) async {
    try {
      // Only delete if it's a local file in our image directory
      if (!imagePath.startsWith('http')) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('ImageService: Deleted image: $imagePath');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('ImageService: Error deleting image: $e');
      return false;
    }
  }

  /// Check if a string is a valid image URL
  bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return false;
      }
      // URL is valid if it has http(s) scheme
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a path is a local file that exists
  Future<bool> isValidLocalImage(String path) async {
    if (path.isEmpty || path.startsWith('http')) return false;
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Upload an image to Cloudinary (replacing old B2 logic)
  Future<String?> uploadImageToB2(String sourcePath, {int? maxWidth}) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('ImageService: Source file does not exist: $sourcePath');
        return null;
      }

      String pathToUpload = sourcePath;

      // If resize is needed, resize and save locally first
      if (maxWidth != null) {
        final resizedPath = await saveImageLocally(sourcePath, maxWidth: maxWidth);
        if (resizedPath != null) {
          pathToUpload = resizedPath;
        }
      }

      final result = await CloudinaryService().uploadImage(pathToUpload);
      if (result.success) {
        debugPrint('ImageService: Successfully uploaded to Cloudinary: ${result.url}');
        return result.url;
      } else {
        debugPrint('ImageService: Cloudinary upload failed: ${result.error}');
        return null;
      }
    } catch (e) {
      debugPrint('ImageService: Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  /// Choose how to pick and save based on alpha-studio integration
  Future<String?> pickAndSaveImage({int? maxWidth, bool useB2 = false}) async {
    final pickedPath = await pickImage();
    if (pickedPath != null) {
      if (useB2) {
        return await uploadImageToB2(pickedPath, maxWidth: maxWidth);
      } else {
        return await saveImageLocally(pickedPath, maxWidth: maxWidth);
      }
    }
    return null;
  }

  /// Clean up orphaned images (images not referenced by any flashcard)
  /// This should be called periodically or on app startup
  Future<int> cleanupOrphanedImages(List<String> usedImagePaths) async {
    try {
      final imageDir = await _imageDirectory;
      if (!await imageDir.exists()) return 0;

      int deletedCount = 0;
      final localUsedPaths = usedImagePaths
          .where((p) => !p.startsWith('http'))
          .map((p) => p.toLowerCase())
          .toSet();

      await for (final entity in imageDir.list()) {
        if (entity is File) {
          if (!localUsedPaths.contains(entity.path.toLowerCase())) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('ImageService: Cleaned up $deletedCount orphaned images');
      }
      return deletedCount;
    } catch (e) {
      debugPrint('ImageService: Error cleaning up images: $e');
      return 0;
    }
  }
}

/// Parameters for image resize isolate
class _ResizeParams {
  final Uint8List bytes;
  final int maxWidth;

  _ResizeParams(this.bytes, this.maxWidth);
}

/// Resize image in isolate to avoid blocking UI
Uint8List? _resizeImageIsolate(_ResizeParams params) {
  try {
    final image = img.decodeImage(params.bytes);
    if (image == null) return null;

    // Only resize if image is larger than maxWidth
    if (image.width <= params.maxWidth) {
      return params.bytes; // Return original if already small enough
    }

    // Calculate new height to maintain aspect ratio
    final aspectRatio = image.height / image.width;
    final newWidth = params.maxWidth;
    final newHeight = (newWidth * aspectRatio).round();

    // Resize the image
    final resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // Encode as JPEG with good quality to save space
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  } catch (e) {
    debugPrint('ImageService: Error in resize isolate: $e');
    return null;
  }
}
