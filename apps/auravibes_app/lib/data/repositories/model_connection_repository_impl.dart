import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider_services.dart';
import 'package:drift/drift.dart';

/// Implementation of the [ModelConnectionRepository] interface.
///
/// This class provides a concrete implementation of model connection data
/// operations using the Drift database. It handles the mapping between domain
/// entities and database records, and provides proper error handling using
/// exceptions.
class ModelConnectionRepositoryImpl implements ModelConnectionRepository {
  ModelConnectionRepositoryImpl({
    required AppDatabase database,
    required EncryptionService encryptionService,
    ModelProviderServices? modelProviderServices,
  }) : _database = database,
       _encryptionService = encryptionService,
       _modelProviderServices =
           modelProviderServices ?? ModelProviderServices();

  final AppDatabase _database;
  final EncryptionService _encryptionService;
  final ModelProviderServices _modelProviderServices;

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate modelConnection,
  ) async {
    final modelProvider = await _database.apiModelProvidersDao.getProviderById(
      modelConnection.modelId,
    );
    if (modelProvider == null) {
      throw ModelConnectionModelNotFoundException(modelConnection.modelId);
    }
    final modelType = modelProvider.type;
    if (modelType == null) {
      throw ModelConnectionNoTypeException(modelConnection.modelId);
    }

    // Extract last 6 characters for display
    final keySuffix = modelConnection.key.length >= 6
        ? modelConnection.key.substring(modelConnection.key.length - 6)
        : modelConnection.key;

    // Store API key encrypted
    final encryptedApiKey = await _encryptionService.encrypt(
      modelConnection.key,
    );

    // Validate API key with model provider
    final models = await _modelProviderServices.getWorkspaceModelSelections(
      ModelProvider(
        type: .fromString(modelType.value),
        key: modelConnection.key,
        url: modelConnection.url ?? modelProvider.url,
      ),
    );
    if (models == null) {
      throw ModelConnectionNoModelsException(modelConnection.modelId);
    }

    final createdModelConnection = await _database.modelConnectionsDao
        .insertModelConnection(
          _modelProviderToCreateToCompanion(
            modelConnection,
            encryptedApiKey,
            keySuffix,
          ),
        );

    final workspaceModelSelections = models
        .map(
          (model) =>
              model.copyWith(modelConnectionId: createdModelConnection.id),
        )
        .toList();

    await _database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
      workspaceModelSelections
          .map(_workspaceModelSelectionToCreateToCompanion)
          .toList(),
    );

    return _modelProviderTableToEntity(createdModelConnection);
  }

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) async {
    if (filter.workspaces?.isNotEmpty != true) {
      return [];
    }
    final modelConnections = await _database.modelConnectionsDao
        .getAllModelConnectionsByWorkspace(workspaceIds: filter.workspaces!);

    return modelConnections.map(_modelProviderTableToEntity).toList();
  }

  ModelConnectionsCompanion _modelProviderToCreateToCompanion(
    ModelConnectionToCreate modelConnection,
    String encryptedApiKey,
    String keySuffix,
  ) {
    return ModelConnectionsCompanion(
      name: .new(modelConnection.name),
      keyValue: .new(encryptedApiKey),
      keySuffix: .new(keySuffix),
      url: .absentIfNull(modelConnection.url),
      workspaceId: .new(modelConnection.workspaceId),
      modelId: .new(modelConnection.modelId),
    );
  }

  ModelConnectionEntity _modelProviderTableToEntity(
    ModelConnectionTable modelConnection,
  ) {
    return ModelConnectionEntity(
      id: modelConnection.id,
      name: modelConnection.name,
      modelId: modelConnection.modelId,
      key: modelConnection.keyValue,
      keySuffix: modelConnection.keySuffix,
      url: modelConnection.url,
      createdAt: modelConnection.createdAt,
      updatedAt: modelConnection.updatedAt,
      workspaceId: modelConnection.workspaceId,
    );
  }

  WorkspaceModelSelectionsCompanion _workspaceModelSelectionToCreateToCompanion(
    WorkspaceModelSelectionToCreate workspaceModelSelection,
  ) {
    return WorkspaceModelSelectionsCompanion(
      modelId: Value(workspaceModelSelection.modelId),
      modelConnectionId: Value(workspaceModelSelection.modelConnectionId),
    );
  }

  @override
  Future<void> deleteModelConnection(String modelConnectionId) async {
    // Verify the model connection exists before attempting deletion
    final modelConnection = await _database.modelConnectionsDao
        .getModelConnectionById(
          modelConnectionId,
        );
    if (modelConnection == null) {
      throw ModelConnectionException(
        'Model connection with ID "$modelConnectionId" not found',
      );
    }

    // Delete from database
    await _database.modelConnectionsDao.deleteModelConnection(
      modelConnectionId,
    );
  }
}
