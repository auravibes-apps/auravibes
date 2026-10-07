import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';
import '../database/drift/database_test_utils.dart';

void main() {
  test(
    'advanced capabilities survive database close and reload independently',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'model-capabilities',
      );
      final file = File('${directory.path}/models.sqlite');
      AppDatabase database = _CapabilitiesDatabaseBeforeReopen(
        NativeDatabase(file),
      );
      try {
        final repository = ApiModelRepository(database);
        final _ = await repository.batchUpsertProviders([
          const ApiModelProviderEntity(
            id: 'anthropic',
            name: 'Anthropic',
            type: .anthropic,
          ),
        ]);
        final _ = await repository.batchUpsertModels([
          for (var index = 0; index < 4; index++)
            ApiModelEntity(
              modelProvider: 'anthropic',
              id: '$index',
              name: 'Persisted',
              limitContext: 1000,
              limitOutput: 100,
              modalitiesInput: ['text'],
              modalitiesOutput: ['text'],
              supportsPromptCacheMarkers: index == 0,
              supportsMidConversationSystemMessages: index == 1,
              supportsToolDeltas: index == 2,
              supportsDeferredTools: index == 3,
            ),
        ]);
        await database.close();
        database = _CapabilitiesDatabaseAfterReopen(NativeDatabase(file));
        final models = await ApiModelRepository(database).getAllModels();
        expect(models, hasLength(4));
        for (final model in models) {
          expect(model.supportsPromptCacheMarkers, model.id == '0');
          expect(model.supportsMidConversationSystemMessages, model.id == '1');
          expect(model.supportsToolDeltas, model.id == '2');
          expect(model.supportsDeferredTools, model.id == '3');
        }
      } finally {
        await database.close();
        directory.deleteSync(recursive: true);
      }
    },
  );

  setUpAll(registerTestFallbackValues);

  group('ApiModelRepository', () {
    final fixture = _ApiModelRepositoryFixture();

    setUp(fixture.resetForTest);

    tearDownAll(fixture.dispose);

    const providerRow = ApiModelProvidersTable(
      id: 'openai',
      name: 'OpenAI',
      type: .openai,
      url: 'https://api.openai.com',
      doc: 'https://docs.openai.com',
    );

    const modelRow = ApiModelsTable(
      modelProvider: 'openai',
      id: 'gpt-4',
      name: 'GPT-4',
      modalitiesInput: ['text'],
      modalitiesOutput: ['text'],
      openWeights: false,
      supportsReasoning: false,
      isCanonical: true,
      supportsPriorityMode: false,
      supportsToolCalls: false,
      supportsPromptCacheMarkers: false,
      supportsMidConversationSystemMessages: false,
      supportsToolDeltas: false,
      supportsDeferredTools: false,

      costInput: 30,
      costOutput: 60,
      costCacheRead: 3,
      costCacheWrite: 7,
      limitContext: 128000,
      limitOutput: 4096,
    );

    group('getAllProviders', () {
      test('returns mapped provider entities', () async {
        when(() => fixture.mockProvidersDao.getAllProviders())
            .thenAnswer((_) async => [providerRow]);

        final result = await fixture.repository.getAllProviders();

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'openai');
        expect(result.firstOrNull?.name, 'OpenAI');
        expect(result.firstOrNull?.type, ModelProvidersType.openai);
        expect(result.firstOrNull?.url, 'https://api.openai.com');
        expect(result.firstOrNull?.doc, 'https://docs.openai.com');
      });

      test('returns empty list when no providers', () async {
        when(() => fixture.mockProvidersDao.getAllProviders())
            .thenAnswer((_) async => []);

        final result = await fixture.repository.getAllProviders();

        expect(result, isEmpty);
      });
    });

    group('getProvidersByType', () {
      test('returns filtered providers', () async {
        when(() => fixture.mockProvidersDao.getProvidersByType('openai'))
            .thenAnswer((_) async => [providerRow]);

        final result = await fixture.repository.getProvidersByType('openai');

        expect(result, hasLength(1));
        expect(result.single.id, 'openai');
      });

      test('returns openrouter providers', () async {
        const openRouterRow = ApiModelProvidersTable(
          id: 'openrouter',
          name: 'OpenRouter',
          type: .openrouter,
          url: 'https://openrouter.ai/api/v1',
        );
        when(() => fixture.mockProvidersDao.getProvidersByType('openrouter'))
            .thenAnswer((_) async => [openRouterRow]);

        final result = await fixture.repository.getProvidersByType(
          'openrouter',
        );

        expect(result, hasLength(1));
        expect(result.single.type, ModelProvidersType.openrouter);
      });
    });

    group('getAllModels', () {
      test('returns mapped model entities', () async {
        when(() => fixture.mockModelsDao.getAllModels())
            .thenAnswer((_) async => [modelRow]);

        final result = await fixture.repository.getAllModels();

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'gpt-4');
        expect(result.firstOrNull?.name, 'GPT-4');
        expect(result.firstOrNull?.modelProvider, 'openai');
        expect(result.firstOrNull?.limitContext, 128000);
        expect(result.firstOrNull?.limitOutput, 4096);
        expect(result.firstOrNull?.modalitiesInput, ['text']);
        expect(result.firstOrNull?.modalitiesOutput, ['text']);
        expect(result.firstOrNull?.costInput, 30);
        expect(result.firstOrNull?.costCacheRead, 3);
        expect(result.firstOrNull?.costCacheWrite, 7);
        expect(result.firstOrNull?.costOutput, 60);
        expect(result.firstOrNull?.openWeights, false);
        expect(result.firstOrNull?.supportsReasoning, false);
        expect(result.firstOrNull?.isCanonical, true);
        expect(result.firstOrNull?.supportsPriorityMode, false);
        expect(result.firstOrNull?.supportsToolCalls, false);
      });
    });

    group('getModelByProviderAndModelId', () {
      test('returns model when found', () async {
        when(
          () => fixture.mockModelsDao.getModelByProviderAndModelId(
            'openai',
            'gpt-4',
          ),
        ).thenAnswer((_) async => modelRow);

        final result = await fixture.repository.getModelByProviderAndModelId(
          'openai',
          'gpt-4',
        );

        expect(result, isNotNull);
        expect((result ?? fail('Expected result to be non-null')).id, 'gpt-4');
      });

      test('returns null when not found', () async {
        when(
          () => fixture.mockModelsDao.getModelByProviderAndModelId(
            'openai',
            'unknown',
          ),
        ).thenAnswer((_) async => null);

        final result = await fixture.repository.getModelByProviderAndModelId(
          'openai',
          'unknown',
        );

        expect(result, isNull);
      });
    });

    group('getModelsByProvider', () {
      test('returns models for provider', () async {
        when(() => fixture.mockModelsDao.getModelsByProvider('openai'))
            .thenAnswer((_) async => [modelRow]);

        final result = await fixture.repository.getModelsByProvider('openai');

        expect(result, hasLength(1));
        expect(result.firstOrNull?.modelProvider, 'openai');
      });
    });

    group('batchUpsertProviders', () {
      test('maps entities to companions and back', () async {
        const entity = ApiModelProviderEntity(
          id: 'openai',
          name: 'OpenAI',
          type: .openai,
          url: 'https://api.openai.com',
          doc: 'https://docs.openai.com',
        );

        when(() => fixture.mockProvidersDao.batchUpsertProviders(any()))
            .thenAnswer((_) async => [providerRow]);

        final result = await fixture.repository.batchUpsertProviders([entity]);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'openai');
        verify(() => fixture.mockProvidersDao.batchUpsertProviders(any()))
            .called(1);
      });
    });

    group('batchUpsertModels', () {
      test('maps entities to companions and back', () async {
        const entity = ApiModelEntity(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
          modalitiesInput: ['text'],
          modalitiesOutput: ['text'],
        );

        when(() => fixture.mockModelsDao.batchUpsertModels(any()))
            .thenAnswer((_) async => [modelRow]);

        final result = await fixture.repository.batchUpsertModels([entity]);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'gpt-4');
        verify(() => fixture.mockModelsDao.batchUpsertModels(any())).called(1);
      });

      test('filters null entities from input', () async {
        when(() => fixture.mockModelsDao.batchUpsertModels(any()))
            .thenAnswer((_) async => []);

        final _ = await fixture.repository.batchUpsertModels([
          const ApiModelEntity(
            modelProvider: 'openai',
            id: 'gpt-4',
            name: 'GPT-4',
            limitContext: 128000,
            limitOutput: 4096,
            modalitiesInput: [],
            modalitiesOutput: [],
          ),
        ]);

        final captured =
            verify(() => fixture.mockModelsDao.batchUpsertModels(captureAny()))
                    .captured
                    .single
                as List;
        expect(captured, hasLength(1));
      });
    });

    group('replaceAllData', () {
      final failureDatabase = _ModelReplacementFailureDatabase(
        DatabaseConnection(NativeDatabase.memory()),
      );

      setUp(() async {
        await failureDatabase.customStatement(
          'DROP TRIGGER IF EXISTS fail_model_sync',
        );
        await failureDatabase.customStatement(
          'DROP TRIGGER IF EXISTS fail_stale_provider_delete',
        );
        await clearAppDatabase(failureDatabase);
      });

      tearDownAll(failureDatabase.close);

      test('upserts providers and models in a transaction', () async {
        when(() => fixture.mockProvidersDao.batchUpsertProviders(any()))
            .thenAnswer((_) async => [providerRow]);
        when(() => fixture.mockModelsDao.batchUpsertModels(any()))
            .thenThrow(Exception('DB error'));
        when(() => fixture.mockModelsDao.getAllModels())
            .thenAnswer((_) async => const []);
        when(() => fixture.mockProvidersDao.getAllProviders())
            .thenAnswer((_) async => const []);

        await expectLater(
          fixture.repository.replaceAllData(
            providers: const [
              ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
                type: .openai,
                url: 'https://api.openai.com',
              ),
            ],
            models: const [
              ApiModelEntity(
                modelProvider: 'openai',
                id: 'gpt-4',
                name: 'GPT-4',
                limitContext: 128000,
                limitOutput: 4096,
                modalitiesInput: [],
                modalitiesOutput: [],
              ),
            ],
          ),
          throwsA(anything),
        );

        expect(fixture.database.transactionCount, 1);
        final _ = verifyNever(() => fixture.mockModelsDao.deleteAllModels());
        final _ = verifyNever(
          () => fixture.mockProvidersDao.deleteAllProviders(),
        );
        verify(() => fixture.mockProvidersDao.batchUpsertProviders(any()))
            .called(1);
        verify(() => fixture.mockModelsDao.batchUpsertModels(any())).called(1);
      });

      test('preserves existing data when model replacement fails', () async {
        final repository = ApiModelRepository(failureDatabase);

        final _ = await failureDatabase.apiModelProvidersDao.upsertProvider(
          .insert(id: 'existing-provider', name: 'Existing Provider'),
        );
        final _ = await failureDatabase.apiModelsDao.upsertModel(
          .insert(
            modelProvider: 'existing-provider',
            id: 'existing-model',
            name: 'Existing Model',
            limitContext: 128000,
            limitOutput: 4096,
          ),
        );
        await failureDatabase.customStatement('''
          CREATE TRIGGER fail_model_sync
          BEFORE INSERT ON api_models
          WHEN NEW.id = 'new-model'
          BEGIN
            SELECT RAISE(ABORT, 'forced model sync failure');
          END;
        ''');

        await expectLater(
          repository.replaceAllData(
            providers: const [
              ApiModelProviderEntity(
                id: 'new-provider',
                name: 'New Provider',
                type: .openai,
              ),
            ],
            models: const [
              ApiModelEntity(
                modelProvider: 'new-provider',
                id: 'new-model',
                name: 'New Model',
                limitContext: 128000,
                limitOutput: 4096,
                modalitiesInput: [],
                modalitiesOutput: [],
              ),
            ],
          ),
          throwsA(isA<SqliteException>()),
        );

        final providers = await repository.getAllProviders();
        final models = await repository.getAllModels();
        expect(providers.map((provider) => provider.id), ['existing-provider']);
        expect(models.map((model) => model.id), ['existing-model']);
      });

      test('rolls back when provider deletion fails', () async {
        final repository = ApiModelRepository(failureDatabase);

        final _ = await failureDatabase.apiModelProvidersDao.upsertProvider(
          .insert(id: 'existing-provider', name: 'Existing Provider'),
        );
        final _ = await failureDatabase.apiModelsDao.upsertModel(
          .insert(
            modelProvider: 'existing-provider',
            id: 'existing-model',
            name: 'Existing Model',
            limitContext: 128000,
            limitOutput: 4096,
          ),
        );
        await failureDatabase.customStatement('''
          CREATE TRIGGER fail_stale_provider_delete
          BEFORE DELETE ON api_model_providers
          WHEN OLD.id = 'existing-provider'
          BEGIN
            SELECT RAISE(ABORT, 'forced provider prune failure');
          END;
        ''');

        await expectLater(
          repository.replaceAllData(
            providers: const [
              ApiModelProviderEntity(
                id: 'new-provider',
                name: 'New Provider',
                type: .openai,
              ),
            ],
            models: const [
              ApiModelEntity(
                modelProvider: 'new-provider',
                id: 'new-model',
                name: 'New Model',
                limitContext: 128000,
                limitOutput: 4096,
                modalitiesInput: [],
                modalitiesOutput: [],
              ),
            ],
          ),
          throwsA(isA<SqliteException>()),
        );

        expect(
          (await repository.getAllProviders()).map((provider) => provider.id),
          ['existing-provider'],
        );
        expect((await repository.getAllModels()).map((model) => model.id), [
          'existing-model',
        ]);
      });

      test('prunes rows missing from replacement data', () async {
        when(() => fixture.mockProvidersDao.batchUpsertProviders(any()))
            .thenAnswer((_) async => [providerRow]);
        when(() => fixture.mockModelsDao.batchUpsertModels(any()))
            .thenAnswer((_) async => [modelRow]);
        when(() => fixture.mockModelsDao.getAllModels()).thenAnswer(
          (_) async => [modelRow, modelRow.copyWith(id: 'old-model')],
        );
        when(() => fixture.mockProvidersDao.getAllProviders()).thenAnswer(
          (_) async => [providerRow, providerRow.copyWith(id: 'old-provider')],
        );
        when(
          () => fixture.mockModelsDao.deleteModelByProviderAndId(
            'openai',
            'old-model',
          ),
        ).thenAnswer((_) async => true);
        when(() => fixture.mockProvidersDao.deleteProvider('old-provider'))
            .thenAnswer((_) async => true);

        await fixture.repository.replaceAllData(
          providers: const [
            ApiModelProviderEntity(
              id: 'openai',
              name: 'OpenAI',
              type: .openai,
              url: 'https://api.openai.com',
            ),
          ],
          models: const [
            ApiModelEntity(
              modelProvider: 'openai',
              id: 'gpt-4',
              name: 'GPT-4',
              limitContext: 128000,
              limitOutput: 4096,
              modalitiesInput: [],
              modalitiesOutput: [],
            ),
          ],
        );

        expect(fixture.database.transactionCount, 1);
        verify(
          () => fixture.mockModelsDao.deleteModelByProviderAndId(
            'openai',
            'old-model',
          ),
        ).called(1);
        verify(() => fixture.mockProvidersDao.deleteProvider('old-provider'))
            .called(1);
      });
    });

    group('type mapping', () {
      test('maps null type from table correctly', () async {
        const rowWithTypeNull = ApiModelProvidersTable(
          id: 'test',
          name: 'Test',
        );
        when(() => fixture.mockProvidersDao.getAllProviders())
            .thenAnswer((_) async => [rowWithTypeNull]);

        final result = await fixture.repository.getAllProviders();

        expect(result.firstOrNull?.type, isNull);
      });

      test('maps anthropic type correctly', () async {
        const anthropicRow = ApiModelProvidersTable(
          id: 'anthropic',
          name: 'Anthropic',
          type: .anthropic,
        );
        when(() => fixture.mockProvidersDao.getAllProviders())
            .thenAnswer((_) async => [anthropicRow]);

        final result = await fixture.repository.getAllProviders();

        expect(result.firstOrNull?.type, ModelProvidersType.anthropic);
      });

      test('maps openrouter type correctly', () async {
        const openRouterRow = ApiModelProvidersTable(
          id: 'openrouter',
          name: 'OpenRouter',
          type: .openrouter,
        );
        when(() => fixture.mockProvidersDao.getAllProviders())
            .thenAnswer((_) async => [openRouterRow]);

        final result = await fixture.repository.getAllProviders();

        expect(result.firstOrNull?.type, ModelProvidersType.openrouter);
      });
    });
  });
}

