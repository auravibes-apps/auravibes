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
  group('ApiModels schema', () {
    final fixture = _DatabaseFixture(_testConnection);
    var columns = <QueryRow>[];

    setUp(() async {
      fixture.reset();
      columns = await fixture.database
          .customSelect('PRAGMA table_info(api_models)')
          .get();
    });

    tearDown(fixture.close);

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'model_provider',
          'id',
          'name',
          'family',
          'modalities_input',
          'modalities_output',
          'open_weights',
          'cost_input',
          'cost_output',
          'cost_cache_read',
          'limit_context',
          'limit_output',
          'supports_reasoning',
          'is_canonical',
          'supports_priority_mode',
          'supports_tool_calls',
        ]),
      );
    });

    test('has 16 columns', () {
      expect(columns.length, 16);
    });

    test('composite primary key on id and model_provider', () {
      final idCol = columns.firstWhere((r) => r.read<String>('name') == 'id');
      final mpCol = columns.firstWhere(
        (r) => r.read<String>('name') == 'model_provider',
      );
      expect(idCol.read<int>('pk'), greaterThan(0));
      expect(mpCol.read<int>('pk'), greaterThan(0));
    });

    test('modalities_input is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'modalities_input',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('modalities_output is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'modalities_output',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('open_weights is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'open_weights',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('cost_input is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'cost_input',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('limit_context is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'limit_context',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('limit_output is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'limit_output',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('supports_reasoning defaults to false', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'supports_reasoning',
      );
      expect(col.read<int>('notnull'), 1);
      expect(col.read<String>('dflt_value'), '0');
    });
  });
}
