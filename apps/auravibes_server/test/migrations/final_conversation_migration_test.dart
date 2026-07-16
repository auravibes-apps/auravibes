import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('final conversation migration preserves dependent records', () {
    final root = Directory.current.path.endsWith('auravibes_server')
        ? Directory.current
        : Directory('apps/auravibes_server');
    final migration = File(
      '${root.path}/migrations/20260713134310558-f03-f22-final/migration.sql',
    ).readAsStringSync();

    expect(migration, isNot(contains('DROP TABLE "conversation"')));
    expect(migration, contains('ADD COLUMN "isPinned" boolean NOT NULL'));
    expect(migration, contains('ADD COLUMN "modelId" text'));
    expect(migration, contains('ADD COLUMN "agentId" text'));
    expect(migration, contains('ADD COLUMN "parentConversationStableId" text'));
  });
}
