import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/api_models.dart';
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
  group('stringListConverter', () {
    test('converts from JSON list', () {
      expect(stringListConverter.fromJson(['a', 'b']), ['a', 'b']);
    });

    test('converts null to empty list', () {
      expect(stringListConverter.fromJson(null), <String>[]);
    });

    test('converts to JSON', () {
      expect(stringListConverter.toJson(['a', 'b']), ['a', 'b']);
    });

    test('round-trip preserves values', () {
      const original = ['x', 'y', 'z'];
      final json = stringListConverter.toJson(original);
      final restored = stringListConverter.fromJson(json);
      expect(restored, original);
    });
  });

  group('ApiModels schema', () {
    final fixture = _DatabaseFixture(_testConnection);
    var columns = <QueryRow>[];

    setUp(() async {
      fixture.reset();
      columns = await fixture.database
          .customSelect(
            'PRAGMA table_info(api_models)',
          )
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
          'modalities_ouput',
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
      final idCol = columns.firstWhere(
        (r) => r.read<String>('name') == 'id',
      );
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

    test('modalities_ouput is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'modalities_ouput',
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

  group('ApiModels column accessors', () {
    final fixture = _DatabaseFixture(_testConnection);

    setUp(fixture.reset);

    tearDown(fixture.close);

    test('all column getters are accessible', () {
      final table = fixture.database.apiModels;
      expect(table.modelProvider, isNotNull);
      expect(table.id, isNotNull);
      expect(table.name, isNotNull);
      expect(table.modalitiesInput, isNotNull);
      expect(table.modalitiesOuput, isNotNull);
      expect(table.openWeights, isNotNull);
      expect(table.costInput, isNotNull);
      expect(table.costOutput, isNotNull);
      expect(table.costCacheRead, isNotNull);
      expect(table.limitContext, isNotNull);
      expect(table.limitOutput, isNotNull);
      expect(table.supportsReasoning, isNotNull);
    });

    test('primaryKey contains id and modelProvider', () {
      final table = fixture.database.apiModels;
      expect(table.primaryKey.length, 2);
      expect(table.primaryKey, contains(table.id));
      expect(table.primaryKey, contains(table.modelProvider));
    });

    test('column names match expected snake_case', () {
      final table = fixture.database.apiModels;
      expect(table.modelProvider.name, 'model_provider');
      expect(table.id.name, 'id');
      expect(table.name.name, 'name');
      expect(table.family.name, 'family');
      expect(table.modalitiesInput.name, 'modalities_input');
      expect(table.modalitiesOuput.name, 'modalities_ouput');
      expect(table.openWeights.name, 'open_weights');
      expect(table.costInput.name, 'cost_input');
      expect(table.costOutput.name, 'cost_output');
      expect(table.costCacheRead.name, 'cost_cache_read');
      expect(table.limitContext.name, 'limit_context');
      expect(table.limitOutput.name, 'limit_output');
      expect(table.supportsReasoning.name, 'supports_reasoning');
      expect(table.isCanonical.name, 'is_canonical');
      expect(table.supportsPriorityMode.name, 'supports_priority_mode');
      expect(table.supportsToolCalls.name, 'supports_tool_calls');
    });

    test(r'$columns returns all 16 columns', () {
      final table = fixture.database.apiModels;
      expect(table.$columns.length, 16);
    });

    test('table name is api_models', () {
      expect(fixture.database.apiModels.actualTableName, 'api_models');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(fixture.database.apiModels.aliasedName, 'api_models');
    });

    test('createAlias returns new table with alias', () {
      final aliased = fixture.database.apiModels.createAlias('test_alias');
      expect(aliased.aliasedName, 'test_alias');
    });
  });
}
