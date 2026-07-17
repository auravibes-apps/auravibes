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

    test('primary key on id', () {
      final idCol = columns.firstWhere(
        (r) => r.read<String>('name') == 'id',
      );
      expect(idCol.read<int>('pk'), greaterThan(0));
      expect(columns.where((r) => r.read<int>('pk') > 0), hasLength(1));
      expect(
        columns
            .firstWhere((r) => r.read<String>('name') == 'workspace_id')
            .read<int>('pk'),
        0,
      );
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
}
