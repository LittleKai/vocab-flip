import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Service to install updates (Windows only)
class UpdateInstallService {
  /// Check if the current platform supports in-app updates
  static bool get isSupported =>
      !kIsWeb && Platform.isWindows;

  /// Get the current application directory
  static String get appDirectory {
    if (Platform.isWindows) {
      return path.dirname(Platform.resolvedExecutable);
    }
    return '';
  }

  /// Extract update ZIP to a temporary location
  /// Returns the extraction path, or null if failed
  Future<String?> extractUpdate(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        debugPrint('UpdateInstallService: ZIP file not found: $zipPath');
        return null;
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract to sibling directory of ZIP
      final extractDir = path.join(
        path.dirname(zipPath),
        'extracted_${DateTime.now().millisecondsSinceEpoch}',
      );

      final directory = Directory(extractDir);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      await directory.create(recursive: true);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(path.join(extractDir, filename));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory(path.join(extractDir, filename))
              .create(recursive: true);
        }
      }

      debugPrint('UpdateInstallService: Extracted to $extractDir');
      return extractDir;
    } catch (e) {
      debugPrint('UpdateInstallService: Extract error: $e');
      return null;
    }
  }

  /// Create and run update batch script (Windows)
  /// This script:
  /// 1. Waits for the app to close
  /// 2. Copies new files over old ones
  /// 3. Restarts the app
  /// 4. Deletes itself
  Future<bool> installAndRestart(String extractedPath) async {
    if (!Platform.isWindows) {
      debugPrint('UpdateInstallService: Not Windows, skipping install');
      return false;
    }

    try {
      final appDir = appDirectory;
      final exePath = Platform.resolvedExecutable;
      final exeName = path.basename(exePath);

      // Find the actual content directory (might be nested)
      String sourceDir = extractedPath;
      final extractedDir = Directory(extractedPath);
      final entries = await extractedDir.list().toList();

      // If there's only one subdirectory, use that as source
      if (entries.length == 1 && entries.first is Directory) {
        sourceDir = entries.first.path;
      }

      // Create batch script
      final batchPath = path.join(path.dirname(extractedPath), 'update.bat');

      // Use proper escaping for batch file paths
      final sourceEscaped = sourceDir.replaceAll('/', '\\');
      final appDirEscaped = appDir.replaceAll('/', '\\');
      final exePathEscaped = exePath.replaceAll('/', '\\');
      final extractedEscaped = extractedPath.replaceAll('/', '\\');

      // Note: Use """ for string interpolation to work
      final batchContent = """
@echo off
title VocabFlip Update
echo Updating VocabFlip...
echo.
echo Please wait while the update is being installed...
echo.

REM Wait for app to close (max 30 seconds)
set count=0
:waitloop
tasklist /FI "IMAGENAME eq $exeName" 2>NUL | find /I "$exeName" >NUL
if "%ERRORLEVEL%"=="0" (
    set /a count+=1
    if %count% GEQ 30 (
        echo Timeout waiting for app to close
        goto :cleanup
    )
    timeout /t 1 /nobreak >NUL
    goto :waitloop
)

REM Wait additional 2 seconds for file handles to release
timeout /t 2 /nobreak >NUL

REM Copy new files (only program files, user data in AppData is not affected)
echo Copying new files...
xcopy /E /Y /I "$sourceEscaped\\*" "$appDirEscaped\\" >NUL 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo Failed to copy files
    goto :cleanup
)

echo Update complete!
echo.
echo Starting VocabFlip...
timeout /t 1 /nobreak >NUL

REM Start the app
start "" "$exePathEscaped"

:cleanup
REM Clean up extracted files
timeout /t 2 /nobreak >NUL
rmdir /S /Q "$extractedEscaped" >NUL 2>&1

REM Delete this batch file
(goto) 2>nul & del "%~f0"
""";

      final batchFile = File(batchPath);
      await batchFile.writeAsString(batchContent);

      debugPrint('UpdateInstallService: Created batch script at $batchPath');

      // Run the batch script in a new window
      await Process.start(
        'cmd',
        ['/c', 'start', '', batchPath],
        mode: ProcessStartMode.detached,
        workingDirectory: path.dirname(batchPath),
      );

      debugPrint('UpdateInstallService: Started update script');
      return true;
    } catch (e) {
      debugPrint('UpdateInstallService: Install error: $e');
      return false;
    }
  }

  /// Verify the extracted update has the required files
  Future<bool> verifyUpdate(String extractedPath) async {
    try {
      final dir = Directory(extractedPath);
      if (!await dir.exists()) {
        return false;
      }

      // Check for the main executable
      final entries = await dir.list(recursive: true).toList();
      final hasExe = entries.any((e) =>
          e is File &&
          e.path.toLowerCase().endsWith('.exe') &&
          path.basename(e.path).toLowerCase().contains('vocabflip'));

      if (!hasExe) {
        debugPrint(
            'UpdateInstallService: No VocabFlip executable found in update');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('UpdateInstallService: Verify error: $e');
      return false;
    }
  }

  /// Clean up extracted files
  Future<void> cleanup(String extractedPath) async {
    try {
      final dir = Directory(extractedPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('UpdateInstallService: Cleanup error: $e');
    }
  }
}
