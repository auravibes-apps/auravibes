// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

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
  group('ToolsGroups schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db
          .customSelect(
            'PRAGMA table_info(tools_groups)',
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
          'workspace_id',
          'mcp_server_id',
          'name',
          'is_enabled',
          'permissions',
        ]),
      );
    });

    test('has 8 columns', () {
      expect(columns.length, 8);
    });

    test('composite primary key on workspace_id and id', () {
      final wsCol = columns.firstWhere(
        (r) => r.read<String>('name') == 'workspace_id',
      );
      final idCol = columns.firstWhere(
        (r) => r.read<String>('name') == 'id',
      );
      expect(wsCol.read<int>('pk'), greaterThan(0));
      expect(idCol.read<int>('pk'), greaterThan(0));
    });

    test('mcp_server_id is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'mcp_server_id',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('name is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'name',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('is_enabled has default', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'is_enabled',
      );
      expect(col.read<String?>('dflt_value'), isNotNull);
    });

    test('permissions is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'permissions',
      );
      expect(col.read<int>('notnull'), 1);
    });
  });

  group('ToolsGroups column accessors', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('all column getters are accessible', () {
      final table = db.toolsGroups;
      expect(table.workspaceId, isNotNull);
      expect(table.mcpServerId, isNotNull);
      expect(table.name, isNotNull);
      expect(table.isEnabled, isNotNull);
      expect(table.permissions, isNotNull);
    });

    test('primaryKey contains workspace_id and id', () {
      final table = db.toolsGroups;
      expect(table.primaryKey.length, 2);
      expect(table.primaryKey, contains(table.workspaceId));
      expect(table.primaryKey, contains(table.id));
    });

    test('column names match expected snake_case', () {
      final table = db.toolsGroups;
      expect(table.workspaceId.name, 'workspace_id');
      expect(table.mcpServerId.name, 'mcp_server_id');
      expect(table.name.name, 'name');
      expect(table.isEnabled.name, 'is_enabled');
      expect(table.permissions.name, 'permissions');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = db.toolsGroups;
      expect(table.$columns.length, 8);
    });

    test('table name is tools_groups', () {
      expect(db.toolsGroups.actualTableName, 'tools_groups');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(db.toolsGroups.aliasedName, 'tools_groups');
    });

    test('createAlias returns new table with alias', () {
      final aliased = db.toolsGroups.createAlias('tga');
      expect(aliased.aliasedName, 'tga');
    });
  });
}
