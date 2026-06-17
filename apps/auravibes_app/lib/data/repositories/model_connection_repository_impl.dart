// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
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
    if (modelConnection.authMode == ModelProviderAuthMode.oauth2) {
      return _createOAuthModelConnection(modelConnection);
    }

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
    final key = modelConnection.key;
    if (key.trim().isEmpty) {
      throw const ModelConnectionException('Model connection has no API key');
    }

    // Extract last 6 characters for display.
    final keySuffix = key.lastCharacters(6);

    final encryptedApiKey = await _encryptionService.encrypt(
      ServiceConnectionAuthCodec.encodeSecret(
        ServiceConnectionSecretApiKey(apiKey: key),
      ),
    );

    // Validate API key with model provider.
    final models = await _modelProviderServices.getWorkspaceModelSelections(
      ModelProvider(
        type: .fromString(modelType.value),
        key: key,
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

  Future<ModelConnectionEntity> _createOAuthModelConnection(
    ModelConnectionToCreate modelConnection,
  ) async {
    final token = modelConnection.oauthToken;
    final metadata = modelConnection.oauthMetadata;
    if (token == null || metadata == null) {
      throw const ModelConnectionException('OAuth token is required');
    }

    if (!isOpenAICodexProvider(modelConnection.modelId)) {
      throw ModelConnectionException(
        'OAuth profile not found: ${modelConnection.modelId}',
      );
    }
    final encryptedToken = await _encryptionService.encrypt(
      ServiceConnectionAuthCodec.encodeSecret(
        ServiceConnectionSecretOAuth2(
          accessToken: token.accessToken,
          refreshToken: token.refreshToken,
          idToken: token.idToken,
        ),
      ),
    );
    final modelIds = modelConnection.modelIds;
    if (modelIds.isEmpty) {
      throw const ModelConnectionException(
        'OpenAI model catalog is unavailable. Retry after model sync.',
      );
    }

    final createdModelConnection = await _database.transaction(() async {
      final created = await _database.modelConnectionsDao.insertModelConnection(
        ServiceConnectionsCompanion.insert(
          name: modelConnection.name,
          serviceId: modelConnection.modelId,
          kind: ServiceConnectionKindTable.modelProvider,
          authenticationType: ServiceAuthenticationTypeTable.oauth2,
          url: .absentIfNull(modelConnection.url),
          encryptedAuthValue: Value(encryptedToken),
          keySuffix: Value(_keySuffix(token.accessToken)),
          metadataJson: Value(
            ServiceConnectionAuthCodec.encodeMetadata(metadata),
          ),
          authStatus: const Value(ServiceConnectionAuthStatus.connected),
          expiresAt: Value(_expiresAt(token)),
          lastRefreshedAt: Value(token.issuedAt),
          workspaceId: modelConnection.workspaceId,
        ),
      );

      await _database.workspaceModelSelectionsDao
          .insertWorkspaceModelSelections(
            modelIds
                .map(
                  (modelId) => WorkspaceModelSelectionsCompanion(
                    modelId: Value(modelId),
                    modelConnectionId: Value(created.id),
                  ),
                )
                .toList(),
          );

      return created;
    });

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
      authMode: _authMode(modelConnection.authenticationType),
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
    if (existing.authenticationType == ServiceAuthenticationTypeTable.oauth2) {
      throw const ModelConnectionException(
        'OAuth model connections must be reconnected instead of edited.',
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
        _decodeApiKey(
          await _encryptionService.decrypt(
            existingEncryptedKey ??
                (throw const ModelConnectionException(
                  'Model connection has no API key',
                )),
          ),
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
        : await _encryptionService.encrypt(
            ServiceConnectionAuthCodec.encodeSecret(
              ServiceConnectionSecretApiKey(apiKey: key),
            ),
          );
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
    return key.lastCharacters(6);
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
      authMode: _authMode(modelConnection.authenticationType),
      url: modelConnection.url,
      keySuffix: modelConnection.keySuffix,
    );
  }

  DateTime? _expiresAt(OAuthTokenEntity token) {
    final expiresIn = token.expiresIn;
    if (expiresIn == null) return null;

    return token.issuedAt.add(Duration(seconds: expiresIn));
  }

  ModelProviderAuthMode _authMode(ServiceAuthenticationTypeTable type) {
    return switch (type) {
      ServiceAuthenticationTypeTable.oauth2 => ModelProviderAuthMode.oauth2,
      _ => ModelProviderAuthMode.apiKey,
    };
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
    // Verify the model connection exists before attempting deletion.
    final modelConnection = await _database.modelConnectionsDao
        .getModelConnectionById(
          modelConnectionId,
        );
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
