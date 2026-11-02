import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:path/path.dart' as p;

import 'dcl_analyze.dart' show dclTargetDirectories;

Future<void> main() async {
  exitCode = await _validateChangedDart();
}

List<String> dclDirectoriesForPaths(Iterable<String> paths) {
  final directories = {
    for (final path in paths)
      if (dclTargetDirectories.any((root) => path.startsWith('$root/')))
        p.dirname(path),
  };

  return directories.toList()..sort();
}

Future<int> _validateChangedDart() async {
  try {
    final rootResult = Process.runSync('git', ['rev-parse', '--show-toplevel']);
    if (rootResult.exitCode != 0) {
      stderr.write(rootResult.stderr);

      return rootResult.exitCode;
    }

    final root = Directory((rootResult.stdout as String).trim());
    final files =
        <String>{
          ..._gitPaths(root, [
            'diff',
            '--name-only',
            '--no-renames',
            '--diff-filter=ACM',
            '-z',
            'HEAD',
            '--',
            '*.dart',
          ]),
          ..._gitPaths(root, [
            'ls-files',
            '--others',
            '--exclude-standard',
            '-z',
            '--',
            '*.dart',
          ]),
        }..removeWhere(
          (path) => path.isEmpty || !File('${root.path}/$path').existsSync(),
        );
    final paths = files.toList()..sort();
    if (paths.isEmpty) {
      stdout.writeln('No changed Dart files.');

      return 0;
    }

    stdout.writeln('Checking ${paths.length} changed Dart files.');
    final dart = Platform.resolvedExecutable;
    final formatArguments = [
      'format',
      '--line-length',
      '80',
      '-o',
      'none',
      '--set-exit-if-changed',
      ...paths,
    ];
    final formatExitCode = await _runDart(dart, formatArguments, root);
    final analyzePaths = await _analyzedPaths(root, paths);
    if (analyzePaths.isEmpty) return formatExitCode;

    final analyzeArguments = [
      'analyze',
      '--fatal-infos',
      '--fatal-warnings',
      '--format=machine',
      ...analyzePaths,
    ];
    final analyzeExitCode = await _runDart(dart, analyzeArguments, root);
    final dclDirectories = dclDirectoriesForPaths(paths);
    final dclArguments = ['run', 'tool/dcl_analyze.dart', ...dclDirectories];
    final dclExitCode = dclDirectories.isEmpty
        ? 0
        : await _runDart(dart, dclArguments, root);

    if (formatExitCode != 0) return formatExitCode;
    if (analyzeExitCode != 0) return analyzeExitCode;

    return dclExitCode;
  } on Object catch (error) {
    stderr.writeln('Changed Dart preflight failed: $error');

    return 2;
  }
}

Future<List<String>> _analyzedPaths(Directory root, List<String> paths) async {
  final collection = AnalysisContextCollection(
    includedPaths: [p.normalize(root.path)],
  );
  try {
    return paths
        .where(
          (path) => collection.contexts.any(
            (context) =>
                context.contextRoot.isAnalyzed(p.join(root.path, path)),
          ),
        )
        .toList();
  } finally {
    await collection.dispose();
  }
}

List<String> _gitPaths(Directory root, List<String> arguments) {
  final result = Process.runSync('git', arguments, workingDirectory: root.path);
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      arguments,
      result.stderr as String,
      result.exitCode,
    );
  }

  return (result.stdout as String)
      .split('\u0000')
      .where((path) => path.isNotEmpty)
      .toList();
}

Future<int> _runDart(
  String executable,
  List<String> arguments,
  Directory root,
) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: root.path,
    mode: .inheritStdio,
  );

  return await process.exitCode;
}
