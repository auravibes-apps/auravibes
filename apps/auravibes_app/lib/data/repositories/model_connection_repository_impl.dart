// ignore_for_file: avoid-substring
// Required: Existing parsing uses code-unit substring offsets.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:drift/drift.dart';

/// Implementation of the [ModelConnectionRepository] interface.
///
/// This class provides a concrete implementation of model connection data
/// operations using the Drift database. It handles the mapping between domain
/// entities and database records, and provides proper error handling using
/// exceptions.
class ModelConnectionRepositoryImpl implements ModelConnectionRepository {
  ModelConnectionRepositoryImpl({
    required this._database,
    required this._encryptionService,
    ModelProviderServices? modelProviderServices,
  }) : _modelProviderServices =
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
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(
    String modelConnectionId,
  ) async {
    final modelConnection = await _database.modelConnectionsDao
        .getModelConnectionById(modelConnectionId);
    if (modelConnection == null) return null;
    return ModelConnectionForEdit(
      id: modelConnection.id,
      name: modelConnection.name,
      modelId: modelConnection.serviceId,
      workspaceId: modelConnection.workspaceId,
      hasKey: modelConnection.encryptedAuthValue?.isNotEmpty == true,
      url: modelConnection.url,
      keySuffix: modelConnection.keySuffix,
    );
  }

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String modelConnectionId,
    ModelConnectionToUpdate modelConnection,
  ) async {
    final existing = await _database.modelConnectionsDao.getModelConnectionById(
      modelConnectionId,
    );
    if (existing == null) {
      throw ModelConnectionException(
        'Model connection with ID "$modelConnectionId" not found',
      );
    }
    final modelProvider = await _database.apiModelProvidersDao.getProviderById(
      existing.serviceId,
    );
    if (modelProvider == null) {
      throw ModelConnectionModelNotFoundException(existing.serviceId);
    }
    final modelType = modelProvider.type;
    if (modelType == null) {
      throw ModelConnectionNoTypeException(existing.serviceId);
    }

    final key = modelConnection.key?.trim().isEmpty == true
        ? null
        : modelConnection.key;
    final existingEncryptedKey = existing.encryptedAuthValue;
    if (key == null &&
        (existingEncryptedKey == null || existingEncryptedKey.isEmpty)) {
      throw const ModelConnectionException('Model connection has no API key');
    }
    final keyForValidation =
        key ??
        await _encryptionService.decrypt(
          existingEncryptedKey ??
              (throw const ModelConnectionException(
                'Model connection has no API key',
              )),
        );
    final hasUrlUpdate = modelConnection.url != null;
    var nextUrl = existing.url;
    if (hasUrlUpdate) {
      final url = modelConnection.url;
      final updatedUrl = url?.trim();
      nextUrl = updatedUrl?.isEmpty == true ? null : url;
    }
    final models = await _modelProviderServices.getWorkspaceModelSelections(
      ModelProvider(
        type: .fromString(modelType.value),
        key: keyForValidation,
        url: nextUrl ?? modelProvider.url,
      ),
    );
    if (models == null) {
      throw ModelConnectionNoModelsException(existing.serviceId);
    }

    final encryptedKey = key == null
        ? existing.encryptedAuthValue
        : await _encryptionService.encrypt(key);
    final keySuffix = key == null ? existing.keySuffix : _keySuffix(key);
    final updated = await _database.modelConnectionsDao.updateModelConnection(
      modelConnectionId,
      ServiceConnectionsCompanion(
        name: .absentIfNull(modelConnection.name),
        url: hasUrlUpdate ? Value(nextUrl) : const Value.absent(),
        encryptedAuthValue: .absentIfNull(encryptedKey),
        keySuffix: .absentIfNull(keySuffix),
      ),
    );
    if (updated == null) {
      throw ModelConnectionException(
        'Model connection with ID "$modelConnectionId" not found',
      );
    }

    return _modelProviderTableToEntity(updated);
  }

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) async {
    if (filter.workspaces.isEmpty) {
      return [];
    }
    final modelConnections = await _database.modelConnectionsDao
        .getAllModelConnectionsByWorkspace(workspaceIds: filter.workspaces);

    return modelConnections.map(_modelProviderTableToEntity).toList();
  }

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) {
    if (filter.workspaces.isEmpty) {
      return Stream.value(const []);
    }
    return _database.modelConnectionsDao
        .watchAllModelConnectionsByWorkspace(workspaceIds: filter.workspaces)
        .map(
          (modelConnections) =>
              modelConnections.map(_modelProviderTableToEntity).toList(),
        );
  }

  ServiceConnectionsCompanion _modelProviderToCreateToCompanion(
    ModelConnectionToCreate modelConnection,
    String encryptedApiKey,
    String keySuffix,
  ) {
    return ServiceConnectionsCompanion(
      name: .new(modelConnection.name),
      serviceId: .new(modelConnection.modelId),
      kind: const Value(ServiceConnectionKindTable.modelProvider),
      authenticationType: const Value(ServiceAuthenticationTypeTable.apiKey),
      url: .absentIfNull(modelConnection.url),
      encryptedAuthValue: .new(encryptedApiKey),
      keySuffix: .new(keySuffix),
      workspaceId: .new(modelConnection.workspaceId),
    );
  }

  String _keySuffix(String key) {
    return key.length >= 6 ? key.substring(key.length - 6) : key;
  }

  ModelConnectionEntity _modelProviderTableToEntity(
    ServiceConnectionTable modelConnection,
  ) {
    return ModelConnectionEntity(
      id: modelConnection.id,
      name: modelConnection.name,
      key: modelConnection.encryptedAuthValue ?? '',
      modelId: modelConnection.serviceId,
      createdAt: modelConnection.createdAt,
      updatedAt: modelConnection.updatedAt,
      workspaceId: modelConnection.workspaceId,
      url: modelConnection.url,
      keySuffix: modelConnection.keySuffix,
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
