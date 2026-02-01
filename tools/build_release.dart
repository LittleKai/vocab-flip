// ignore_for_file: avoid_print

import 'dart:io';
import 'package:archive/archive.dart';
import 'package:yaml/yaml.dart';

/// Tool to build Windows release and create ZIP package
/// Usage: dart run tools/build_release.dart
void main() async {
  print('===========================================');
  print('  VocabFlip Windows Release Builder');
  print('===========================================\n');

  // Get project root directory
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final projectDir = scriptDir.parent;

  // Read version from pubspec.yaml
  print('[1/4] Reading version from pubspec.yaml...');
  final pubspecFile = File('${projectDir.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('ERROR: pubspec.yaml not found!');
    exit(1);
  }

  final pubspecContent = await pubspecFile.readAsString();
  final pubspec = loadYaml(pubspecContent);
  final version = pubspec['version'] as String;
  final versionNumber = version.split('+').first; // Remove build number

  print('   Version: $versionNumber\n');

  // Run flutter build
  print('[2/4] Building Windows release...');
  print('   This may take a few minutes...\n');

  final buildResult = await Process.run(
    'flutter',
    ['build', 'windows', '--release'],
    workingDirectory: projectDir.path,
    runInShell: true,
  );

  if (buildResult.exitCode != 0) {
    print('ERROR: Build failed!');
    print(buildResult.stderr);
    exit(1);
  }

  print('   Build completed successfully!\n');

  // Locate build output
  final buildDir = Directory('${projectDir.path}/build/windows/x64/runner/Release');
  if (!buildDir.existsSync()) {
    // Try alternate path for older Flutter versions
    final altBuildDir = Directory('${projectDir.path}/build/windows/runner/Release');
    if (!altBuildDir.existsSync()) {
      print('ERROR: Build output not found!');
      print('   Expected: ${buildDir.path}');
      exit(1);
    }
  }

  print('[3/4] Creating ZIP archive...');

  // Create ZIP
  final archive = Archive();
  final buildPath = buildDir.path;

  await _addDirectoryToArchive(archive, buildDir, 'vocabflip');

  // Encode ZIP
  final zipEncoder = ZipEncoder();
  final zipData = zipEncoder.encode(archive);

  if (zipData == null) {
    print('ERROR: Failed to create ZIP!');
    exit(1);
  }

  // Save ZIP to Documents
  final outputDir = r'C:\Users\XEON\Documents';
  final zipFileName = 'vocabflip-windows-v$versionNumber.zip';
  final zipPath = '$outputDir\\$zipFileName';

  final zipFile = File(zipPath);
  await zipFile.writeAsBytes(zipData);

  final zipSizeMB = (zipFile.lengthSync() / 1024 / 1024).toStringAsFixed(2);

  print('   ZIP created: $zipPath');
  print('   Size: $zipSizeMB MB\n');

  // Open folder
  print('[4/4] Opening output folder...');
  await Process.run('explorer.exe', ['/select,', zipPath], runInShell: true);

  print('\n===========================================');
  print('  Build completed successfully!');
  print('  Output: $zipFileName');
  print('===========================================\n');
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
