// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:drift/drift.dart';

typedef _ModelConnectionUpdatePayload = ({
  String? encryptedKey,
  bool hasUrlUpdate,
  String? keySuffix,
  List<WorkspaceModelSelectionToCreate> models,
  String? nextUrl,
});

typedef _OAuthCreateData = ({
  OAuthTokenEntity token,
  ServiceConnectionMetadata metadata,
  String encryptedToken,
  List<String> modelIds,
});

typedef _ValidatedOAuthData = ({
  OAuthTokenEntity token,
  ServiceConnectionMetadata metadata,
});

typedef _UpdateValidationData = ({
  ({ApiModelProvidersTable provider, String type}) provider,
  String? key,
  String keyForValidation,
  bool hasUrlUpdate,
  String? nextUrl,
});

typedef _ApiKeyConnectionInsertData = ({
  ModelConnectionToCreate modelConnection,
  String encryptedApiKey,
  String keySuffix,
  List<WorkspaceModelSelectionToCreate> models,
});

typedef _UpdateKeyData = ({String? key, String keyForValidation});

typedef _WorkspaceSelectionUpdateData = ({
  Set<String> existingModelIds,
  Set<String> removedIds,
});

typedef _UpdatePayloadBuildData = ({
  _UpdateValidationData validation,
  List<WorkspaceModelSelectionToCreate> models,
  String? encryptedKey,
  String? existingKeySuffix,
});

/// Implementation of the [ModelConnectionRepository] interface.
///
/// This class provides a concrete implementation of model connection data
/// operations using the Drift database. It handles the mapping between domain
/// entities and database records, and provides proper error handling using
/// exceptions.
class ModelConnectionRepository({
  required final AppDatabase _database,
  required final EncryptionService _encryptionService,
  ModelProviderServices? modelProviderServices,
}) implements ModelConnectionStore {
  static const _missingApiKeyMessage = 'Model connection has no API key';
  final ModelProviderServices _modelProviderServices =
      modelProviderServices ?? ModelProviderServices();

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate modelConnection,
  ) async {
    if (modelConnection.authMode == ModelProviderAuthMode.oauth2) {
      return await _createOAuthModelConnection(modelConnection);
    }

    return await _createApiKeyModelConnection(modelConnection);
  }

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(
    String modelConnectionId,
  ) async {
    final modelConnection = await _database.modelConnectionsDao
        .getModelConnectionById(modelConnectionId);
    if (modelConnection == null) return null;

    return _modelConnectionForEdit(modelConnection);
  }

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String modelConnectionId,
    ModelConnectionToUpdate modelConnection,
  ) async {
    final existing = await _editableModelConnection(modelConnectionId);
    final payload = await _updatePayload(existing, modelConnection);
    final updated = await _updateModelConnection(
      modelConnectionId,
      modelConnection,
      payload,
    );

    return _updatedModelConnectionEntity(updated, modelConnectionId);
  }

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

  @override
  Future<void> deleteModelConnection(String modelConnectionId) async {
    // Verify the model connection exists before attempting deletion.
    final modelConnection = await _database.modelConnectionsDao
        .getModelConnectionById(modelConnectionId);
    if (modelConnection == null) {
      throw ModelConnectionException(
        'Model connection with ID "$modelConnectionId" not found',
      );
    }

    // Delete from database.
    await _database.modelConnectionsDao.deleteModelConnection(
      modelConnectionId,
    );
  }
}

extension ModelConnectionRepositoryHelpers on ModelConnectionRepository {
  Future<ModelConnectionEntity> _createApiKeyModelConnection(
    ModelConnectionToCreate modelConnection,
  ) async {
    final provider = await _modelProviderForCreate(modelConnection.modelId);
    final data = await _apiKeyConnectionInsertData(modelConnection, provider);
    final created = await _insertApiKeyConnection(data);

    return _modelProviderTableToEntity(created);
  }

