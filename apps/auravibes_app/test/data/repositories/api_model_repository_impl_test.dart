// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

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
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'api_model_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ApiModelProvidersDao>(), MockSpec<ApiModelsDao>()])
void main() {
  group('ApiModelRepositoryImpl', () {
    late MockApiModelProvidersDao mockProvidersDao;
    late MockApiModelsDao mockModelsDao;
    late _TestAppDatabase database;
    late ApiModelRepositoryImpl repository;

    setUp(() {
      mockProvidersDao = MockApiModelProvidersDao();
      mockModelsDao = MockApiModelsDao();
      database = _TestAppDatabase(mockProvidersDao, mockModelsDao);
      repository = ApiModelRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

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
          mockProvidersDao.getAllProviders(),
        ).thenAnswer((_) async => [providerRow]);

        final result = await repository.getAllProviders();

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'openai');
        expect(result.firstOrNull?.name, 'OpenAI');
        expect(result.firstOrNull?.type, ModelProvidersType.openai);
        expect(result.firstOrNull?.url, 'https://api.openai.com');
        expect(result.firstOrNull?.doc, 'https://docs.openai.com');
      });

      test('returns empty list when no providers', () async {
        when(mockProvidersDao.getAllProviders()).thenAnswer((_) async => []);

        final result = await repository.getAllProviders();

        expect(result, isEmpty);
      });
    });

    group('getProvidersByType', () {
      test('returns filtered providers', () async {
        when(
          mockProvidersDao.getProvidersByType('openai'),
        ).thenAnswer((_) async => [providerRow]);

        final result = await repository.getProvidersByType('openai');

        expect(result, hasLength(1));
        expect(result.single.id, 'openai');
      });
    });

    group('getAllModels', () {
      test('returns mapped model entities', () async {
        when(mockModelsDao.getAllModels()).thenAnswer((_) async => [modelRow]);

        final result = await repository.getAllModels();

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
          mockModelsDao.getModelByProviderAndModelId('openai', 'gpt-4'),
        ).thenAnswer((_) async => modelRow);

        final result = await repository.getModelByProviderAndModelId(
          'openai',
          'gpt-4',
        );

        expect(result, isNotNull);
        expect(result!.id, 'gpt-4');
      });

      test('returns null when not found', () async {
        when(
          mockModelsDao.getModelByProviderAndModelId('openai', 'unknown'),
        ).thenAnswer((_) async => null);

        final result = await repository.getModelByProviderAndModelId(
          'openai',
          'unknown',
        );

        expect(result, isNull);
      });
    });

    group('getModelsByProvider', () {
      test('returns models for provider', () async {
        when(
          mockModelsDao.getModelsByProvider('openai'),
        ).thenAnswer((_) async => [modelRow]);

        final result = await repository.getModelsByProvider('openai');

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
          mockProvidersDao.batchUpsertProviders(any),
        ).thenAnswer((_) async => [providerRow]);

        final result = await repository.batchUpsertProviders([entity]);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'openai');
        verify(mockProvidersDao.batchUpsertProviders(any)).called(1);
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
          mockModelsDao.batchUpsertModels(any),
        ).thenAnswer((_) async => [modelRow]);

        final result = await repository.batchUpsertModels([entity]);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'gpt-4');
        verify(mockModelsDao.batchUpsertModels(any)).called(1);
      });

      test('filters null entities from input', () async {
        when(mockModelsDao.batchUpsertModels(any)).thenAnswer((_) async => []);

        final _ = await repository.batchUpsertModels([
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
            verify(mockModelsDao.batchUpsertModels(captureAny)).captured.single
                as List;
        expect(captured, hasLength(1));
      });
    });

    group('deleteAllData', () {
      test('returns sum of deleted models and providers', () async {
        when(mockModelsDao.deleteAllModels()).thenAnswer((_) async => 5);
        when(mockProvidersDao.deleteAllProviders()).thenAnswer((_) async => 3);

        final result = await repository.deleteAllData();

        expect(result, 8);
        verify(mockModelsDao.deleteAllModels()).called(1);
        verify(mockProvidersDao.deleteAllProviders()).called(1);
      });
    });

    group('type mapping', () {
      test('maps null type from table correctly', () async {
        const rowWithTypeNull = ApiModelProvidersTable(
          id: 'test',
          name: 'Test',
        );
        when(
          mockProvidersDao.getAllProviders(),
        ).thenAnswer((_) async => [rowWithTypeNull]);

        final result = await repository.getAllProviders();

        expect(result.firstOrNull?.type, isNull);
      });

      test('maps anthropic type correctly', () async {
        const anthropicRow = ApiModelProvidersTable(
          id: 'anthropic',
          name: 'Anthropic',
          type: ModelProvidersTableType.anthropic,
        );
        when(
          mockProvidersDao.getAllProviders(),
        ).thenAnswer((_) async => [anthropicRow]);

        final result = await repository.getAllProviders();

        expect(result.firstOrNull?.type, ModelProvidersType.anthropic);
      });
    });
  });
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
