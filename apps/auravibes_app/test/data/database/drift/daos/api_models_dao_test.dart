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

void main() {
  group('ApiModelsDao', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase(connection: createTestConnection());
    });

    tearDown(() async {
      await database.close();
    });

    test('getAllModels returns empty list when no models', () async {
      final models = await database.apiModelsDao.getAllModels();
      expect(models, isEmpty);
    });

    test('upsertModel inserts and retrieves model', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      final inserted = await database.apiModelsDao.upsertModel(
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
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final updated = await database.apiModelsDao.upsertModel(
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
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final model = await database.apiModelsDao.getModelByProviderAndModelId(
        'openai',
        'gpt-4',
      );
      expect(model, isNotNull);
      expect(model!.name, equals('GPT-4'));
    });

    test('getModelByProviderAndModelId returns null when not found', () async {
      final model = await database.apiModelsDao.getModelByProviderAndModelId(
        'openai',
        'nonexistent',
      );
      expect(model, isNull);
    });

    test('getModelsByProvider returns filtered models', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await seedProvider(database, id: 'anthropic', name: 'Anthropic');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'anthropic',
          id: 'claude-3',
          name: 'Claude 3',
          limitContext: 200000,
          limitOutput: 4096,
        ),
      );
      final openaiModels = await database.apiModelsDao.getModelsByProvider(
        'openai',
      );
      expect(openaiModels.length, equals(1));
      expect(openaiModels.firstOrNull?.name, equals('GPT-4'));
    });

    test('deleteModel removes model and returns true', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final deleted = await database.apiModelsDao.deleteModel('gpt-4');
      expect(deleted, isTrue);
    });

    test('deleteModel returns false for nonexistent model', () async {
      final deleted = await database.apiModelsDao.deleteModel('nonexistent');
      expect(deleted, isFalse);
    });

    test('deleteModelsByProvider removes all models for provider', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final count = await database.apiModelsDao.deleteModelsByProvider(
        'openai',
      );
      expect(count, equals(2));
    });

    test('modelExists returns correct values', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      expect(await database.apiModelsDao.modelExists('gpt-4'), isTrue);
      expect(await database.apiModelsDao.modelExists('nonexistent'), isFalse);
    });

    test('searchModelsByName returns matching models', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4 Turbo',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final results = await database.apiModelsDao.searchModelsByName('Turbo');
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('GPT-4 Turbo'));
    });

    test('getModelCount returns correct count', () async {
      expect(await database.apiModelsDao.getModelCount(), equals(0));
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      expect(await database.apiModelsDao.getModelCount(), equals(1));
    });

    test('getModelCountByProvider returns correct count', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await seedProvider(database, id: 'anthropic', name: 'Anthropic');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      expect(
        await database.apiModelsDao.getModelCountByProvider('openai'),
        equals(1),
      );
      expect(
        await database.apiModelsDao.getModelCountByProvider('anthropic'),
        equals(0),
      );
    });

    test('batchInsertModels inserts multiple models', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      final results = await database.apiModelsDao.batchInsertModels([
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
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      final results = await database.apiModelsDao.batchUpsertModels([
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
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          costInput: const Value(0.03),
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          costInput: const Value(0.001),
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final results = await database.apiModelsDao.getModelsByCostRange(
        0.01,
        0.05,
      );
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('GPT-4'));
    });

    test('getModelsByMinContextLimit filters by context', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final results = await database.apiModelsDao.getModelsByMinContextLimit(
        100000,
      );
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('GPT-4'));
    });

    test('getOpenWeightsModels returns only open weights', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          openWeights: const Value(false),
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-oss',
          name: 'GPT-OSS',
          openWeights: const Value(true),
          limitContext: 32000,
          limitOutput: 4096,
        ),
      );
      final results = await database.apiModelsDao.getOpenWeightsModels();
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('GPT-OSS'));
    });

    test('getModelsByCostEfficiency sorts by cost ascending', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          costInput: const Value(0.03),
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-3.5',
          name: 'GPT-3.5',
          costInput: const Value(0.001),
          limitContext: 16000,
          limitOutput: 4096,
        ),
      );
      final results = await database.apiModelsDao.getModelsByCostEfficiency();
      expect(results.firstOrNull?.name, equals('GPT-3.5'));
      expect(results.lastOrNull?.name, equals('GPT-4'));
    });

    test('deleteAllModels removes all models', () async {
      await seedProvider(database, id: 'openai', name: 'OpenAI');
      await database.apiModelsDao.upsertModel(
        ApiModelsCompanion.insert(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
        ),
      );
      final deleted = await database.apiModelsDao.deleteAllModels();
      expect(deleted, equals(1));
      expect(await database.apiModelsDao.getModelCount(), equals(0));
    });
  });
}
