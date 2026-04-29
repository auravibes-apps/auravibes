import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_table.dart';
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
  group('PermissionAccess', () {
    test('fromString returns ask', () {
      expect(PermissionAccess.fromString('ask'), PermissionAccess.ask);
    });

    test('fromString returns granted', () {
      expect(PermissionAccess.fromString('granted'), PermissionAccess.granted);
    });

    test('fromString defaults to ask for unknown', () {
      expect(PermissionAccess.fromString('unknown'), PermissionAccess.ask);
    });

    test('ask value', () {
      expect(PermissionAccess.ask.value, 'ask');
    });

    test('granted value', () {
      expect(PermissionAccess.granted.value, 'granted');
    });
  });

  group('Tools schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db
          .customSelect(
            'PRAGMA table_info(tools)',
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
          'workspace_tools_group_id',
          'tool_id',
          'custom_name',
          'description',
          'additional_prompt',
          'config',
          'input_schema',
          'is_enabled',
          'permissions',
        ]),
      );
    });

    test('has 13 columns', () {
      expect(columns.length, 13);
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

    test('workspace_tools_group_id is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'workspace_tools_group_id',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('tool_id is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'tool_id',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('custom_name is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'custom_name',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('description is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'description',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('additional_prompt is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'additional_prompt',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('config is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'config',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('input_schema is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'input_schema',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('is_enabled has default', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'is_enabled',
      );
      expect(col.read<String?>('dflt_value'), isNotNull);
    });

    test('permissions has default', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'permissions',
      );
      expect(col.read<String?>('dflt_value'), isNotNull);
    });
  });

  group('Tools column accessors', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('all column getters are accessible', () {
      final table = db.tools;
      expect(table.workspaceId, isNotNull);
      expect(table.workspaceToolsGroupId, isNotNull);
      expect(table.toolId, isNotNull);
      expect(table.customName, isNotNull);
      expect(table.description, isNotNull);
      expect(table.additionalPrompt, isNotNull);
      expect(table.config, isNotNull);
      expect(table.inputSchema, isNotNull);
      expect(table.isEnabled, isNotNull);
      expect(table.permissions, isNotNull);
    });

    test('primaryKey contains workspace_id and id', () {
      final table = db.tools;
      expect(table.primaryKey.length, 2);
      expect(table.primaryKey, contains(table.workspaceId));
      expect(table.primaryKey, contains(table.id));
    });

    test('column names match expected snake_case', () {
      final table = db.tools;
      expect(table.workspaceId.name, 'workspace_id');
      expect(table.workspaceToolsGroupId.name, 'workspace_tools_group_id');
      expect(table.toolId.name, 'tool_id');
      expect(table.customName.name, 'custom_name');
      expect(table.description.name, 'description');
      expect(table.additionalPrompt.name, 'additional_prompt');
      expect(table.config.name, 'config');
      expect(table.inputSchema.name, 'input_schema');
      expect(table.isEnabled.name, 'is_enabled');
      expect(table.permissions.name, 'permissions');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = db.tools;
      expect(table.$columns.length, 13);
    });

    test('table name is tools', () {
      expect(db.tools.actualTableName, 'tools');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(db.tools.aliasedName, 'tools');
    });

    test('createAlias returns new table with alias', () {
      final aliased = db.tools.createAlias('ta');
      expect(aliased.aliasedName, 'ta');
    });
  });
}
