import 'dart:io';

import 'package:path/path.dart' as p;

import 'analyzed_path_groups.dart';
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
    final analyzeGroups = await analyzedPathGroups(root, paths);
    if (analyzeGroups.isEmpty) return formatExitCode;

    var analyzeExitCode = 0;
    for (final group in analyzeGroups) {
      final arguments = [
        'analyze',
        '--fatal-infos',
        '--fatal-warnings',
        '--format=machine',
        ...group,
      ];
      final result = await _runDart(dart, arguments, root);
      if (analyzeExitCode == 0) analyzeExitCode = result;
    }
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
