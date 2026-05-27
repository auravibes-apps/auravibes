// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

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

void main() {
  group('ModelConnections schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db
          .customSelect(
            'PRAGMA table_info(model_connections)',
          )
          .get();
    });

    tearDown(() async => db.close());

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'id',
          'created_at',
          'updated_at',
          'name',
          'model_id',
          'url',
          'key_value',
          'key_suffix',
          'workspace_id',
        ]),
      );
    });

    test('has 9 columns', () {
      expect(columns.length, 9);
    });

    test('name is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'name',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('model_id is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'model_id',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('url is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'url',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('key_value is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'key_value',
      );
      expect(col.read<int>('notnull'), 1);
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

  group('ModelConnections column accessors', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('all column getters are accessible', () {
      final table = db.modelConnections;
      expect(table.name, isNotNull);
      expect(table.modelId, isNotNull);
      expect(table.url, isNotNull);
      expect(table.keyValue, isNotNull);
      expect(table.keySuffix, isNotNull);
      expect(table.workspaceId, isNotNull);
    });

    test('column names match expected snake_case', () {
      final table = db.modelConnections;
      expect(table.name.name, 'name');
      expect(table.modelId.name, 'model_id');
      expect(table.url.name, 'url');
      expect(table.keyValue.name, 'key_value');
      expect(table.keySuffix.name, 'key_suffix');
      expect(table.workspaceId.name, 'workspace_id');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = db.modelConnections;
      expect(table.$columns.length, 9);
    });

    test('table name is model_connections', () {
      expect(db.modelConnections.actualTableName, 'model_connections');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(db.modelConnections.aliasedName, 'model_connections');
    });

    test('createAlias returns new table with alias', () {
      final aliased = db.modelConnections.createAlias('mca');
      expect(aliased.aliasedName, 'mca');
    });
  });
}
