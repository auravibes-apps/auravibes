import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:path/path.dart' as p;

import 'changed_test_selector.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runLocalPreflight(arguments);
}

Future<int> runLocalPreflight(List<String> arguments) async {
  final _Options options;
  try {
    options = _Options.parse(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln('local-preflight: $error')
      ..writeln(_usage);

    return 2;
  }
  if (options.help) {
    stdout.writeln(_usage);

    return 0;
  }

  final rootResult = Process.runSync('git', ['rev-parse', '--show-toplevel']);
  if (rootResult.exitCode != 0) {
    stderr.write(rootResult.stderr);

    return rootResult.exitCode;
  }
  final root = Directory((rootResult.stdout as String).trim());
  if (options.fullValidation) {
    const command = ['dart', 'run', 'melos', 'run', 'validate'];
    stdout
      ..writeln('Full workspace validation was explicitly requested.')
      ..writeln(_formatCommand('fvm', command));
    if (options.dryRun) return 0;

    return await _run('fvm', command, root);
  }

  final List<ChangedFile> changes;
  try {
    changes = await _workingTreeChanges(root, options.base);
  } on Object catch (error) {
    stderr.writeln('local-preflight: cannot inspect changes: $error');

    return 2;
  }
  final sortedChanges = changes.toList()
    ..sort((left, right) => _changeLabel(left).compareTo(_changeLabel(right)));
  final changedDartPaths = _existingChangedDartPaths(root, sortedChanges);
  final analyzePaths = await _analyzedPaths(root, changedDartPaths);
  final selection = await selectRepository(
    rootPath: root.path,
    base: options.base,
    head: 'HEAD',
    includeWorkingTree: true,
  );

  stdout
    ..writeln(
      'Base: ${options.base} (working tree, including untracked files)',
    )
    ..writeln('Changed files: ${sortedChanges.length}');
  for (final change in sortedChanges) {
    stdout.writeln('  ${_changeLabel(change)}');
  }
  stdout.writeln(
    'Test selection: ${selection.mode.name} - '
    '${selection.reason.replaceAll(root.path, '.')}',
  );
  if (selection.mode == SelectionMode.full) {
    stdout.writeln(
      'Fallback: the selector chose workspace tests because it could not '
      'safely narrow this change. Full validation remains opt-in with '
      '--full-validation.',
    );
  }

  final dart = Platform.resolvedExecutable;
  final formatArguments = [
    'format',
    '--line-length',
    '80',
    '-o',
    'none',
    '--set-exit-if-changed',
    ...changedDartPaths,
  ];
  final analyzeArguments = [
    'analyze',
    '--fatal-infos',
    '--fatal-warnings',
    ...analyzePaths,
  ];
  stdout.writeln('Formatter (${changedDartPaths.length} changed Dart files):');
  if (changedDartPaths.isEmpty) {
    stdout.writeln('  No command; no changed Dart files exist.');
  } else {
    stdout
      ..writeln('  Paths causing selection: ${changedDartPaths.join(', ')}')
      ..writeln('  ${_formatCommand('fvm dart', formatArguments.skip(1))}');
  }
  stdout.writeln('Analyzer (${analyzePaths.length} analyzed Dart files):');
  if (analyzePaths.isEmpty) {
    stdout.writeln('  No command; no changed Dart files are analyzed.');
  } else {
    stdout
      ..writeln('  Paths causing selection: ${analyzePaths.join(', ')}')
      ..writeln('  ${_formatCommand('fvm dart', analyzeArguments.skip(1))}');
  }

  final plannedCommands = <_PlannedCommand>[];
  final diagnostics = <String>[];
  final planningExitCode = await runSelectedTests(
    selection,
    rootPath: root.path,
    onDiagnostic: diagnostics.add,
    onPlannedCommand: ({
      required executable,
      required arguments,
      required workingDirectory,
    }) {
      plannedCommands.add(
        .new(
          executable: executable,
          arguments: arguments,
          workingDirectory: workingDirectory,
        ),
      );
    },
    dryRun: true,
  );
  if (planningExitCode != 0) {
    stderr.writeln('local-preflight: could not plan selected tests.');
    for (final diagnostic in diagnostics) {
      stderr.writeln(diagnostic.replaceAll(root.path, '.'));
    }

    return planningExitCode;
  }
  stdout.writeln('Tests (${plannedCommands.length} package command(s)):');
  if (plannedCommands.isEmpty) {
    stdout.writeln('  No test command selected.');
  } else {
    for (var index = 0; index < plannedCommands.length; index += 1) {
      final command = plannedCommands[index];
      final package = p.relative(command.workingDirectory, from: root.path);
      final testPaths = command.arguments
          .where((argument) => argument.startsWith('test/'))
          .toList();
      final commandName = _fvmCommand(root, command.executable);
      stdout
        ..writeln('  Package: $package')
        ..writeln('    Selected test paths: ${testPaths.join(', ')}')
        ..writeln(
          '    Changed paths considered for this selection: '
          '${sortedChanges.map(_changeLabel).join(', ')}',
        )
        ..writeln('    ${_formatCommand(commandName, command.arguments)}');
    }
  }
  if (options.dryRun) return 0;

  if (changedDartPaths.isNotEmpty) {
    final formatExitCode = await _run(dart, formatArguments, root);
    if (formatExitCode != 0) return formatExitCode;
  }
  if (analyzePaths.isNotEmpty) {
    final analyzeExitCode = await _run(dart, analyzeArguments, root);
    if (analyzeExitCode != 0) return analyzeExitCode;
  }

  return await runSelectedTests(selection, rootPath: root.path);
}

Future<List<ChangedFile>> _workingTreeChanges(
  Directory root,
  String base,
) async {
  final tracked = await _git(root, [
    'diff',
    '--name-status',
    '--find-renames',
    '-z',
    base,
    '--',
  ]);
  final changes = parseNameStatus(tracked);
  final untracked = await _git(root, [
    'ls-files',
    '--others',
    '--exclude-standard',
    '-z',
  ]);
  final added = untracked
      .split('\u0000')
      .where((path) => path.isNotEmpty)
      .map(ChangedFile.added);

  return [...changes, ...added];
}

List<String> _existingChangedDartPaths(
  Directory root,
  List<ChangedFile> changes,
) {
  final paths = <String>{};
  for (final change in changes) {
    final path = change.newPath;
    if (path == null || !path.endsWith('.dart')) continue;
    final normalized = p.normalize(path);
    if (File(p.join(root.path, normalized)).existsSync()) {
      final _ = paths.add(normalized);
    }
  }

  return paths.toList()..sort();
}

Future<List<String>> _analyzedPaths(Directory root, List<String> paths) async {
  if (paths.isEmpty) return const [];
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

Future<String> _git(Directory root, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: root.path,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      arguments,
      result.stderr.toString(),
      result.exitCode,
    );
  }

  return result.stdout.toString();
}

