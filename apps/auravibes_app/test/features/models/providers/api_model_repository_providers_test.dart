import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/api_model_repository_impl.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:auravibes_app/services/model_sync_service.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeApiModelRepository implements ApiModelRepository {
  _FakeApiModelRepository({this.providers = const [], this.models = const []});
  final List<ApiModelProviderEntity> providers;
  final List<ApiModelEntity> models;

  @override
  Future<List<ApiModelProviderEntity>> getAllProviders() async => providers;

  @override
  Future<List<ApiModelEntity>> getAllModels() async => models;

  @override
  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  ) async {
    return models
        .where(
          (m) => m.modelProvider == providerId && m.id == modelId,
        )
        .firstOrNull;
  }

  @override
  Future<List<ApiModelEntity>> getModelsByProvider(String providerId) async {
    return models.where((m) => m.modelProvider == providerId).toList();
  }

  @override
  Future<List<ApiModelProviderEntity>> getProvidersByType(String type) {
    throw UnimplementedError();
  }

  @override
  Future<List<ApiModelProviderEntity>> batchUpsertProviders(
    List<ApiModelProviderEntity> providers,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<ApiModelEntity>> batchUpsertModels(List<ApiModelEntity> models) {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteAllData() {
    throw UnimplementedError();
  }
}

void main() {
  group('apiModelRepositoryProvider', () {
    test('returns ApiModelRepository from container', () {
      final repo = _FakeApiModelRepository();
      final container = ProviderContainer(
        overrides: [
          apiModelRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(apiModelRepositoryProvider);
      expect(result, same(repo));
    });

    test('builds repository from app database provider', () {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(apiModelRepositoryProvider);
      expect(result, isA<ApiModelRepositoryImpl>());
    });
  });

  group('modelApiServiceProvider', () {
    test('returns ModelApiService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(modelApiServiceProvider);
      expect(result, isA<ModelApiService>());
    });
  });

  group('apiModelProvidersProvider', () {
    test('returns providers from repository', () async {
      final providers = [
        const ApiModelProviderEntity(
          id: 'openai',
          name: 'OpenAI',
          type: ModelProvidersType.openai,
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          apiModelRepositoryProvider.overrideWithValue(
            _FakeApiModelRepository(providers: providers),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(apiModelProvidersProvider.future);
      expect(result.map((provider) => provider.id), [
        'openai-codex',
        'openai',
      ]);
    });
  });

  group('getAllModelsProvider', () {
    test('returns all models from repository', () async {
      final models = [
        const ApiModelEntity(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
          modalitiesInput: [],
          modalitiesOuput: [],
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          apiModelRepositoryProvider.overrideWithValue(
            _FakeApiModelRepository(models: models),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(getAllModelsProvider.future);
      expect(result, hasLength(1));
      expect(result.firstOrNull?.id, 'gpt-4');
    });
  });

  group('getModelByProviderAndModelIdProvider', () {
    test('returns matching model', () async {
      final models = [
        const ApiModelEntity(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
          modalitiesInput: [],
          modalitiesOuput: [],
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          apiModelRepositoryProvider.overrideWithValue(
            _FakeApiModelRepository(models: models),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        getModelByProviderAndModelIdProvider(
          providerId: 'openai',
          modelId: 'gpt-4',
        ).future,
      );
      expect(result, isNotNull);
      expect((result ?? fail('Expected result to be non-null')).id, 'gpt-4');
    });

    test('returns null when no match', () async {
      final container = ProviderContainer(
        overrides: [
          apiModelRepositoryProvider.overrideWithValue(
            _FakeApiModelRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        getModelByProviderAndModelIdProvider(
          providerId: 'openai',
          modelId: 'nonexistent',
        ).future,
      );
      expect(result, isNull);
    });
  });

  group('modelSyncServiceProvider', () {
    test('creates ModelSyncService and cancels timer on dispose', () {
      final container = ProviderContainer(
        overrides: [
          apiModelRepositoryProvider.overrideWithValue(
            _FakeApiModelRepository(),
          ),
          modelApiServiceProvider.overrideWithValue(ModelApiService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(modelSyncServiceProvider);
      expect(service, isA<ModelSyncService>());

      container.dispose();
    });
  });

  group('getModelsByProviderProvider', () {
    test('returns models for given provider', () async {
      final models = [
        const ApiModelEntity(
          modelProvider: 'openai',
          id: 'gpt-4',
          name: 'GPT-4',
          limitContext: 128000,
          limitOutput: 4096,
          modalitiesInput: [],
          modalitiesOuput: [],
        ),
        const ApiModelEntity(
          modelProvider: 'anthropic',
          id: 'claude-3',
          name: 'Claude 3',
          limitContext: 200000,
          limitOutput: 4096,
          modalitiesInput: [],
          modalitiesOuput: [],
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          apiModelRepositoryProvider.overrideWithValue(
            _FakeApiModelRepository(models: models),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        getModelsByProviderProvider(providerId: 'openai').future,
      );
      expect(result, hasLength(1));
      expect(result.firstOrNull?.id, 'gpt-4');
    });
  });
}
