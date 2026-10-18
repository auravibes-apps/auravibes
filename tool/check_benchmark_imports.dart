import 'dart:io';

import 'package:import_sorter/sort.dart';

void main() {
  final packageDirectories = <Directory>[];
  for (final rootPath in ['apps', 'packages']) {
    final root = Directory(rootPath);
    if (!root.existsSync()) continue;

    for (final entry in root.listSync(followLinks: false)) {
      if (entry is Directory &&
          File('${entry.path}/pubspec.yaml').existsSync()) {
        packageDirectories.add(entry);
      }
    }
  }
  packageDirectories.add(Directory('widgetbook'));

  final unsortedFiles = <String>[];
  for (final packageDirectory in packageDirectories) {
    final benchmarkDirectory = Directory('${packageDirectory.path}/benchmark');
    if (!benchmarkDirectory.existsSync()) continue;

    final pubspec = File('${packageDirectory.path}/pubspec.yaml')
        .readAsStringSync();
    final packageName = RegExp(
      r'^name:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);
    if (packageName == null) {
      throw StateError(
        'No package name in ${packageDirectory.path}/pubspec.yaml',
      );
    }

    final files =
        benchmarkDirectory
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));

    for (final file in files) {
      final sorted = sortImports(
        file.readAsLinesSync(),
        packageName,
        false,
        false,
        false,
        filePath: file.path,
      );
      if (sorted.updated) unsortedFiles.add(file.path);
    }
  }

  for (final path in unsortedFiles) {
    stderr.writeln('Unsorted imports: $path');
  }
  if (unsortedFiles.isNotEmpty) exitCode = 1;
}