String _changeLabel(ChangedFile change) => switch (change.status) {
  'added' => 'A ${change.newPath}',
  'modified' => 'M ${change.newPath}',
  'deleted' => 'D ${change.oldPath}',
  'renamed' => 'R ${change.oldPath} -> ${change.newPath}',
  _ => '${change.status} ${change.newPath ?? change.oldPath}',
};

String _fvmCommand(Directory root, String executable) {
  final dart = File('${root.path}/.fvm/flutter_sdk/bin/dart').absolute.path;
  final flutter =
      File('${root.path}/.fvm/flutter_sdk/bin/flutter').absolute.path;
  if (p.normalize(executable) == p.normalize(dart)) return 'fvm dart';
  if (p.normalize(executable) == p.normalize(flutter)) return 'fvm flutter';

  return executable;
}

String _formatCommand(String executable, Iterable<String> arguments) =>
    [executable, ...arguments.map(_quote)].join(' ');

String _quote(String value) {
  if (RegExp(r'^[A-Za-z0-9_./:=,@+-]+$').hasMatch(value)) return value;

  final quote = String.fromCharCode(0x27);
  final escapedQuote = String.fromCharCodes([0x27, 0x5c, 0x27, 0x27]);

  return '$quote${value.replaceAll(quote, escapedQuote)}$quote';
}

Future<int> _run(
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

class const _PlannedCommand({
  required final String executable,
  required final List<String> arguments,
  required final String workingDirectory,
});

const _usage = '''
Usage: melos run preflight:changed [-- --base <ref>]
       [--dry-run] [--full-validation]

The default base is origin/main. The current working tree and untracked files
are included. --dry-run prints selected formatter, analyzer, and test commands.
--full-validation explicitly runs the complete Melos validate script.
''';

class const _Options({
  required final String base,
  required final bool dryRun,
  required final bool fullValidation,
  required final bool help,
}) {
  factory parse(List<String> arguments) {
    var base = 'origin/main';
    var dryRun = false;
    var fullValidation = false;
    var help = false;
    for (var index = 0; index < arguments.length; index += 1) {
      final argument = arguments[index];
      switch (argument) {
        case '--dry-run':
          dryRun = true;
        case '--full-validation':
          fullValidation = true;
        case '--help':
        case '-h':
          help = true;
        case '--base':
          if (index + 1 >= arguments.length ||
              arguments[index + 1].startsWith('--')) {
            throw FormatException('$argument requires a value');
          }
          final value = arguments[++index];
          if (value.startsWith('-')) {
            throw FormatException('Invalid revision: $value');
          }
          base = value;
        default:
          throw FormatException('Unknown argument: $argument');
      }
    }
    if (fullValidation && base != 'origin/main') {
      throw const FormatException(
        '--base cannot be combined with --full-validation',
      );
    }

    return .new(
      base: base,
      dryRun: dryRun,
      fullValidation: fullValidation,
      help: help,
    );
  }

}