  Future<_ApiKeyConnectionInsertData> _apiKeyConnectionInsertData(
    ModelConnectionToCreate modelConnection,
    ApiModelProvidersTable provider,
  ) async {
    final key = _requiredApiKey(modelConnection.key);
    final encryptedApiKey = await _encryptApiKey(key);
    final models = await _modelsForCreate(modelConnection, provider, key);

    return (
      modelConnection: modelConnection,
      encryptedApiKey: encryptedApiKey,
      keySuffix: _keySuffix(key),
      models: models,
    );
  }

  Future<ApiModelProvidersTable> _modelProviderForCreate(String modelId) async {
    final provider = await _database.apiModelProvidersDao.getProviderById(
      modelId,
    );
    if (provider == null) {
      throw ModelConnectionModelNotFoundException(modelId);
    }
    if (provider.type == null) {
      throw ModelConnectionNoTypeException(modelId);
    }

    return provider;
  }

  String _requiredApiKey(String value) {
    final key = value.trim();
    if (key.isEmpty) {
      throw const ModelConnectionException(
        ModelConnectionRepository._missingApiKeyMessage,
      );
    }

    return key;
  }

  Future<String> _encryptApiKey(String key) => _encryptionService.encrypt(
    ServiceConnectionAuthCodec.encodeSecret(
      ServiceConnectionSecretApiKey(apiKey: key),
    ),
  );
}

extension ModelConnectionCreateValidation on ModelConnectionRepository {
  Future<List<WorkspaceModelSelectionToCreate>> _modelsForCreate(
    ModelConnectionToCreate modelConnection,
    ApiModelProvidersTable provider,
    String key,
  ) async {
    final modelType = _requiredCreateModelType(
      provider,
      modelConnection.modelId,
    );
    final models = await _workspaceModelSelectionsForCreate(
      modelType,
      key,
      modelConnection.url ?? provider.url,
    );

    return _requiredCreateModels(models, modelConnection.modelId);
  }

  ModelProvidersTableType _requiredCreateModelType(
    ApiModelProvidersTable provider,
    String modelId,
  ) {
    final modelType = provider.type;
    if (modelType == null) {
      throw ModelConnectionNoTypeException(modelId);
    }

    return modelType;
  }

  List<WorkspaceModelSelectionToCreate> _requiredCreateModels(
    List<WorkspaceModelSelectionToCreate>? models,
    String modelId,
  ) {
    if (models == null) {
      throw ModelConnectionNoModelsException(modelId);
    }

    return models;
  }

  Future<List<WorkspaceModelSelectionToCreate>?>
  _workspaceModelSelectionsForCreate(
    ModelProvidersTableType modelType,
    String key,
    String? url,
  ) => _modelProviderServices.getWorkspaceModelSelections(
    .new(type: .fromString(modelType.value), key: key, url: url),
  );
}

extension ModelConnectionCreatePersistence on ModelConnectionRepository {
  Future<ServiceConnectionTable> _insertApiKeyConnection(
    _ApiKeyConnectionInsertData data,
  ) => _database.transaction(() => _insertApiKeyTransaction(data));

  Future<ServiceConnectionTable> _insertApiKeyTransaction(
    _ApiKeyConnectionInsertData data,
  ) async {
    final created = await _database.modelConnectionsDao.insertModelConnection(
      _modelProviderToCreateToCompanion(
        data.modelConnection,
        data.encryptedApiKey,
        data.keySuffix,
      ),
    );
    await _insertWorkspaceModelSelections(created.id, data.models);

    return created;
  }

  Future<void> _insertWorkspaceModelSelections(
    String modelConnectionId,
    List<WorkspaceModelSelectionToCreate> models,
  ) => _database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
    models
        .map((model) => model.copyWith(modelConnectionId: modelConnectionId))
        .map(_workspaceModelSelectionToCreateToCompanion)
        .toList(),
  );
}

extension ModelConnectionOAuthCreation on ModelConnectionRepository {
  Future<ModelConnectionEntity> _createOAuthModelConnection(
    ModelConnectionToCreate modelConnection,
  ) async {
    final data = await _oauthCreateData(modelConnection);
    final created = await _insertOAuthConnection(modelConnection, data);

    return _modelProviderTableToEntity(created);
  }

