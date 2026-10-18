import 'dart:io';

final _importDirective = RegExp(r"""^\s*import\s+['"]([^'"]+)['"]""");

void main() {
  final packageDirectories = <Directory>[];
  for (final rootPath in ['apps', 'packages']) {
    final root = Directory(rootPath);
    if (!root.existsSync()) continue;

    packageDirectories.addAll(
      root
          .listSync(followLinks: false)
          .whereType<Directory>()
          .where(
            (directory) => File('${directory.path}/pubspec.yaml').existsSync(),
          ),
    );
  }
  packageDirectories.add(Directory('widgetbook'));

  final unsortedFiles = <String>[];
  for (final packageDirectory in packageDirectories) {
    final benchmarkDirectory = Directory('${packageDirectory.path}/benchmark');
    if (!benchmarkDirectory.existsSync()) continue;

    final files =
        benchmarkDirectory
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));

    for (final file in files) {
      final imports = file
          .readAsLinesSync()
          .map((line) => _importDirective.firstMatch(line)?.group(1))
          .whereType<String>()
          .toList();
      final sortedImports = [...imports]..sort();
      if (imports.join('\n') != sortedImports.join('\n')) {
        unsortedFiles.add(file.path);
      }
    }
  }

  for (final path in unsortedFiles) {
    stderr.writeln('Unsorted imports: $path');
  }
  if (unsortedFiles.isNotEmpty) exitCode = 1;
}
