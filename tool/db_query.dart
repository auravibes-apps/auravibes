import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/app_storage_namespace.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    if (options.help) {
      stdout.write(_usage);

      return;
    }

    final directory = options.databaseDirectory ?? await _documentsDirectory();
    final databaseName = AppStorageNamespace.forHashSource(options.hashSource);
    final databaseFile = File(path.join(directory, '$databaseName.sqlite'));
    if (!databaseFile.existsSync()) {
      throw StateError('Database not found: ${databaseFile.path}');
    }

    final database = sqlite3.open(databaseFile.path);
    try {
      final rows = database.select(options.sql);
      for (final row in rows) {
        stdout.writeln(jsonEncode(row.map(_jsonEntry)));
      }
    } finally {
      database.close();
    }
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

MapEntry<String, Object?> _jsonEntry(String key, Object? value) =>
    MapEntry(key, value is Uint8List ? base64Encode(value) : value);

Future<String> _documentsDirectory() async {
  final environment = Platform.environment;
  if (Platform.isMacOS) {
    final home = environment['HOME'];
    if (home == null) throw StateError('HOME is not set.');

    return path.join(
      home,
      'Library',
      'Containers',
      'me.auravibes.app.dev',
      'Data',
      'Documents',
    );
  }
  if (Platform.isLinux) {
    final result = await Process.run('xdg-user-dir', ['DOCUMENTS']);
    final documents = '${result.stdout}'.trim();
    if (result.exitCode == 0 && documents.isNotEmpty) return documents;

    final home = environment['HOME'];
    if (home != null) return path.join(home, 'Documents');
  }
  if (Platform.isWindows) {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      '[Environment]::GetFolderPath("MyDocuments")',
    ]);
    final documents = '${result.stdout}'.trim();
    if (result.exitCode == 0 && documents.isNotEmpty) return documents;
  }

  throw UnsupportedError(
    'Cannot locate the application documents directory. '
    'Pass --database-directory.',
  );
}

final class _Options._({
  required final String? databaseDirectory,
  required final String hashSource,
  required final bool help,
  required final String sql,
}) {
  factory parse(List<String> arguments) {
    String? databaseDirectory;
    var hashSource = Directory.current.absolute.path;
    var help = false;
    final sql = <String>[];

    for (var index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--database-directory':
          databaseDirectory = _value(arguments, ++index);
        case '--hash-source':
          hashSource = _value(arguments, ++index);
        case '--help' || '-h':
          help = true;
        default:
          sql.add(arguments[index]);
      }
    }

    if (!help && sql.isEmpty) throw const FormatException('Missing SQL query.');

    return ._(
      databaseDirectory: databaseDirectory,
      hashSource: hashSource,
      help: help,
      sql: sql.join(' '),
    );
  }

  static String _value(List<String> arguments, int index) {
    if (index >= arguments.length) {
      throw const FormatException('Missing option value.');
    }

    return arguments[index];
  }
}

const _usage = '''
Execute SQL against the dev database scoped by DB_HASH_SOURCE.

Usage:
  fvm dart run tool/db_query.dart [options] "SQL"

Options:
  --hash-source PATH         DB_HASH_SOURCE value (default: current directory)
  --database-directory PATH Override the platform documents directory
  -h, --help                 Show this help

Examples:
  fvm dart run tool/db_query.dart "SELECT id, name FROM workspaces"
  fvm dart run tool/db_query.dart --hash-source ../other "PRAGMA user_version"
''';