  Future<_OAuthCreateData> _oauthCreateData(
    ModelConnectionToCreate modelConnection,
  ) async {
    final validated = _validatedOAuthData(modelConnection);
    final encryptedToken = await _encryptOAuthToken(validated.token);
    final modelIds = _requiredOAuthModelIds(modelConnection.modelIds);

    return (
      token: validated.token,
      metadata: validated.metadata,
      encryptedToken: encryptedToken,
      modelIds: modelIds,
    );
  }

  _ValidatedOAuthData _validatedOAuthData(
    ModelConnectionToCreate modelConnection,
  ) {
    final token = modelConnection.oauthToken;
    final metadata = modelConnection.oauthMetadata;
    if (token == null || metadata == null) {
      throw const ModelConnectionException('OAuth token is required');
    }

    _requireCodexProvider(modelConnection.modelId);

    return (token: token, metadata: metadata);
  }

  Future<String> _encryptOAuthToken(OAuthTokenEntity token) =>
      _encryptionService.encrypt(
        ServiceConnectionAuthCodec.encodeSecret(
          ServiceConnectionSecretOAuth2(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            idToken: token.idToken,
          ),
        ),
      );

  void _requireCodexProvider(String modelId) {
    if (ModelProviderOAuthProfiles.isCodexProvider(modelId)) return;

    throw ModelConnectionException('OAuth profile not found: $modelId');
  }

  List<String> _requiredOAuthModelIds(List<String> modelIds) {
    if (modelIds.isNotEmpty) return modelIds;

    throw const ModelConnectionException(
      'OpenAI model catalog is unavailable. Retry after model sync.',
    );
  }
}

extension ModelConnectionOAuthPersistence on ModelConnectionRepository {
  Future<ServiceConnectionTable> _insertOAuthConnection(
    ModelConnectionToCreate modelConnection,
    _OAuthCreateData data,
  ) => _database.transaction(
    () => _insertOAuthTransaction(modelConnection, data),
  );

  Future<ServiceConnectionTable> _insertOAuthTransaction(
    ModelConnectionToCreate modelConnection,
    _OAuthCreateData data,
  ) async {
    final created = await _insertOAuthRecord(modelConnection, data);
    await _insertOAuthModelSelections(created.id, data.modelIds);

    return created;
  }

  Future<ServiceConnectionTable> _insertOAuthRecord(
    ModelConnectionToCreate modelConnection,
    _OAuthCreateData data,
  ) => _database.modelConnectionsDao.insertModelConnection(
    _oauthConnectionToCompanion(modelConnection, data),
  );
}

extension ModelConnectionOAuthCompanion on ModelConnectionRepository {
  ServiceConnectionsCompanion _oauthConnectionToCompanion(
    ModelConnectionToCreate modelConnection,
    _OAuthCreateData data,
  ) => _oauthConnectionMetadata(
    _oauthConnectionSecrets(
      _oauthConnectionBase(modelConnection),
      modelConnection,
      data,
    ),
    data,
  );

  ServiceConnectionsCompanion _oauthConnectionBase(
    ModelConnectionToCreate modelConnection,
  ) => .insert(
    name: modelConnection.name,
    serviceId: modelConnection.modelId,
    kind: ServiceConnectionKindTable.modelProvider,
    authenticationType: ServiceAuthenticationTypeTable.oauth2,
    workspaceId: modelConnection.workspaceId,
  );

  ServiceConnectionsCompanion _oauthConnectionSecrets(
    ServiceConnectionsCompanion base,
    ModelConnectionToCreate modelConnection,
    _OAuthCreateData data,
  ) => base.copyWith(
    url: .absentIfNull(modelConnection.url),
    encryptedAuthValue: .new(data.encryptedToken),
    keySuffix: .new(_keySuffix(data.token.accessToken)),
  );

