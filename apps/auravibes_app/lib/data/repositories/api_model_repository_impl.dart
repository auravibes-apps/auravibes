// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
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

  // Provider operations.

  @override
  Future<List<ApiModelProviderEntity>> getAllProviders() async {
    final providerTables = await _database.apiModelProvidersDao
        .getAllProviders();

    return providerTables.map(_mapToProviderEntity).toList();
  }

  @override
  Stream<List<ApiModelProviderEntity>> watchAllProviders() {
    return _database.apiModelProvidersDao.watchAllProviders().map(
      (providers) => providers.map(_mapToProviderEntity).toList(),
    );
  }

  @override
  Future<List<ApiModelProviderEntity>> getProvidersByType(String type) async {
    final providerTables = await _database.apiModelProvidersDao
        .getProvidersByType(type);

    return providerTables.map(_mapToProviderEntity).toList();
  }

  // Model operations.

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

  @override
  Stream<List<ApiModelEntity>> watchModelsByProvider(String providerId) {
    return _database.apiModelsDao
        .watchModelsByProvider(providerId)
        .map(
          (models) => models.map(_mapToModelEntity).toList(),
        );
  }

  // Batch operations.

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

  @override
  Future<void> replaceAllData({
    required List<ApiModelProviderEntity> providers,
    required List<ApiModelEntity> models,
  }) async {
    final providerCompanions = providers
        .map(_modelProviderEntityToCompanion)
        .toList();
    final modelCompanions = models.map(_mapEntityToCompanion).nonNulls.toList();

    // Single transaction: a failure in any step rolls back the deletes, so a
    // transient upsert error can't leave the data source empty.
    // Order mirrors deleteAllData: models reference providers (no cascade), so
    // models must be deleted before providers, and providers inserted first.
    await _database.transaction(() async {
      final _ = await _database.apiModelsDao.deleteAllModels();
      final _ = await _database.apiModelProvidersDao.deleteAllProviders();
      final _ = await _database.apiModelProvidersDao.batchUpsertProviders(
        providerCompanions,
      );
      final _ = await _database.apiModelsDao.batchUpsertModels(modelCompanions);
    });
  }

  // Helper methods.

  /// Maps a database table record to a domain entity.
  ApiModelProviderEntity _mapToProviderEntity(
    ApiModelProvidersTable providerTable,
  ) {
    return ApiModelProviderEntity(
      id: providerTable.id,
      name: providerTable.name,
      type: _mapToTypeTable(providerTable.type),
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
      type: .absentIfNull(_mapTableToType(entity.type)),
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
    return ApiModelEntity(
      modelProvider: modelTable.modelProvider,
      id: modelTable.id,
      name: modelTable.name,
      limitContext: modelTable.limitContext,
      limitOutput: modelTable.limitOutput,
      modalitiesInput: modelTable.modalitiesInput ?? [],
      modalitiesOuput: modelTable.modalitiesOuput ?? [],
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
  }

  ApiModelsCompanion? _mapEntityToCompanion(ApiModelEntity? entity) {
    if (entity == null) return null;

    return ApiModelsCompanion(
      modelProvider: .new(entity.modelProvider),
      id: .new(entity.id),
      name: .new(entity.name),
      family: .new(entity.family),
      modalitiesInput: .new(entity.modalitiesInput),
      modalitiesOuput: .new(entity.modalitiesOuput),
      openWeights: .new(entity.openWeights),
      supportsReasoning: .new(entity.supportsReasoning),
      isCanonical: .new(entity.isCanonical),
      supportsPriorityMode: .new(entity.supportsPriorityMode),
      supportsToolCalls: .new(entity.supportsToolCalls),
      costInput: .new(entity.costInput),
      costOutput: .new(entity.costOutput),
      costCacheRead: .new(entity.costCacheRead),
      limitContext: .new(entity.limitContext),
      limitOutput: .new(entity.limitOutput),
    );
  }
}