typedef _ApiModelRepositoryFixtureSetup = ({
  MockApiModelProvidersDao mockProvidersDao,
  MockApiModelsDao mockModelsDao,
  _TestAppDatabase database,
  ApiModelRepository repository,
});

_ApiModelRepositoryFixtureSetup _createApiModelRepositoryFixtureSetup() {
  final mockProvidersDao = MockApiModelProvidersDao();
  final mockModelsDao = MockApiModelsDao();
  final database = _TestAppDatabase(mockProvidersDao, mockModelsDao);

  return (
    mockProvidersDao: mockProvidersDao,
    mockModelsDao: mockModelsDao,
    database: database,
    repository: .new(database),
  );
}

class _ApiModelRepositoryFixture {
  new() : this._(_createApiModelRepositoryFixtureSetup());

  new _(_ApiModelRepositoryFixtureSetup setup)
    : _mockProvidersDao = setup.mockProvidersDao,
      _mockModelsDao = setup.mockModelsDao,
      _database = setup.database,
      _repository = setup.repository;

  final MockApiModelProvidersDao _mockProvidersDao;
  final MockApiModelsDao _mockModelsDao;
  final _TestAppDatabase _database;
  final ApiModelRepository _repository;

  MockApiModelProvidersDao get mockProvidersDao => _mockProvidersDao;