  ServiceConnectionsCompanion _oauthConnectionMetadata(
    ServiceConnectionsCompanion base,
    _OAuthCreateData data,
  ) => base.copyWith(
    metadataJson: .new(
      ServiceConnectionAuthCodec.encodeMetadata(data.metadata),
    ),
    authStatus: const Value(ServiceConnectionAuthStatus.connected),
    expiresAt: .new(_expiresAt(data.token)),
    lastRefreshedAt: .new(data.token.issuedAt),
  );

  Future<void> _insertOAuthModelSelections(
    String modelConnectionId,
    List<String> modelIds,
  ) => _database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
    modelIds
        .map(
          (modelId) => WorkspaceModelSelectionsCompanion(
            modelId: .new(modelId),
            modelConnectionId: .new(modelConnectionId),
          ),
        )
        .toList(),
  );
}

extension ModelConnectionUpdateValidation on ModelConnectionRepository {
  Future<ServiceConnectionTable> _editableModelConnection(
    String modelConnectionId,
  ) async {
    final existing = await _database.modelConnectionsDao.getModelConnectionById(
      modelConnectionId,
    );
    if (existing == null) {
      throw ModelConnectionException(
        'Model connection with ID "$modelConnectionId" not found',
      );
    }

    return _requireEditableApiKeyConnection(existing);
  }

  ServiceConnectionTable _requireEditableApiKeyConnection(
    ServiceConnectionTable existing,
  ) {
    if (existing.authenticationType == ServiceAuthenticationTypeTable.oauth2) {
      throw const ModelConnectionException(
        'OAuth model connections must be reconnected instead of edited.',
      );
    }

    return existing;
  }

  Future<_ModelConnectionUpdatePayload> _updatePayload(
    ServiceConnectionTable existing,
    ModelConnectionToUpdate modelConnection,
  ) async {
    final validation = await _updateValidation(existing, modelConnection);

    return await _completeUpdatePayload(existing, validation);
  }

  Future<_ModelConnectionUpdatePayload> _completeUpdatePayload(
    ServiceConnectionTable existing,
    _UpdateValidationData validation,
  ) async {
    final models = await _modelsForUpdate(existing, validation);
    final encryptedKey = await _updatedEncryptedKey(
      validation.key,
      existing.encryptedAuthValue,
    );

    return _updatePayloadResult((
      validation: validation,
      models: models,
      encryptedKey: encryptedKey,
      existingKeySuffix: existing.keySuffix,
    ));
  }

  _ModelConnectionUpdatePayload _updatePayloadResult(
    _UpdatePayloadBuildData data,
  ) {
    final validation = data.validation;

    return (
      encryptedKey: data.encryptedKey,
      hasUrlUpdate: validation.hasUrlUpdate,
      keySuffix: _updatedKeySuffix(validation.key, data.existingKeySuffix),
      models: data.models,
      nextUrl: validation.nextUrl,
    );
  }

  Future<_UpdateValidationData> _updateValidation(
    ServiceConnectionTable existing,
    ModelConnectionToUpdate modelConnection,
  ) async {
    final provider = await _modelProviderForUpdate(existing.serviceId);

    return await _buildUpdateValidation(existing, modelConnection, provider);
  }

  Future<_UpdateValidationData> _buildUpdateValidation(
    ServiceConnectionTable existing,
    ModelConnectionToUpdate modelConnection,
    ({ApiModelProvidersTable provider, String type}) provider,
  ) async {
    final keyData = await _updateKeyData(
      modelConnection.key,
      existing.encryptedAuthValue,
    );

    return (
      provider: provider,
      key: keyData.key,
      keyForValidation: keyData.keyForValidation,
      hasUrlUpdate: modelConnection.url != null,
      nextUrl: _nextUpdateUrl(existing.url, modelConnection.url),
    );
  }
}

extension ModelConnectionUpdateInputs on ModelConnectionRepository {
  Future<_UpdateKeyData> _updateKeyData(
    String? input,
    String? encryptedKey,
  ) async {
    final key = _updateKey(input);

    return (
      key: key,
      keyForValidation: await _keyForValidation(key, encryptedKey),
    );
  }

