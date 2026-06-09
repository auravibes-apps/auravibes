// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor createTestConnection() {
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

Future<void> seedProvider(
  AppDatabase db, {
  required String id,
  required String name,
}) => db.apiModelProvidersDao.upsertProvider(
  ApiModelProvidersCompanion.insert(id: id, name: name),
);

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
  group('ApiModelsDao', () {
    final fixture = _DatabaseFixture(createTestConnection);

    setUp(fixture.reset);

    tearDown(() async {
      await fixture.close();
    });

    test('getAllModels returns empty list when no models', () async {
      final models = await fixture.database.apiModelsDao.getAllModels();
      expect(models, isEmpty);
    });

    test('upsertModel inserts and retrieves model', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final inserted = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      expect(inserted.id, equals('gpt-4'));
      expect(inserted.name, equals('GPT-4'));
      expect(inserted.modelProvider, equals('openai'));
    });

    test('upsertModel updates on conflict', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final updated = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4 Turbo',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      expect(updated.name, equals('GPT-4 Turbo'));
    });

    test('getModelByProviderAndModelId returns model', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final model = await fixture.database.apiModelsDao
          .getModelByProviderAndModelId(
            'openai',
            'gpt-4',
          );
      expect(model, isNotNull);
      expect(
        (model ?? fail('Expected model to be non-null')).name,
        equals('GPT-4'),
      );
    });

    test('getModelByProviderAndModelId returns null when not found', () async {
      final model = await fixture.database.apiModelsDao
          .getModelByProviderAndModelId(
            'openai',
            'nonexistent',
          );
      expect(model, isNull);
    });

    test('getModelsByProvider returns filtered models', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      await seedProvider(fixture.database, id: 'anthropic', name: 'Anthropic');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'anthropic',
          id: 'claude-3',
          name: 'Claude 3',
          limitContext: 200000,
          limitOutput: 4096,
        ),
      );
      final openaiModels = await fixture.database.apiModelsDao
          .getModelsByProvider(
            'openai',
          );
      expect(openaiModels.length, equals(1));
      expect(openaiModels.firstOrNull?.name, equals('GPT-4'));
    });

    test('deleteModel removes model and returns true', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final deleted = await fixture.database.apiModelsDao.deleteModel('gpt-4');
      expect(deleted, isTrue);
    });

    test('deleteModel returns false for nonexistent model', () async {
      final deleted = await fixture.database.apiModelsDao.deleteModel(
        'nonexistent',
      );
      expect(deleted, isFalse);
    });

    test('deleteModelsByProvider removes all models for provider', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final count = await fixture.database.apiModelsDao.deleteModelsByProvider(
        'openai',
      );
      expect(count, equals(2));
    });

    test('modelExists returns correct values', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      expect(await fixture.database.apiModelsDao.modelExists('gpt-4'), isTrue);
      expect(
        await fixture.database.apiModelsDao.modelExists('nonexistent'),
        isFalse,
      );
    });

    test('searchModelsByName returns matching models', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4 Turbo',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final results = await fixture.database.apiModelsDao.searchModelsByName(
        'Turbo',
      );
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('GPT-4 Turbo'));
    });

    test('getModelCount returns correct count', () async {
      expect(await fixture.database.apiModelsDao.getModelCount(), equals(0));
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      expect(await fixture.database.apiModelsDao.getModelCount(), equals(1));
    });

    test('getModelCountByProvider returns correct count', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      await seedProvider(fixture.database, id: 'anthropic', name: 'Anthropic');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      expect(
        await fixture.database.apiModelsDao.getModelCountByProvider('openai'),
        equals(1),
      );
      expect(
        await fixture.database.apiModelsDao.getModelCountByProvider(
          'anthropic',
        ),
        equals(0),
      );
    });

    test('batchInsertModels inserts multiple models', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final results = await fixture.database.apiModelsDao.batchInsertModels([
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          limitContext: 16000,
          limitOutput: 4096,
        ),
      ]);
      expect(results.length, equals(2));
    });

    test('batchUpsertModels upserts multiple models', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final results = await fixture.database.apiModelsDao.batchUpsertModels([
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          limitContext: 16000,
          limitOutput: 4096,
        ),
      ]);
      expect(results.length, equals(2));
    });

    test('getModelsByCostRange filters by cost', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          costInput: const Value(0.03),
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          costInput: const Value(0.001),
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final results = await fixture.database.apiModelsDao.getModelsByCostRange(
        0.01,
        0.05,
      );
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('GPT-4'));
    });

    test('getModelsByMinContextLimit filters by context', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final results = await fixture.database.apiModelsDao
          .getModelsByMinContextLimit(
            100000,
          );
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('GPT-4'));
    });

    test('getOpenWeightsModels returns only open weights', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          openWeights: const Value(false),
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-oss',
          name: 'GPT-OSS',
          openWeights: const Value(true),
          limitContext: 32000,
          limitOutput: 4096,
        ),
      );
      final results = await fixture.database.apiModelsDao
          .getOpenWeightsModels();
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('GPT-OSS'));
    });

    test('getModelsByCostEfficiency sorts by cost ascending', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          costInput: const Value(0.03),
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          costInput: const Value(0.001),
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final results = await fixture.database.apiModelsDao
          .getModelsByCostEfficiency();
      expect(results.firstOrNull?.name, equals('GPT-3.5'));
      expect(results.lastOrNull?.name, equals('GPT-4'));
    });

    test('deleteAllModels removes all models', () async {
      await seedProvider(fixture.database, id: 'openai', name: 'OpenAI');
      final _ = await fixture.database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final deleted = await fixture.database.apiModelsDao.deleteAllModels();
      expect(deleted, equals(1));
      expect(await fixture.database.apiModelsDao.getModelCount(), equals(0));
    });
  });
}
