import 'dart:io';

import 'package:auravibes_app/app_storage_namespace.dart';
import 'package:path/path.dart' as path;

import 'database_directory.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    if (options.help) {
      stdout.write(_usage);

      return;
    }

    final directory =
        options.databaseDirectory ?? await applicationDocumentsDirectory();
    final defaultDatabase = File(
      path.join(directory, '${AppStorageNamespace.forHashSource(null)}.sqlite'),
    );
    final scopedDatabase = File(
      path.join(
        directory,
        '${AppStorageNamespace.forHashSource(options.hashSource)}.sqlite',
      ),
    );

    if (scopedDatabase.existsSync() || !defaultDatabase.existsSync()) return;

    final _ = await defaultDatabase.copy(scopedDatabase.path);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..write(_usage);
    exitCode = 64;
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

final class _Options._({
  required final String? databaseDirectory,
  required final String hashSource,
  required final bool help,
}) {
  factory parse(List<String> arguments) {
    String? databaseDirectory;
    var hashSource = _currentWorktreePath();
    var help = false;

    for (var index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--database-directory':
          databaseDirectory = _value(arguments, ++index);
        case '--hash-source':
          hashSource = _value(arguments, ++index);
        case '--help' || '-h':
          help = true;
        default:
          throw FormatException('Unknown option: ${arguments[index]}');
      }
    }

    return ._(
      databaseDirectory: databaseDirectory,
      hashSource: hashSource,
      help: help,
    );
  }

  static String _value(List<String> arguments, int index) {
    if (index >= arguments.length) {
      throw const FormatException('Missing option value.');
    }

    return arguments[index];
  }
}

String _currentWorktreePath() {
  final result = Process.runSync('git', ['rev-parse', '--show-toplevel']);
  final worktree = '${result.stdout}'.trim();
  if (result.exitCode == 0 && worktree.isNotEmpty) return worktree;

  return Directory.current.absolute.path;
}

const _usage = '''
Clone the unscoped AuraVibes dev database into a new worktree scope.

Usage:
  fvm dart run tool/clone_database.dart [options]

Options:
  --hash-source PATH         Worktree path to hash (default: current directory)
  --database-directory PATH Override the platform documents directory
  -h, --help                 Show this help
''';