  Future<String> _keyForValidation(String? key, String? encryptedKey) =>
      key == null ? _existingApiKey(encryptedKey) : Future.value(key);

  String? _nextUpdateUrl(String? existingUrl, String? updatedUrl) =>
      updatedUrl == null ? existingUrl : _nextConnectionUrl(updatedUrl);

  Future<List<WorkspaceModelSelectionToCreate>> _modelsForUpdate(
    ServiceConnectionTable existing,
    _UpdateValidationData validation,
  ) async {
    final models = await _modelProviderServices.getWorkspaceModelSelections(
      .new(
        type: .fromString(validation.provider.type),
        key: validation.keyForValidation,
        url: validation.nextUrl ?? validation.provider.provider.url,
      ),
    );
    if (models == null) {
      throw ModelConnectionNoModelsException(existing.serviceId);
    }

    return models;
  }
}

extension ModelConnectionUpdateSupport on ModelConnectionRepository {
  String? _updatedKeySuffix(String? key, String? existingKeySuffix) =>
      key == null ? existingKeySuffix : _keySuffix(key);

  Future<({ApiModelProvidersTable provider, String type})>
  _modelProviderForUpdate(String serviceId) async {
    final provider = await _database.apiModelProvidersDao.getProviderById(
      serviceId,
    );
    if (provider == null) {
      throw ModelConnectionModelNotFoundException(serviceId);
    }
    final type = provider.type;
    if (type == null) {
      throw ModelConnectionNoTypeException(serviceId);
    }

    return (provider: provider, type: type.value);
  }

  String? _updateKey(String? key) {
    if (key?.trim().isEmpty == true) return null;

    return key;
  }

  Future<String> _existingApiKey(String? encryptedKey) async {
    if (encryptedKey == null || encryptedKey.isEmpty) {
      throw const ModelConnectionException(
        ModelConnectionRepository._missingApiKeyMessage,
      );
    }

    return _decodeApiKey(await _encryptionService.decrypt(encryptedKey));
  }

  Future<String?> _updatedEncryptedKey(
    String? key,
    String? existingEncryptedKey,
  ) {
    if (key == null) return Future.value(existingEncryptedKey);

    return _encryptionService.encrypt(
      ServiceConnectionAuthCodec.encodeSecret(
        ServiceConnectionSecretApiKey(apiKey: key),
      ),
    );
  }
}

extension ModelConnectionUpdatePersistence on ModelConnectionRepository {
  ModelConnectionEntity _updatedModelConnectionEntity(
    ServiceConnectionTable? updated,
    String modelConnectionId,
  ) {
    if (updated == null) {
      throw ModelConnectionException(
        'Model connection with ID "$modelConnectionId" not found',
      );
    }

    return _modelProviderTableToEntity(updated);
  }

  Future<ServiceConnectionTable?> _updateModelConnection(
    String modelConnectionId,
    ModelConnectionToUpdate modelConnection,
    _ModelConnectionUpdatePayload payload,
  ) => _database.transaction(
    () => _updateConnectionAndSelections(
      modelConnectionId,
      modelConnection,
      payload,
    ),
  );

  Future<ServiceConnectionTable?> _updateConnectionAndSelections(
    String modelConnectionId,
    ModelConnectionToUpdate modelConnection,
    _ModelConnectionUpdatePayload payload,
  ) async {
    final updatedConnection = await _database.modelConnectionsDao
        .updateModelConnection(
          modelConnectionId,
          _modelConnectionUpdateCompanion(modelConnection, payload),
        );
    if (updatedConnection == null) return null;

    await _replaceWorkspaceModelSelections(modelConnectionId, payload.models);

    return updatedConnection;
  }

  ServiceConnectionsCompanion _modelConnectionUpdateCompanion(
    ModelConnectionToUpdate modelConnection,
    _ModelConnectionUpdatePayload payload,
  ) => .new(
    name: .absentIfNull(modelConnection.name),
    url: payload.hasUrlUpdate ? Value(payload.nextUrl) : const Value.absent(),
    encryptedAuthValue: .absentIfNull(payload.encryptedKey),
    keySuffix: .absentIfNull(payload.keySuffix),
  );
}

