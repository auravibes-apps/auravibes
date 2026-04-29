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
  group('WorkspaceModelSelections schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db
          .customSelect(
            'PRAGMA table_info(workspace_model_selections)',
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
          'model_id',
          'model_connection_id',
        ]),
      );
    });

    test('has 5 columns', () {
      expect(columns.length, 5);
    });

    test('model_id is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'model_id',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('model_connection_id is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'model_connection_id',
      );
      expect(col.read<int>('notnull'), 1);
    });
  });

  group('WorkspaceModelSelections column accessors', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('all column getters are accessible', () {
      final table = db.workspaceModelSelections;
      expect(table.modelId, isNotNull);
      expect(table.modelConnectionId, isNotNull);
    });

    test('column names match expected snake_case', () {
      final table = db.workspaceModelSelections;
      expect(table.modelId.name, 'model_id');
      expect(table.modelConnectionId.name, 'model_connection_id');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = db.workspaceModelSelections;
      expect(table.$columns.length, 5);
    });

    test('table name is workspace_model_selections', () {
      expect(
        db.workspaceModelSelections.actualTableName,
        'workspace_model_selections',
      );
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(
        db.workspaceModelSelections.aliasedName,
        'workspace_model_selections',
      );
    });

    test('createAlias returns new table with alias', () {
      final aliased = db.workspaceModelSelections.createAlias('wma');
      expect(aliased.aliasedName, 'wma');
    });
  });
}
