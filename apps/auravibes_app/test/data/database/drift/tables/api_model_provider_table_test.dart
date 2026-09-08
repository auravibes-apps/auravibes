import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
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

final class _DatabaseFixture(final QueryExecutor Function() createConnection) {
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
  group('ModelProvidersTableType', () {
    test('fromString parses supported values and rejects unknown values', () {
      const cases = <({String input, ModelProvidersTableType? expected})>[
        (input: 'openai', expected: ModelProvidersTableType.openai),
        (input: 'anthropic', expected: ModelProvidersTableType.anthropic),
        (input: 'openrouter', expected: ModelProvidersTableType.openrouter),
        (input: 'OpenAI', expected: ModelProvidersTableType.openai),
        (input: 'ANTHROPIC', expected: ModelProvidersTableType.anthropic),
        (input: 'unknown', expected: null),
        (input: '', expected: null),
      ];

      for (final (:input, :expected) in cases) {
        expect(
          ModelProvidersTableType.fromString(input),
          expected,
          reason: input,
        );
      }
    });

    test('value and toString match each supported identifier', () {
      const cases = <({ModelProvidersTableType type, String value})>[
        (type: ModelProvidersTableType.openai, value: 'openai'),
        (type: ModelProvidersTableType.anthropic, value: 'anthropic'),
        (type: ModelProvidersTableType.openrouter, value: 'openrouter'),
      ];

      for (final (:type, :value) in cases) {
        expect(type.value, value, reason: value);
        expect(type.toString(), value, reason: value);
      }
    });

    test('has exactly three values', () {
      expect(ModelProvidersTableType.values, hasLength(3));
    });
  });

  group('ApiModelProviders schema', () {
    final fixture = _DatabaseFixture(_testConnection);
    var columns = <QueryRow>[];

    setUp(() async {
      fixture.reset();
      columns = await fixture.database
          .customSelect('PRAGMA table_info(api_model_providers)')
          .get();
    });

    tearDown(fixture.close);

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(names, containsAll(['id', 'name', 'type', 'url', 'doc']));
    });

    test('has 5 columns', () {
      expect(columns.length, 5);
    });

    test('id is primary key', () {
      final col = columns.firstWhere((r) => r.read<String>('name') == 'id');
      expect(col.read<int>('pk'), greaterThan(0));
    });

    test('name is not null', () {
      final col = columns.firstWhere((r) => r.read<String>('name') == 'name');
      expect(col.read<int>('notnull'), 1);
    });

    test('type is nullable', () {
      final col = columns.firstWhere((r) => r.read<String>('name') == 'type');
      expect(col.read<int>('notnull'), 0);
    });

    test('url is nullable', () {
      final col = columns.firstWhere((r) => r.read<String>('name') == 'url');
      expect(col.read<int>('notnull'), 0);
    });

    test('doc is nullable', () {
      final col = columns.firstWhere((r) => r.read<String>('name') == 'doc');
      expect(col.read<int>('notnull'), 0);
    });
  });

  group('ApiModelProviders column accessors', () {
    final fixture = _DatabaseFixture(_testConnection);

    setUp(fixture.reset);

    tearDown(fixture.close);

    test('can insert provider with nullable fields null', () async {
      final _ = await fixture.database
          .into(fixture.database.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'test-provider',
              name: 'Test Provider',
            ),
          );

      final rows = await fixture.database.apiModelProvidersDao
          .getAllProviders();
      expect(rows, hasLength(1));
      expect(rows.firstOrNull?.id, 'test-provider');
      expect(rows.firstOrNull?.name, 'Test Provider');
      expect(rows.firstOrNull?.type, isNull);
      expect(rows.firstOrNull?.url, isNull);
      expect(rows.firstOrNull?.doc, isNull);
    });

    test('can insert provider with all fields', () async {
      final _ = await fixture.database
          .into(fixture.database.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'full-provider',
              name: 'Full Provider',
              type: const Value(ModelProvidersTableType.openai),
              url: const Value('https://api.test.com'),
              doc: const Value('Test docs'),
            ),
          );

      final rows = await fixture.database.apiModelProvidersDao
          .getAllProviders();
      expect(rows, hasLength(1));
      expect(rows.firstOrNull?.id, 'full-provider');
      expect(rows.firstOrNull?.name, 'Full Provider');
      expect(rows.firstOrNull?.type, ModelProvidersTableType.openai);
      expect(rows.firstOrNull?.url, 'https://api.test.com');
      expect(rows.firstOrNull?.doc, 'Test docs');
    });

    test('can insert openrouter provider', () async {
      final _ = await fixture.database
          .into(fixture.database.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'openrouter',
              name: 'OpenRouter',
              type: const Value(ModelProvidersTableType.openrouter),
              url: const Value('https://openrouter.ai/api/v1'),
            ),
          );

      final rows = await fixture.database.apiModelProvidersDao
          .getAllProviders();
      expect(rows.firstOrNull?.type, ModelProvidersTableType.openrouter);
      expect(rows.firstOrNull?.url, 'https://openrouter.ai/api/v1');
    });

    test('can insert multiple providers', () async {
      final _ = await fixture.database
          .into(fixture.database.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'provider-1',
              name: 'Provider 1',
            ),
          );
      final _ = await fixture.database
          .into(fixture.database.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'provider-2',
              name: 'Provider 2',
              type: const Value(ModelProvidersTableType.anthropic),
            ),
          );

      final rows = await fixture.database.apiModelProvidersDao
          .getAllProviders();
      expect(rows, hasLength(2));
    });
  });
}