extension ModelConnectionSelectionPersistence on ModelConnectionRepository {
  Future<void> _replaceWorkspaceModelSelections(
    String modelConnectionId,
    List<WorkspaceModelSelectionToCreate> models,
  ) async {
    final existingSelections = await _database.workspaceModelSelectionsDao
        .getByModelConnectionId(modelConnectionId);
    final changes = _workspaceSelectionUpdateData(existingSelections, models);
    await _deleteWorkspaceModelSelections(changes.removedIds);
    await _insertNewWorkspaceModelSelections(
      modelConnectionId,
      models,
      changes.existingModelIds,
    );
  }

  Future<void> _deleteWorkspaceModelSelections(Set<String> selectionIds) async {
    final _ = await _database.workspaceModelSelectionsDao.deleteByIds(
      selectionIds,
    );
  }

  Future<void> _insertNewWorkspaceModelSelections(
    String modelConnectionId,
    Iterable<WorkspaceModelSelectionToCreate> models,
    Set<String> existingModelIds,
  ) => _database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
    _newWorkspaceModelSelections(modelConnectionId, models, existingModelIds),
  );

  _WorkspaceSelectionUpdateData _workspaceSelectionUpdateData(
    Iterable<WorkspaceModelSelectionTable> selections,
    Iterable<WorkspaceModelSelectionToCreate> models,
  ) {
    final existingModelIds = _existingModelIds(selections);
    final removedIds = _removedSelectionIds(selections, _nextModelIds(models));

    return (existingModelIds: existingModelIds, removedIds: removedIds);
  }

  Set<String> _existingModelIds(
    Iterable<WorkspaceModelSelectionTable> selections,
  ) => {for (final selection in selections) selection.modelId};

  Set<String> _nextModelIds(Iterable<WorkspaceModelSelectionToCreate> models) =>
      {for (final model in models) model.modelId};

  Set<String> _removedSelectionIds(
    Iterable<WorkspaceModelSelectionTable> selections,
    Set<String> nextModelIds,
  ) => {
    for (final selection in selections)
      if (!nextModelIds.contains(selection.modelId)) selection.id,
  };

  List<WorkspaceModelSelectionsCompanion> _newWorkspaceModelSelections(
    String modelConnectionId,
    Iterable<WorkspaceModelSelectionToCreate> models,
    Set<String> existingModelIds,
  ) => models
      .where((model) => !existingModelIds.contains(model.modelId))
      .map((model) => model.copyWith(modelConnectionId: modelConnectionId))
      .map(_workspaceModelSelectionToCreateToCompanion)
      .toList();
}

extension ModelConnectionMapping on ModelConnectionRepository {
  ModelConnectionForEdit _modelConnectionForEdit(
    ServiceConnectionTable modelConnection,
  ) {
    final connection = _modelConnectionForEditBase(modelConnection);

    return connection.copyWith(
      authMode: _authMode(modelConnection.authenticationType),
      url: modelConnection.url,
      keySuffix: modelConnection.keySuffix,
    );
  }

  ModelConnectionForEdit _modelConnectionForEditBase(
    ServiceConnectionTable modelConnection,
  ) => ModelConnectionForEdit(
    id: modelConnection.id,
    name: modelConnection.name,
    modelId: modelConnection.serviceId,
    workspaceId: modelConnection.workspaceId,
    hasKey: modelConnection.encryptedAuthValue?.isNotEmpty == true,
  );

  String? _nextConnectionUrl(String? url) {
    final updatedUrl = url?.trim();

    return updatedUrl?.isEmpty == true ? null : updatedUrl;
  }

  ServiceConnectionsCompanion _modelProviderToCreateToCompanion(
    ModelConnectionToCreate modelConnection,
    String encryptedApiKey,
    String keySuffix,
  ) => _modelProviderBaseCompanion(modelConnection).copyWith(
    url: .absentIfNull(modelConnection.url),
    encryptedAuthValue: .new(encryptedApiKey),
    keySuffix: .new(keySuffix),
  );

