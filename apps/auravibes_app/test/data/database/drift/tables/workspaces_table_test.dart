// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
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
  group('Workspaces schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db
          .customSelect(
            'PRAGMA table_info(workspaces)',
          )
          .get();
    });

    tearDown(() async => db.close());

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll(['id', 'created_at', 'updated_at', 'name', 'type', 'url']),
      );
    });

    test('has 6 columns', () {
      expect(columns.length, 6);
    });

    test('name is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'name',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('type is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'type',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('url is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'url',
      );
      expect(col.read<int>('notnull'), 0);
    });
  });

  group('WorkspaceType enum', () {
    test('fromString returns local', () {
      expect(WorkspaceType.fromString('local'), WorkspaceType.local);
    });

    test('fromString returns remote', () {
      expect(WorkspaceType.fromString('remote'), WorkspaceType.remote);
    });

    test('fromString is case insensitive', () {
      expect(WorkspaceType.fromString('LOCAL'), WorkspaceType.local);
    });

    test('fromString throws on invalid', () {
      expect(() => WorkspaceType.fromString('invalid'), throwsArgumentError);
    });

    test('local value', () {
      expect(WorkspaceType.local.value, 'local');
    });

    test('remote value', () {
      expect(WorkspaceType.remote.value, 'remote');
    });

    test('isLocal getter', () {
      expect(WorkspaceType.local.isLocal, true);
      expect(WorkspaceType.remote.isLocal, false);
    });

    test('isRemote getter', () {
      expect(WorkspaceType.remote.isRemote, true);
      expect(WorkspaceType.local.isRemote, false);
    });

    test('toString returns value', () {
      expect(WorkspaceType.local.toString(), 'local');
    });
  });

  group('Workspaces column accessors', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('all column getters are accessible', () {
      final table = db.workspaces;
      expect(table.name, isNotNull);
      expect(table.type, isNotNull);
      expect(table.url, isNotNull);
    });

    test('column names match expected snake_case', () {
      final table = db.workspaces;
      expect(table.name.name, 'name');
      expect(table.type.name, 'type');
      expect(table.url.name, 'url');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = db.workspaces;
      expect(table.$columns.length, 6);
    });

    test('table name is workspaces', () {
      expect(db.workspaces.actualTableName, 'workspaces');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(db.workspaces.aliasedName, 'workspaces');
    });

    test('createAlias returns new table with alias', () {
      final aliased = db.workspaces.createAlias('wa');
      expect(aliased.aliasedName, 'wa');
    });
  });
}
