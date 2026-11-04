import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('object gateway migration creates isolated durable ledger tables', () {
    final root = Directory.current.path.endsWith('auravibes_server')
        ? Directory.current
        : Directory('apps/auravibes_server');
    final migration = File(
      '${root.path}/migrations/20261029124845281-object-gateway/migration.sql',
    ).readAsStringSync();
    final definition = File(
      '${root.path}/migrations/20261029124845281-object-gateway/definition.sql',
    ).readAsStringSync();
    final registry = File(
      '${root.path}/migrations/migration_registry.txt',
    ).readAsLinesSync();
    final latestMigration = registry.lastWhere(
      (version) => version.isNotEmpty && !version.startsWith('#'),
    );
    final latestDefinition = File(
      '${root.path}/migrations/$latestMigration/definition.sql',
    ).readAsStringSync();

    for (final sql in [migration, definition, latestDefinition]) {
      expect(sql, contains('CREATE SCHEMA IF NOT EXISTS object_gateway'));
      expect(sql, contains('CREATE TABLE'));
      expect(sql, contains('object_gateway.keys'));
      expect(sql, contains('registration_hash bytea NOT NULL'));
      expect(sql, contains('closed boolean NOT NULL DEFAULT false'));
      expect(sql, contains('object_gateway.uploads'));
      expect(sql, contains('nonce_hash bytea PRIMARY KEY'));
      expect(sql, contains('pending boolean NOT NULL DEFAULT true'));
      expect(sql, contains('object_gateway_pending_uploads'));
    }
    expect(migration, contains('REFERENCES object_gateway.keys(key_hash)'));
    expect(migration, contains('WHERE pending'));
  });
}
