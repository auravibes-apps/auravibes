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
  group('ToolsGroups schema', () {
    final fixture = _DatabaseFixture(_testConnection);
    var columns = <QueryRow>[];

    setUp(() async {
      fixture.reset();
      columns = await fixture.database
          .customSelect(
            'PRAGMA table_info(tools_groups)',
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
    final fixture = _DatabaseFixture(_testConnection);

    setUp(fixture.reset);

    tearDown(fixture.close);

    test('all column getters are accessible', () {
      final table = fixture.database.toolsGroups;
      expect(table.workspaceId, isNotNull);
      expect(table.mcpServerId, isNotNull);
      expect(table.name, isNotNull);
      expect(table.isEnabled, isNotNull);
      expect(table.permissions, isNotNull);
    });

    test('primaryKey contains workspace_id and id', () {
      final table = fixture.database.toolsGroups;
      expect(table.primaryKey.length, 2);
      expect(table.primaryKey, contains(table.workspaceId));
      expect(table.primaryKey, contains(table.id));
    });

    test('column names match expected snake_case', () {
      final table = fixture.database.toolsGroups;
      expect(table.workspaceId.name, 'workspace_id');
      expect(table.mcpServerId.name, 'mcp_server_id');
      expect(table.name.name, 'name');
      expect(table.isEnabled.name, 'is_enabled');
      expect(table.permissions.name, 'permissions');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = fixture.database.toolsGroups;
      expect(table.$columns.length, 8);
    });

    test('table name is tools_groups', () {
      expect(fixture.database.toolsGroups.actualTableName, 'tools_groups');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(fixture.database.toolsGroups.aliasedName, 'tools_groups');
    });

    test('createAlias returns new table with alias', () {
      final aliased = fixture.database.toolsGroups.createAlias('tga');
      expect(aliased.aliasedName, 'tga');
    });
  });
}
