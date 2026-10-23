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
    final imageDir =
        Directory(p.join(await appDir.resolveSymbolicLinks(), _imageFolder));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    if (!p.equals(await imageDir.resolveSymbolicLinks(), imageDir.path)) {
      throw const FileSystemException(
          'Managed image directory must not be linked');
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

      if (maxWidth != null) {
        // Resize and save as optimized JPG
        final resizedBytes = await resizeImage(sourcePath, maxWidth);
        if (resizedBytes != null) {
          final fileName = '${const Uuid().v4()}.jpg';
          final destPath = p.join(imageDir.path, fileName);
          final destFile = File(destPath);
          await destFile.writeAsBytes(resizedBytes);
          debugPrint('ImageService: Resized image saved to: $destPath');
          return destPath;
        } else {
          // Fallback to copying original if resize fails
          final extension = p.extension(sourcePath).toLowerCase();
          final fileName = '${const Uuid().v4()}$extension';
          final destPath = p.join(imageDir.path, fileName);
          await sourceFile.copy(destPath);
          debugPrint(
              'ImageService: Original image copied to: $destPath (resize failed)');
          return destPath;
        }
      } else {
        // Just copy without resizing
        final extension = p.extension(sourcePath).toLowerCase();
        final fileName = '${const Uuid().v4()}$extension';
        final destPath = p.join(imageDir.path, fileName);
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
    if (kIsWeb || !p.isAbsolute(imagePath)) return false;
    try {
      final imageDir = await _imageDirectory;
      final candidate = p.normalize(imagePath);
      if (!p.equals(p.dirname(candidate), imageDir.path) ||
          !_allowedExtensions
              .contains(p.extension(candidate).substring(1).toLowerCase()) ||
          await FileSystemEntity.type(candidate, followLinks: false) !=
              FileSystemEntityType.file) {
        return false;
      }
      final file = File(candidate);
      final resolved = await file.resolveSymbolicLinks();
      if (!p.equals(p.dirname(resolved), imageDir.path)) return false;
      await file.delete();
      return true;
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
      if (!['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) {
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

      await for (final entity in imageDir.list(followLinks: false)) {
        if (entity is File) {
          if (!localUsedPaths.contains(entity.path.toLowerCase())) {
            if (await deleteImage(entity.path)) deletedCount++;
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

    // If image is already smaller than maxWidth
    if (image.width <= params.maxWidth) {
      // If original image size is large (> 300KB), re-encode with JPEG to compress
      if (params.bytes.length > 300 * 1024) {
        return Uint8List.fromList(img.encodeJpg(image, quality: 85));
      }
      return params.bytes; // Return original if already small and compact
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
