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
  group('Conversations schema', () {
    final fixture = _DatabaseFixture(_testConnection);
    var columns = <QueryRow>[];

    setUp(() async {
      fixture.reset();
      columns = await fixture.database
          .customSelect(
            'PRAGMA table_info(conversations)',
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
    final fixture = _DatabaseFixture(_testConnection);

    setUp(fixture.reset);

    tearDown(fixture.close);

    test('all column getters are accessible', () {
      final table = fixture.database.conversations;
      expect(table.workspaceId, isNotNull);
      expect(table.title, isNotNull);
      expect(table.modelId, isNotNull);
      expect(table.isPinned, isNotNull);
    });

    test('column names match expected snake_case', () {
      final table = fixture.database.conversations;
      expect(table.workspaceId.name, 'workspace_id');
      expect(table.title.name, 'title');
      expect(table.modelId.name, 'model_id');
      expect(table.isPinned.name, 'is_pinned');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = fixture.database.conversations;
      expect(table.$columns.length, 7);
    });

    test('table name is conversations', () {
      expect(fixture.database.conversations.actualTableName, 'conversations');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(fixture.database.conversations.aliasedName, 'conversations');
    });

    test('createAlias returns new table with alias', () {
      final aliased = fixture.database.conversations.createAlias('ca');
      expect(aliased.aliasedName, 'ca');
    });
  });
}
