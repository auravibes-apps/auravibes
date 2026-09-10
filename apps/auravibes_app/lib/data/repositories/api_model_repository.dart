// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';

/// Implementation of the [ApiModelRepository] interface.
///
/// This class provides a concrete implementation of API model and provider
/// data operations using the Drift database. It handles the mapping between
/// domain entities and database records, and provides proper error handling.
class ApiModelRepository implements ModelCatalogStore {
  new(this._database);

  /// The database instance for API model operations.
  final AppDatabase _database;

  // Provider operations.

  @override
  Future<List<ApiModelProviderEntity>> getAllProviders() async {
    final providerTables = await _database.apiModelProvidersDao
        .getAllProviders();

    return providerTables.map(this._mapToProviderEntity).toList();
  }

  @override
  Stream<List<ApiModelProviderEntity>> watchAllProviders() {
    return _database.apiModelProvidersDao.watchAllProviders().map(
      (providers) => providers.map(this._mapToProviderEntity).toList(),
    );
  }

  Future<List<ApiModelProviderEntity>> getProvidersByType(String type) async {
    final providerTables = await _database.apiModelProvidersDao
        .getProvidersByType(type);

    return providerTables.map(this._mapToProviderEntity).toList();
  }

  // Model operations.

  @override
  Future<List<ApiModelEntity>> getAllModels() async {
    final modelTables = await _database.apiModelsDao.getAllModels();

    return modelTables.map(this._mapToModelEntity).toList();
  }

  @override
  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  ) async {
    final modelTable = await _database.apiModelsDao
        .getModelByProviderAndModelId(providerId, modelId);
    if (modelTable == null) return null;

    return this._mapToModelEntity(modelTable);
  }

  @override
  Future<List<ApiModelEntity>> getModelsByProvider(String providerId) async {
    final modelTables = await _database.apiModelsDao.getModelsByProvider(
      providerId,
    );

    return modelTables.map(this._mapToModelEntity).toList();
  }

  @override
  Stream<List<ApiModelEntity>> watchModelsByProvider(String providerId) {
    return _database.apiModelsDao
        .watchModelsByProvider(providerId)
        .map((models) => models.map(this._mapToModelEntity).toList());
  }
}

extension ApiModelRepositoryBatchOperations on ApiModelRepository {
  Future<List<ApiModelProviderEntity>> batchUpsertProviders(
    List<ApiModelProviderEntity> providers,
  ) async {
    final providerCompanions = providers
        .map(this._modelProviderEntityToCompanion)
        .toList();

    final insertedProviders = await _database.apiModelProvidersDao
        .batchUpsertProviders(providerCompanions);

    return [
      for (final insertedProvider in insertedProviders)
        this._mapToProviderEntity(insertedProvider),
    ];
  }

  Future<List<ApiModelEntity>> batchUpsertModels(
    List<ApiModelEntity> models,
  ) async {
    final modelCompanions = models
        .map(this._mapEntityToCompanion)
        .nonNulls
        .toList();
    final insertedModels = await _database.apiModelsDao.batchUpsertModels(
      modelCompanions,
    );

    return [
      for (final insertedModel in insertedModels)
        this._mapToModelEntity(insertedModel),
    ];
  }

  Future<void> replaceAllData({
    required List<ApiModelProviderEntity> providers,
    required List<ApiModelEntity> models,
  }) async {
    await _database.transaction(
      () => _replaceAllData(providers: providers, models: models),
    );
  }

  Future<void> _replaceAllData({
    required List<ApiModelProviderEntity> providers,
    required List<ApiModelEntity> models,
  }) async {
    final _ = await batchUpsertProviders(providers);
    final _ = await batchUpsertModels(models);
    await _removeStaleModels(models);
    await _removeStaleProviders(providers);
  }

  Future<void> _removeStaleModels(List<ApiModelEntity> models) async {
    final nextModelKeys = models
        .map((model) => (provider: model.modelProvider, id: model.id))
        .toSet();
    final existingModels = await _database.apiModelsDao.getAllModels();

    for (final model in existingModels) {
      final key = (provider: model.modelProvider, id: model.id);
      if (nextModelKeys.contains(key)) continue;

      final _ = await _database.apiModelsDao.deleteModelByProviderAndId(
        model.modelProvider,
        model.id,
      );
    }
  }

