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
  group('ModelProvidersTableType', () {
    test('fromString returns openai', () {
      expect(
        ModelProvidersTableType.fromString('openai'),
        ModelProvidersTableType.openai,
      );
    });

    test('fromString returns anthropic', () {
      expect(
        ModelProvidersTableType.fromString('anthropic'),
        ModelProvidersTableType.anthropic,
      );
    });

    test('fromString returns null for unknown', () {
      expect(ModelProvidersTableType.fromString('unknown'), isNull);
    });

    test('fromString is case insensitive', () {
      expect(
        ModelProvidersTableType.fromString('OpenAI'),
        ModelProvidersTableType.openai,
      );
    });

    test('fromString handles mixed case', () {
      expect(
        ModelProvidersTableType.fromString('ANTHROPIC'),
        ModelProvidersTableType.anthropic,
      );
    });

    test('fromString returns openrouter', () {
      expect(
        ModelProvidersTableType.fromString('openrouter'),
        ModelProvidersTableType.openrouter,
      );
    });

    test('fromString handles empty string', () {
      expect(ModelProvidersTableType.fromString(''), isNull);
    });

    test('openai value', () {
      expect(ModelProvidersTableType.openai.value, 'openai');
    });

    test('anthropic value', () {
      expect(ModelProvidersTableType.anthropic.value, 'anthropic');
    });

    test('openrouter value', () {
      expect(ModelProvidersTableType.openrouter.value, 'openrouter');
    });

    test('openai toString', () {
      expect(ModelProvidersTableType.openai.toString(), 'openai');
    });

    test('anthropic toString', () {
      expect(ModelProvidersTableType.anthropic.toString(), 'anthropic');
    });

    test('openrouter toString', () {
      expect(ModelProvidersTableType.openrouter.toString(), 'openrouter');
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
          .customSelect(
            'PRAGMA table_info(api_model_providers)',
          )
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

    test('all column getters are accessible', () {
      final table = fixture.database.apiModelProviders;
      expect(table.id, isNotNull);
      expect(table.name, isNotNull);
      expect(table.type, isNotNull);
      expect(table.url, isNotNull);
      expect(table.doc, isNotNull);
    });

    test('primaryKey contains id', () {
      final table = fixture.database.apiModelProviders;
      expect(table.primaryKey.length, 1);
      expect(table.primaryKey, contains(table.id));
    });

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
