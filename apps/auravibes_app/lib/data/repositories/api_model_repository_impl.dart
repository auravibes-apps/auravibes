import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/api_model_provider_table.dart';
import 'package:auravibes_app/domain/entities/api_model.dart';
import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';

/// Implementation of the [ApiModelRepository] interface.
///
/// This class provides a concrete implementation of API model and provider
/// data operations using the Drift database. It handles the mapping between
/// domain entities and database records, and provides proper error handling.
class ApiModelRepositoryImpl implements ApiModelRepository {
  ApiModelRepositoryImpl(this._database);

  /// The database instance for API model operations.
  final AppDatabase _database;

  // Provider operations

  @override
  Future<List<ApiModelProviderEntity>> getAllProviders() async {
    final providerTables = await _database.apiModelProvidersDao
        .getAllProviders();
    return providerTables.map(_mapToProviderEntity).toList();
  }

  @override
  Future<List<ApiModelProviderEntity>> getProvidersByType(String type) async {
    final providerTables = await _database.apiModelProvidersDao
        .getProvidersByType(type);
    return providerTables.map(_mapToProviderEntity).toList();
  }

  // Model operations

  @override
  Future<List<ApiModelEntity>> getAllModels() async {
    final modelTables = await _database.apiModelsDao.getAllModels();
    return modelTables.map(_mapToModelEntity).toList();
  }

  @override
  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  ) async {
    final modelTable = await _database.apiModelsDao
        .getModelByProviderAndModelId(providerId, modelId);
    if (modelTable == null) return null;
    return _mapToModelEntity(modelTable);
  }

  @override
  Future<List<ApiModelEntity>> getModelsByProvider(String providerId) async {
    final modelTables = await _database.apiModelsDao.getModelsByProvider(
      providerId,
    );
    return modelTables.map(_mapToModelEntity).toList();
  }

  // Batch operations

  @override
  Future<List<ApiModelProviderEntity>> batchUpsertProviders(
    List<ApiModelProviderEntity> providers,
  ) async {
    final providerCompanions = providers
        .map(_modelProviderEntityToCompanion)
        .toList();

    final insertedProviders = await _database.apiModelProvidersDao
        .batchUpsertProviders(providerCompanions);

    return [
      for (final insertedProvider in insertedProviders)
        _mapToProviderEntity(insertedProvider),
    ];
  }

  @override
  Future<List<ApiModelEntity>> batchUpsertModels(
    List<ApiModelEntity> models,
  ) async {
    final modelCompanions = models.map(_mapEntityToCompanion).nonNulls.toList();
    final insertedModels = await _database.apiModelsDao.batchUpsertModels(
      modelCompanions,
    );

    return [
      for (final insertedModel in insertedModels)
        _mapToModelEntity(insertedModel),
    ];
  }

  @override
  Future<int> deleteAllData() async {
    final deletedModels = await _database.apiModelsDao.deleteAllModels();
    final deletedProviders = await _database.apiModelProvidersDao
        .deleteAllProviders();
    return deletedModels + deletedProviders;
  }

  // Helper methods

  /// Maps a database table record to a domain entity.
  ApiModelProviderEntity _mapToProviderEntity(
    ApiModelProvidersTable providerTable,
  ) {
    return ApiModelProviderEntity(
      id: providerTable.id,
      name: providerTable.name,
      type: _mapToTypeTable(providerTable.type),
      doc: providerTable.doc,
      url: providerTable.url,
    );
  }

  ApiModelProvidersCompanion _modelProviderEntityToCompanion(
    ApiModelProviderEntity entity,
  ) {
    return ApiModelProvidersCompanion(
      id: .new(entity.id),
      name: .new(entity.name),
      doc: .new(entity.doc),
      url: .new(entity.url),
      type: .absentIfNull(_mapTableToType(entity.type)),
    );
  }

  ModelProvidersType? _mapToTypeTable(ModelProvidersTableType? type) {
    if (type == null) return null;
    return switch (type) {
      .openai => .openai,
      .anthropic => .anthropic,
    };
  }

  ModelProvidersTableType? _mapTableToType(ModelProvidersType? type) {
    if (type == null) return null;
    return switch (type) {
      .openai => .openai,
      .anthropic => .anthropic,
    };
  }

  /// Maps a database table record to a domain entity.
  ApiModelEntity _mapToModelEntity(ApiModelsTable modelTable) {
    return ApiModelEntity(
      id: modelTable.id,
      name: modelTable.name,
      costCacheRead: modelTable.costCacheRead,
      costInput: modelTable.costInput,
      costOutput: modelTable.costOutput,
      limitContext: modelTable.limitContext,
      limitOutput: modelTable.limitOutput,
      modalitiesInput: modelTable.modalitiesInput ?? [],
      modalitiesOuput: modelTable.modalitiesOuput ?? [],
      modelProvider: modelTable.modelProvider,

      openWeights: modelTable.openWeights,
    );
  }

  ApiModelsCompanion? _mapEntityToCompanion(ApiModelEntity? entity) {
    if (entity == null) return null;
    return ApiModelsCompanion(
      id: .new(entity.id),
      name: .new(entity.name),
      costCacheRead: .new(entity.costCacheRead),
      costInput: .new(entity.costInput),
      costOutput: .new(entity.costOutput),
      limitContext: .new(entity.limitContext),
      limitOutput: .new(entity.limitOutput),
      modalitiesInput: .new(entity.modalitiesInput),
      modalitiesOuput: .new(entity.modalitiesOuput),
      modelProvider: .new(entity.modelProvider),
      openWeights: .new(entity.openWeights),
    );
  }
}
