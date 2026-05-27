// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

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

    test('fromString handles empty string', () {
      expect(ModelProvidersTableType.fromString(''), isNull);
    });

    test('openai value', () {
      expect(ModelProvidersTableType.openai.value, 'openai');
    });

    test('anthropic value', () {
      expect(ModelProvidersTableType.anthropic.value, 'anthropic');
    });

    test('openai toString', () {
      expect(ModelProvidersTableType.openai.toString(), 'openai');
    });

    test('anthropic toString', () {
      expect(ModelProvidersTableType.anthropic.toString(), 'anthropic');
    });

    test('has exactly two values', () {
      expect(ModelProvidersTableType.values, hasLength(2));
    });
  });

  group('ApiModelProviders schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db
          .customSelect(
            'PRAGMA table_info(api_model_providers)',
          )
          .get();
    });

    tearDown(() async => db.close());

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
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('all column getters are accessible', () {
      final table = db.apiModelProviders;
      expect(table.id, isNotNull);
      expect(table.name, isNotNull);
      expect(table.type, isNotNull);
      expect(table.url, isNotNull);
      expect(table.doc, isNotNull);
    });

    test('primaryKey contains id', () {
      final table = db.apiModelProviders;
      expect(table.primaryKey.length, 1);
      expect(table.primaryKey, contains(table.id));
    });

    test('can insert provider with nullable fields null', () async {
      final _ = await db
          .into(db.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'test-provider',
              name: 'Test Provider',
            ),
          );

      final rows = await db.apiModelProvidersDao.getAllProviders();
      expect(rows, hasLength(1));
      expect(rows.firstOrNull?.id, 'test-provider');
      expect(rows.firstOrNull?.name, 'Test Provider');
      expect(rows.firstOrNull?.type, isNull);
      expect(rows.firstOrNull?.url, isNull);
      expect(rows.firstOrNull?.doc, isNull);
    });

    test('can insert provider with all fields', () async {
      final _ = await db
          .into(db.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'full-provider',
              name: 'Full Provider',
              type: const Value(ModelProvidersTableType.openai),
              url: const Value('https://api.test.com'),
              doc: const Value('Test docs'),
            ),
          );

      final rows = await db.apiModelProvidersDao.getAllProviders();
      expect(rows, hasLength(1));
      expect(rows.firstOrNull?.id, 'full-provider');
      expect(rows.firstOrNull?.name, 'Full Provider');
      expect(rows.firstOrNull?.type, ModelProvidersTableType.openai);
      expect(rows.firstOrNull?.url, 'https://api.test.com');
      expect(rows.firstOrNull?.doc, 'Test docs');
    });

    test('can insert multiple providers', () async {
      final _ = await db
          .into(db.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'provider-1',
              name: 'Provider 1',
            ),
          );
      final _ = await db
          .into(db.apiModelProviders)
          .insert(
            ApiModelProvidersCompanion.insert(
              id: 'provider-2',
              name: 'Provider 2',
              type: const Value(ModelProvidersTableType.anthropic),
            ),
          );

      final rows = await db.apiModelProvidersDao.getAllProviders();
      expect(rows, hasLength(2));
    });
  });
}