  Future<void> _removeStaleProviders(
    List<ApiModelProviderEntity> providers,
  ) async {
    final nextProviderIds = providers.map((provider) => provider.id).toSet();
    final existingProviders = await _database.apiModelProvidersDao
        .getAllProviders();

    for (final provider in existingProviders) {
      if (nextProviderIds.contains(provider.id)) continue;

      final _ = await _database.apiModelProvidersDao.deleteProvider(
        provider.id,
      );
    }
  }
}

extension on ApiModelRepository {
  /// Maps a database table record to a domain entity.
  ApiModelProviderEntity _mapToProviderEntity(
    ApiModelProvidersTable providerTable,
  ) {
    return ApiModelProviderEntity(
      id: providerTable.id,
      name: providerTable.name,
      type: this._mapToTypeTable(providerTable.type),
      url: providerTable.url,
      doc: providerTable.doc,
    );
  }

  ApiModelProvidersCompanion _modelProviderEntityToCompanion(
    ApiModelProviderEntity entity,
  ) {
    return ApiModelProvidersCompanion(
      id: .new(entity.id),
      name: .new(entity.name),
      type: .absentIfNull(this._mapTableToType(entity.type)),
      url: .new(entity.url),
      doc: .new(entity.doc),
    );
  }

  ModelProvidersType? _mapToTypeTable(ModelProvidersTableType? type) {
    if (type == null) return null;

    return switch (type) {
      .openai => .openai,
      .anthropic => .anthropic,
      .openrouter => .openrouter,
    };
  }

  ModelProvidersTableType? _mapTableToType(ModelProvidersType? type) {
    if (type == null) return null;

    return switch (type) {
      .openai => .openai,
      .anthropic => .anthropic,
      .openrouter => .openrouter,
    };
  }

  /// Maps a database table record to a domain entity.
  ApiModelEntity _mapToModelEntity(ApiModelsTable modelTable) {
    return _addModelCapabilities(_baseModelEntity(modelTable), modelTable);
  }

  ApiModelEntity _baseModelEntity(ApiModelsTable modelTable) => ApiModelEntity(
    modelProvider: modelTable.modelProvider,
    id: modelTable.id,
    name: modelTable.name,
    limitContext: modelTable.limitContext,
    limitOutput: modelTable.limitOutput,
    modalitiesInput: modelTable.modalitiesInput ?? [],
    modalitiesOutput: modelTable.modalitiesOutput ?? [],
  );

  ApiModelEntity _addModelCapabilities(
    ApiModelEntity model,
    ApiModelsTable modelTable,
  ) => model.copyWith(
    family: modelTable.family,
    costInput: modelTable.costInput,
    costCacheRead: modelTable.costCacheRead,
    costOutput: modelTable.costOutput,
    openWeights: modelTable.openWeights,
    supportsReasoning: modelTable.supportsReasoning,
    isCanonical: modelTable.isCanonical,
    supportsPriorityMode: modelTable.supportsPriorityMode,
    supportsToolCalls: modelTable.supportsToolCalls,
  );

  ApiModelsCompanion? _mapEntityToCompanion(ApiModelEntity? entity) {
    if (entity == null) return null;

    return _addModelMetadata(_baseModelCompanion(entity), entity);
  }

  ApiModelsCompanion _baseModelCompanion(ApiModelEntity entity) =>
      ApiModelsCompanion(
        modelProvider: .new(entity.modelProvider),
        id: .new(entity.id),
        name: .new(entity.name),
      );

  ApiModelsCompanion _addModelMetadata(
    ApiModelsCompanion companion,
    ApiModelEntity entity,
  ) {
    return companion
        .copyWith(
          family: .new(entity.family),
          modalitiesInput: .new(entity.modalitiesInput),
          modalitiesOutput: .new(entity.modalitiesOutput),
        )
        .copyWith(
          openWeights: .new(entity.openWeights),
          supportsReasoning: .new(entity.supportsReasoning),
          isCanonical: .new(entity.isCanonical),
          supportsPriorityMode: .new(entity.supportsPriorityMode),
          supportsToolCalls: .new(entity.supportsToolCalls),
        )
        .copyWith(
          costInput: .new(entity.costInput),
          costOutput: .new(entity.costOutput),
          costCacheRead: .new(entity.costCacheRead),
          limitContext: .new(entity.limitContext),
          limitOutput: .new(entity.limitOutput),
        );
  }
}
