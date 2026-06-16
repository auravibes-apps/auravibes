import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/api_model_providers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/api_models_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/repositories/api_model_repository_impl.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('ApiModelRepositoryImpl', () {
    final fixture = _ApiModelRepositoryFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    const providerRow = ApiModelProvidersTable(
      id: 'openai',
      name: 'OpenAI',
      type: ModelProvidersTableType.openai,
      url: 'https://api.openai.com',
      doc: 'https://docs.openai.com',
    );

    const modelRow = ApiModelsTable(
      modelProvider: 'openai',
      id: 'gpt-4',
      name: 'GPT-4',
      modalitiesInput: ['text'],
      modalitiesOuput: ['text'],
      openWeights: false,
      supportsReasoning: false,
      costInput: 30,
      costOutput: 60,
      limitContext: 128000,
      limitOutput: 4096,
    );

    group('getAllProviders', () {
      test('returns mapped provider entities', () async {
        when(
          () => fixture.mockProvidersDao.getAllProviders(),
        ).thenAnswer((_) async => [providerRow]);

        final result = await fixture.repository.getAllProviders();

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'openai');
        expect(result.firstOrNull?.name, 'OpenAI');
        expect(result.firstOrNull?.type, ModelProvidersType.openai);
        expect(result.firstOrNull?.url, 'https://api.openai.com');
        expect(result.firstOrNull?.doc, 'https://docs.openai.com');
      });

      test('returns empty list when no providers', () async {
        when(
          () => fixture.mockProvidersDao.getAllProviders(),
        ).thenAnswer((_) async => []);

        final result = await fixture.repository.getAllProviders();

        expect(result, isEmpty);
      });
    });

    group('getProvidersByType', () {
      test('returns filtered providers', () async {
        when(
          () => fixture.mockProvidersDao.getProvidersByType('openai'),
        ).thenAnswer((_) async => [providerRow]);

        final result = await fixture.repository.getProvidersByType('openai');

        expect(result, hasLength(1));
        expect(result.single.id, 'openai');
      });
    });

    group('getAllModels', () {
      test('returns mapped model entities', () async {
        when(
          () => fixture.mockModelsDao.getAllModels(),
        ).thenAnswer((_) async => [modelRow]);

        final result = await fixture.repository.getAllModels();

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'gpt-4');
        expect(result.firstOrNull?.name, 'GPT-4');
        expect(result.firstOrNull?.modelProvider, 'openai');
        expect(result.firstOrNull?.limitContext, 128000);
        expect(result.firstOrNull?.limitOutput, 4096);
        expect(result.firstOrNull?.modalitiesInput, ['text']);
        expect(result.firstOrNull?.modalitiesOuput, ['text']);
        expect(result.firstOrNull?.costInput, 30);
        expect(result.firstOrNull?.costOutput, 60);
        expect(result.firstOrNull?.openWeights, false);
        expect(result.firstOrNull?.supportsReasoning, false);
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
        when(
          () => fixture.mockModelsDao.getModelsByProvider('openai'),
        ).thenAnswer((_) async => [modelRow]);

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
          type: ModelProvidersType.openai,
          url: 'https://api.openai.com',
          doc: 'https://docs.openai.com',
        );

        when(
          () => fixture.mockProvidersDao.batchUpsertProviders(any()),
        ).thenAnswer((_) async => [providerRow]);

        final result = await fixture.repository.batchUpsertProviders([entity]);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'openai');
        verify(
          () => fixture.mockProvidersDao.batchUpsertProviders(any()),
        ).called(1);
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
          modalitiesOuput: ['text'],
        );

        when(
          () => fixture.mockModelsDao.batchUpsertModels(any()),
        ).thenAnswer((_) async => [modelRow]);

        final result = await fixture.repository.batchUpsertModels([entity]);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'gpt-4');
        verify(() => fixture.mockModelsDao.batchUpsertModels(any())).called(1);
      });

      test('filters null entities from input', () async {
        when(
          () => fixture.mockModelsDao.batchUpsertModels(any()),
        ).thenAnswer((_) async => []);

        final _ = await fixture.repository.batchUpsertModels([
          const ApiModelEntity(
            modelProvider: 'openai',
            id: 'gpt-4',
            name: 'GPT-4',
            limitContext: 128000,
            limitOutput: 4096,
            modalitiesInput: [],
            modalitiesOuput: [],
          ),
        ]);

        final captured =
            verify(
                  () => fixture.mockModelsDao.batchUpsertModels(captureAny()),
                ).captured.single
                as List;
        expect(captured, hasLength(1));
      });
    });

    group('deleteAllData', () {
      test('returns sum of deleted models and providers', () async {
        when(
          () => fixture.mockModelsDao.deleteAllModels(),
        ).thenAnswer((_) async => 5);
        when(
          () => fixture.mockProvidersDao.deleteAllProviders(),
        ).thenAnswer((_) async => 3);

        final result = await fixture.repository.deleteAllData();

        expect(result, 8);
        verify(() => fixture.mockModelsDao.deleteAllModels()).called(1);
        verify(() => fixture.mockProvidersDao.deleteAllProviders()).called(1);
      });
    });

    group('type mapping', () {
      test('maps null type from table correctly', () async {
        const rowWithTypeNull = ApiModelProvidersTable(
          id: 'test',
          name: 'Test',
        );
        when(
          () => fixture.mockProvidersDao.getAllProviders(),
        ).thenAnswer((_) async => [rowWithTypeNull]);

        final result = await fixture.repository.getAllProviders();

        expect(result.firstOrNull?.type, isNull);
      });

      test('maps anthropic type correctly', () async {
        const anthropicRow = ApiModelProvidersTable(
          id: 'anthropic',
          name: 'Anthropic',
          type: ModelProvidersTableType.anthropic,
        );
        when(
          () => fixture.mockProvidersDao.getAllProviders(),
        ).thenAnswer((_) async => [anthropicRow]);

        final result = await fixture.repository.getAllProviders();

        expect(result.firstOrNull?.type, ModelProvidersType.anthropic);
      });
    });
  });
}

class _ApiModelRepositoryFixture {
  MockApiModelProvidersDao? _mockProvidersDao;
  MockApiModelsDao? _mockModelsDao;
  _TestAppDatabase? _database;
  ApiModelRepositoryImpl? _repository;

  MockApiModelProvidersDao get mockProvidersDao =>
      _mockProvidersDao ?? fail('Fixture not initialized');

  MockApiModelsDao get mockModelsDao =>
      _mockModelsDao ?? fail('Fixture not initialized');

  _TestAppDatabase get database => _database ?? fail('Fixture not initialized');

  ApiModelRepositoryImpl get repository =>
      _repository ?? fail('Fixture not initialized');

  void reset() {
    final providersDao = MockApiModelProvidersDao();
    final modelsDao = MockApiModelsDao();
    final database = _TestAppDatabase(providersDao, modelsDao);
    _mockProvidersDao = providersDao;
    _mockModelsDao = modelsDao;
    _database = database;
    _repository = ApiModelRepositoryImpl(database);
  }

  Future<void> dispose() async {
    await database.close();
    _mockProvidersDao = null;
    _mockModelsDao = null;
    _database = null;
    _repository = null;
  }
}

class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(this._providersDao, this._modelsDao)
    : super(connection: DatabaseConnection(NativeDatabase.memory()));
  final ApiModelProvidersDao _providersDao;
  final ApiModelsDao _modelsDao;

  @override
  ApiModelProvidersDao get apiModelProvidersDao => _providersDao;

  @override
  ApiModelsDao get apiModelsDao => _modelsDao;
}
