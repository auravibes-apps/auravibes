import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('message bookmark migration preserves and backfills saved targets', () {
    final root = Directory.current.path.endsWith('auravibes_server')
        ? Directory.current
        : Directory('apps/auravibes_server');
    final migration = File(
      '${root.path}/migrations/20261022022450147/migration.sql',
    ).readAsStringSync();

    expect(migration, isNot(contains('DROP TABLE "message_bookmark"')));
    expect(migration, contains('ADD COLUMN "conversationId" bigint'));
    expect(migration, contains('ADD COLUMN "messageStableId" text'));
    expect(migration, contains('ADD COLUMN "contentSnapshot" text'));
    expect(migration, contains('ADD COLUMN "roleSnapshot" text'));
    expect(migration, contains('ADD COLUMN "messageCreatedAt" timestamp'));
    expect(migration, contains('UPDATE "message_bookmark"'));
    expect(migration, contains('FROM "conversation_message"'));
    expect(migration, contains('message."id" = bookmark."messageId"'));
    expect(
      migration,
      contains('"conversationId" = message."conversationId"'),
    );
    expect(
      migration,
      contains('"messageStableId" = message."stableId"'),
    );
    expect(migration, contains('"contentSnapshot" = message."content"'));
    expect(migration, contains('"roleSnapshot" = message."role"'));
    expect(
      migration,
      contains('"messageCreatedAt" = message."createdAt"'),
    );
    expect(migration, contains('ALTER COLUMN "conversationId" SET NOT NULL'));
    expect(migration, contains('ALTER COLUMN "messageStableId" SET NOT NULL'));
    expect(migration, contains('ALTER COLUMN "contentSnapshot" SET NOT NULL'));
    expect(migration, contains('ALTER COLUMN "roleSnapshot" SET NOT NULL'));
    expect(migration, contains('ALTER COLUMN "messageCreatedAt" SET NOT NULL'));
    expect(migration, contains('DROP CONSTRAINT "message_bookmark_fk_1"'));
    expect(migration, contains('FOREIGN KEY("conversationId")'));
    expect(migration, contains('REFERENCES "conversation"("id")'));
    expect(migration, isNot(contains('FOREIGN KEY("messageId")')));
  });
}
