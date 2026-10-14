import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('auto-approval migration adds false default without dropping data', () {
    final root = Directory.current.path.endsWith('auravibes_server')
        ? Directory.current
        : Directory('apps/auravibes_server');
    final migrations = Directory('${root.path}/migrations')
        .listSync()
        .whereType<Directory>();
    final migration = migrations
        .map((directory) => File('${directory.path}/migration.sql'))
        .where((file) => file.existsSync())
        .map((file) => file.readAsStringSync())
        .singleWhere((sql) => sql.contains('ADD COLUMN "autoApproveTools"'));
    expect(
      migration,
      contains('ADD COLUMN "autoApproveTools" boolean NOT NULL DEFAULT false'),
    );
    expect(migration, isNot(contains('DROP TABLE')));
    expect(migration, isNot(contains('DROP COLUMN')));
  });
}
