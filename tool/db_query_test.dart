import 'dart:io';

import 'package:auravibes_app/app_storage_namespace.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('queries the database selected by hash source', () async {
    final directory = await Directory.systemTemp.createTemp('db_query_test_');
    addTearDown(() => directory.delete(recursive: true));
    const hashSource = '/workspace/one';
    final name = AppStorageNamespace.forHashSource(hashSource);
    sqlite3.open(path.join(directory.path, '$name.sqlite'))
      ..execute('CREATE TABLE values_for_test (value TEXT)')
      ..execute('''INSERT INTO values_for_test VALUES ('scoped')''')
      ..close();

    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/db_query.dart',
      '--database-directory',
      directory.path,
      '--hash-source',
      hashSource,
      'SELECT value FROM values_for_test',
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}'.trim(), '{"value":"scoped"}');
  });
}
