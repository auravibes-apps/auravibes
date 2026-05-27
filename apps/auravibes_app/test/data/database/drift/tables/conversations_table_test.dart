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
  group('Conversations schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db
          .customSelect(
            'PRAGMA table_info(conversations)',
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
          'title',
          'model_id',
          'is_pinned',
        ]),
      );
    });

    test('has 7 columns', () {
      expect(columns.length, 7);
    });

    test('workspace_id is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'workspace_id',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('title is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'title',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('model_id is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'model_id',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('is_pinned has default', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'is_pinned',
      );
      expect(col.read<String?>('dflt_value'), isNotNull);
    });
  });

  group('Conversations column accessors', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('all column getters are accessible', () {
      final table = db.conversations;
      expect(table.workspaceId, isNotNull);
      expect(table.title, isNotNull);
      expect(table.modelId, isNotNull);
      expect(table.isPinned, isNotNull);
    });

    test('column names match expected snake_case', () {
      final table = db.conversations;
      expect(table.workspaceId.name, 'workspace_id');
      expect(table.title.name, 'title');
      expect(table.modelId.name, 'model_id');
      expect(table.isPinned.name, 'is_pinned');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = db.conversations;
      expect(table.$columns.length, 7);
    });

    test('table name is conversations', () {
      expect(db.conversations.actualTableName, 'conversations');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(db.conversations.aliasedName, 'conversations');
    });

    test('createAlias returns new table with alias', () {
      final aliased = db.conversations.createAlias('ca');
      expect(aliased.aliasedName, 'ca');
    });
  });
}
