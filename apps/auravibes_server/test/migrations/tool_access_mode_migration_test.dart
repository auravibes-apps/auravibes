import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('tool access migration defaults existing conversations', () {
    final root = Directory.current.path.endsWith('auravibes_server')
        ? Directory.current
        : Directory('apps/auravibes_server');
    final migrationDirectory = Directory('${root.path}/migrations')
        .listSync()
        .whereType<Directory>()
        .singleWhere((directory) {
          final sql = File('${directory.path}/migration.sql');
          return sql.existsSync() &&
              sql.readAsStringSync().contains('ADD COLUMN "toolAccessMode"');
        });
    final migration = File(
      '${migrationDirectory.path}/migration.sql',
    ).readAsStringSync();
    final definition = File(
      '${migrationDirectory.path}/definition_project.json',
    ).readAsStringSync();
    expect(
      migration,
      contains('ADD COLUMN "toolAccessMode" text NOT NULL DEFAULT \'default\''),
    );
    expect(definition, contains('"name": "childConversationStableId"'));
    expect(migration, isNot(contains('autoApproveTools')));
    expect(migration, isNot(contains('DROP TABLE')));
    expect(migration, isNot(contains('DROP COLUMN')));
  });
}
