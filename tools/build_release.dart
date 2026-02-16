// ignore_for_file: avoid_print

import 'dart:io';
import 'package:archive/archive.dart';

/// Build Android APK + Windows, copy to release/ folder
/// Usage: dart run tools/build_release.dart [android|windows|all]
///   - no argument or "all": build both
///   - "android": build Android only
///   - "windows": build Windows only
void main(List<String> args) async {
  final target = args.isEmpty ? 'all' : args.first.toLowerCase();
  final buildAndroid = target == 'all' || target == 'android';
  final buildWindows = target == 'all' || target == 'windows';

  if (!buildAndroid && !buildWindows) {
    print('Usage: dart run tools/build_release.dart [android|windows|all]');
    exit(1);
  }

  print('===========================================');
  print('  VocabFlip Release Builder');
  print('===========================================\n');

  final scriptDir = File(Platform.script.toFilePath()).parent;
  final projectDir = scriptDir.parent;

  // Create release folder
  final releaseDir = Directory('${projectDir.path}/release');
  if (!releaseDir.existsSync()) {
    releaseDir.createSync();
    print('[*] Created release/ folder\n');
  }

  var step = 1;
  final totalSteps = (buildAndroid ? 2 : 0) + (buildWindows ? 2 : 0);

  // --- Android ---
  if (buildAndroid) {
    print('[$step/$totalSteps] Building Android APK...');
    print('   This may take a few minutes...\n');
    step++;

    final buildResult = await Process.run(
      'flutter',
      ['build', 'apk', '--release'],
      workingDirectory: projectDir.path,
      runInShell: true,
    );

    if (buildResult.exitCode != 0) {
      print('ERROR: Android build failed!');
      print(buildResult.stderr);
      exit(1);
    }

    print('   Android build completed!\n');

    print('[$step/$totalSteps] Copying APK to release/...');
    step++;

    final apkSource = File(
      '${projectDir.path}/build/app/outputs/flutter-apk/app-release.apk',
    );

    if (!apkSource.existsSync()) {
      print('ERROR: APK not found at ${apkSource.path}');
      exit(1);
    }

    final apkDest = File('${releaseDir.path}/vocabflip.apk');
    apkSource.copySync(apkDest.path);

    final apkSizeMB =
        (apkDest.lengthSync() / 1024 / 1024).toStringAsFixed(2);
    print('   Copied: vocabflip.apk ($apkSizeMB MB)\n');
  }

  // --- Windows ---
  if (buildWindows) {
    print('[$step/$totalSteps] Building Windows release...');
    print('   This may take a few minutes...\n');
    step++;

    final buildResult = await Process.run(
      'flutter',
      ['build', 'windows', '--release'],
      workingDirectory: projectDir.path,
      runInShell: true,
    );

    if (buildResult.exitCode != 0) {
      print('ERROR: Windows build failed!');
      print(buildResult.stderr);
      exit(1);
    }

    print('   Windows build completed!\n');

    print('[$step/$totalSteps] Creating ZIP and copying to release/...');
    step++;

    // Find build output
    var buildDir = Directory(
      '${projectDir.path}/build/windows/x64/runner/Release',
    );
    if (!buildDir.existsSync()) {
      buildDir = Directory(
        '${projectDir.path}/build/windows/runner/Release',
      );
      if (!buildDir.existsSync()) {
        print('ERROR: Windows build output not found!');
        exit(1);
      }
    }

    // Create ZIP
    final archive = Archive();
    await _addDirectoryToArchive(archive, buildDir, 'vocabflip');

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    if (zipData == null) {
      print('ERROR: Failed to create ZIP!');
      exit(1);
    }

    final zipDest = File('${releaseDir.path}/vocabflip-windows.zip');
    await zipDest.writeAsBytes(zipData);

    final zipSizeMB =
        (zipDest.lengthSync() / 1024 / 1024).toStringAsFixed(2);
    print('   Created: vocabflip-windows.zip ($zipSizeMB MB)\n');
  }

  // Summary
  print('===========================================');
  print('  Build completed!');
  print('  Output folder: release/');
  if (buildAndroid) print('    - vocabflip.apk');
  if (buildWindows) print('    - vocabflip-windows.zip');
  print('===========================================\n');

  // Open release folder
  await Process.run(
    'explorer.exe',
    [releaseDir.path.replaceAll('/', '\\')],
    runInShell: true,
  );
}

/// Recursively add directory contents to archive
Future<void> _addDirectoryToArchive(
  Archive archive,
  Directory dir,
  String archiveBasePath,
) async {
  final entities = dir.listSync(recursive: true);

  for (final entity in entities) {
    if (entity is File) {
      final relativePath = entity.path
          .substring(dir.path.length + 1)
          .replaceAll('\\', '/');
      final archivePath = '$archiveBasePath/$relativePath';

      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
    }
  }
}