  ServiceConnectionsCompanion _modelProviderBaseCompanion(
    ModelConnectionToCreate modelConnection,
  ) => ServiceConnectionsCompanion(
    name: .new(modelConnection.name),
    serviceId: .new(modelConnection.modelId),
    kind: const Value(ServiceConnectionKindTable.modelProvider),
    authenticationType: const Value(ServiceAuthenticationTypeTable.apiKey),
    workspaceId: .new(modelConnection.workspaceId),
  );

  String _keySuffix(String key) {
    const keySuffixLength = 6;

    return key.lastCharacters(keySuffixLength);
  }

  String _decodeApiKey(String decrypted) {
    ServiceConnectionSecret secret;
    try {
      secret = ServiceConnectionAuthCodec.decodeSecret(decrypted);
    } on FormatException {
      return decrypted;
    }

    if (secret is ServiceConnectionSecretApiKey) {
      return secret.apiKey;
    }

    throw const ModelConnectionException('Invalid model API key payload');
  }
}

extension ModelConnectionEntityMapping on ModelConnectionRepository {
  ModelConnectionEntity _modelProviderTableToEntity(
    ServiceConnectionTable modelConnection,
  ) {
    final connection = _modelConnectionEntityBase(modelConnection);

    return connection.copyWith(
      authMode: _authMode(modelConnection.authenticationType),
      url: modelConnection.url,
      keySuffix: modelConnection.keySuffix,
    );
  }

  ModelConnectionEntity _modelConnectionEntityBase(
    ServiceConnectionTable modelConnection,
  ) => ModelConnectionEntity(
    id: modelConnection.id,
    name: modelConnection.name,
    modelId: modelConnection.serviceId,
    createdAt: modelConnection.createdAt,
    updatedAt: modelConnection.updatedAt,
    workspaceId: modelConnection.workspaceId,
    hasKey: modelConnection.encryptedAuthValue?.isNotEmpty == true,
  );

  DateTime? _expiresAt(OAuthTokenEntity token) {
    final expiresIn = token.expiresIn;
    if (expiresIn == null) return null;

    return token.issuedAt.add(.new(seconds: expiresIn));
  }

  ModelProviderAuthMode _authMode(ServiceAuthenticationTypeTable type) {
    return switch (type) {
      .oauth2 => ModelProviderAuthMode.oauth2,
      _ => ModelProviderAuthMode.apiKey,
    };
  }

  WorkspaceModelSelectionsCompanion _workspaceModelSelectionToCreateToCompanion(
    WorkspaceModelSelectionToCreate workspaceModelSelection,
  ) {
    return WorkspaceModelSelectionsCompanion(
      modelId: .new(workspaceModelSelection.modelId),
      modelConnectionId: .new(workspaceModelSelection.modelConnectionId),
    );
  }
}

/// Base exception for model connection-related operations.
class ModelConnectionException implements Exception {
  /// Creates a new ModelConnectionException.
  const new(this.message, [this.cause]);

  /// Error message describing the exception.
  final String message;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: ${cause.runtimeType})' : '';

    return 'ModelConnectionException: $message$causedBy';
  }
}

/// Exception thrown when a model connection has no models.
class ModelConnectionNoModelsException extends ModelConnectionException {
  /// Creates a new ModelConnectionNoModelsException.
  const new(this.modelId, [Exception? cause])
    : super('ModelProvider with type "$modelId" not found models', cause);

  /// ID of the workspaceModelSelection that was not found.
  final String modelId;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: ${cause.runtimeType})' : '';

    return 'ModelConnectionException: $message$causedBy';
  }
}

class const ModelConnectionModelNotFoundException(
  final String modelId, [
  Exception? cause,
]) extends ModelConnectionException {
  this : super('ModelProvider with id "$modelId" not found', cause);
}

class const ModelConnectionNoTypeException(
  final String modelId, [
  Exception? cause,
]) extends ModelConnectionException {
  this : super('ModelProvider with id "$modelId" has no type', cause);
}