  MockApiModelsDao get mockModelsDao => _mockModelsDao;

  _TestAppDatabase get database => _database;

  ApiModelRepository get repository => _repository;

  Future<void> resetForTest() async {
    reset(_mockProvidersDao);
    reset(_mockModelsDao);
    _database.transactionCount = 0;
    await clearAppDatabase(_database);
  }

  Future<void> dispose() async {
    await _database.close();
  }
}

final class _CapabilitiesDatabaseBeforeReopen extends AppDatabase {
  new(QueryExecutor connection) : super(connection: connection);
}

final class _CapabilitiesDatabaseAfterReopen extends AppDatabase {
  new(QueryExecutor connection) : super(connection: connection);
}

final class _ModelReplacementFailureDatabase extends AppDatabase {
  new(QueryExecutor connection) : super(connection: connection);
}

class _TestAppDatabase(
  final ApiModelProvidersDao _providersDao,
  final ApiModelsDao _modelsDao,
) extends AppDatabase {
  this : super(connection: DatabaseConnection(NativeDatabase.memory()));

  int transactionCount = 0;

  @override
  ApiModelProvidersDao get apiModelProvidersDao => _providersDao;

  @override
  ApiModelsDao get apiModelsDao => _modelsDao;

  @override
  Future<T> transaction<T>(
    Future<T> Function() action, {
    bool requireNew = false,
  }) {
    transactionCount += 1;

    return super.transaction(action, requireNew: requireNew);
  }
}
