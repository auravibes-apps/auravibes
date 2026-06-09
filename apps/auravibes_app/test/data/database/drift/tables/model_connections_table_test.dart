// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor _testConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

final class _DatabaseFixture {
  _DatabaseFixture(this.createConnection);

  final QueryExecutor Function() createConnection;
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = AppDatabase(connection: createConnection());
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('ServiceConnections schema', () {
    final fixture = _DatabaseFixture(_testConnection);
    var columns = <QueryRow>[];

    setUp(() async {
      fixture.reset();
      columns = await fixture.database
          .customSelect(
            'PRAGMA table_info(service_connections)',
          )
          .get();
    });

    tearDown(fixture.close);

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'id',
          'created_at',
          'updated_at',
          'name',
          'service_id',
          'kind',
          'authentication_type',
          'url',
          'encrypted_auth_value',
          'key_suffix',
          'metadata_json',
          'workspace_id',
          'is_enabled',
        ]),
      );
    });

    test('has 13 columns', () {
      expect(columns.length, 13);
    });

    test('name is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'name',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('service_id is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'service_id',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('kind is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'kind',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('authentication_type is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'authentication_type',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('url is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'url',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('encrypted_auth_value is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'encrypted_auth_value',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('key_suffix is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'key_suffix',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('workspace_id is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'workspace_id',
      );
      expect(col.read<int>('notnull'), 1);
    });
  });

  group('ServiceConnections column accessors', () {
    final fixture = _DatabaseFixture(_testConnection);

    setUp(fixture.reset);

    tearDown(fixture.close);

    test('all column getters are accessible', () {
      final table = fixture.database.serviceConnections;
      expect(table.name, isNotNull);
      expect(table.serviceId, isNotNull);
      expect(table.kind, isNotNull);
      expect(table.authenticationType, isNotNull);
      expect(table.url, isNotNull);
      expect(table.encryptedAuthValue, isNotNull);
      expect(table.keySuffix, isNotNull);
      expect(table.metadataJson, isNotNull);
      expect(table.workspaceId, isNotNull);
      expect(table.isEnabled, isNotNull);
    });

    test('column names match expected snake_case', () {
      final table = fixture.database.serviceConnections;
      expect(table.name.name, 'name');
      expect(table.serviceId.name, 'service_id');
      expect(table.kind.name, 'kind');
      expect(table.authenticationType.name, 'authentication_type');
      expect(table.url.name, 'url');
      expect(table.encryptedAuthValue.name, 'encrypted_auth_value');
      expect(table.keySuffix.name, 'key_suffix');
      expect(table.metadataJson.name, 'metadata_json');
      expect(table.workspaceId.name, 'workspace_id');
      expect(table.isEnabled.name, 'is_enabled');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = fixture.database.serviceConnections;
      expect(table.$columns.length, 13);
    });

    test('table name is service_connections', () {
      expect(
        fixture.database.serviceConnections.actualTableName,
        'service_connections',
      );
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(
        fixture.database.serviceConnections.aliasedName,
        'service_connections',
      );
    });

    test('createAlias returns new table with alias', () {
      final aliased = fixture.database.serviceConnections.createAlias('mca');
      expect(aliased.aliasedName, 'mca');
    });
  });
}
