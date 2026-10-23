import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/legacy_api_key_storage.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:drift/drift.dart';
import 'package:easy_localization/easy_localization.dart';

typedef ConnectorConnectionUpdateRequest = ({
  String id,
  String workspaceId,
  String name,
  bool clearSecret,
  String? secret,
});

typedef ConnectorConnectionCreateRequest = ({
  String workspaceId,
  String connectorId,
  String name,
  String apiKey,
});

typedef ConnectorConnectionCandidatesRequest = ({
  String workspaceId,
  String connectorId,
  List<String> compatibleModelProviderIds,
});

typedef _McpBearerRequest = ({
  ServiceConnectionRepository repository,
  String workspaceId,
  String name,
  String serviceId,
  ServiceConnectionKindTable kind,
  String bearerToken,
});

typedef _McpOAuthRequest = ({
  ServiceConnectionRepository repository,
  String workspaceId,
  String name,
  String serviceId,
  ServiceConnectionKindTable kind,
  McpAuthenticationTypeOAuth authenticationType,
  OAuthTokenEntity token,
});

typedef _McpBearerProfileRequest = ({
  ServiceConnectionRepository repository,
  String workspaceId,
  McpServiceConnectionProfile profile,
  String bearerToken,
});

typedef _McpOAuthProfileRequest = ({
  ServiceConnectionRepository repository,
  String workspaceId,
  McpServiceConnectionProfile profile,
  McpAuthenticationTypeOAuth authenticationType,
});

typedef _McpAuthenticationRequest = ({
  ServiceConnectionRepository repository,
  String workspaceId,
  McpServiceConnectionProfile profile,
  McpAuthenticationType authentication,
});

typedef _ConnectionInsertRequest = ({
  String name,
  String serviceId,
  ServiceConnectionKindTable kind,
  ServiceAuthenticationTypeTable authenticationType,
  String workspaceId,
});

class ServiceConnectionRepository(
  final AppDatabase _database,
  final EncryptionService _encryptionService, [
  LegacyApiKeyStorage? legacyApiKeyStorage,
]) with _ServiceConnectionRepositoryQueries {
  final LegacyApiKeyStorage _legacyApiKeyStorage =
      legacyApiKeyStorage ?? LegacyApiKeyStorage();

  Future<GenericServiceConnectionRecord?> getConnectorConnectionForEdit(
    String id, {
    required String workspaceId,
  }) => _getConnectorConnectionForEdit(this, id, workspaceId: workspaceId);

  Future<void> updateConnectorConnection(
    ConnectorConnectionUpdateRequest request,
  ) => _updateConnectorConnection(this, request);

  Future<List<ServiceConnectionCandidate>> listConnectorConnectionCandidates(
    ConnectorConnectionCandidatesRequest request,
  ) => _listConnectorConnectionCandidates(this, request);

  Future<ServiceConnectionEntity> createConnectorConnection(
    ConnectorConnectionCreateRequest request,
  ) => _createConnectorConnection(this, request);

  Future<void> deleteConnectorConnection(
    String id, {
    required String workspaceId,
  }) => _deleteConnectorConnection(this, id, workspaceId: workspaceId);

  Future<ServiceConnectionSecret> readSecret(String id) =>
      _readSecret(this, id);

  Future<String?> createMcpServiceConnection({
    required String workspaceId,
    required McpServiceConnectionProfile profile,
  }) => _createMcpServiceConnection(this, workspaceId, profile);

  Future<String?> updateMcpAuthentication({
    required String? connectionId,
    required String workspaceId,
    required String name,
    required McpAuthenticationType authenticationType,
  }) => _updateMcpAuthentication(this, (
    connectionId: connectionId,
    workspaceId: workspaceId,
    name: name,
    authenticationType: authenticationType,
  ));

  Future<void> updateOAuthToken({
    required String id,
    required OAuthTokenEntity token,
  }) => _updateOAuthToken(this, id: id, token: token);

  Future<void> deleteOwnedMcpCredential(String id) =>
      _deleteOwnedMcpCredential(this, id);
}

mixin _ServiceConnectionRepositoryQueries {
  Future<ServiceConnectionEntity?> getById(String id) =>
      ServiceConnectionRepositoryQueries(this as ServiceConnectionRepository)
          .getById(id);

  Stream<List<ServiceConnectionEntity>> watchWorkspaceConnections(
    String workspaceId,
  ) =>
      ServiceConnectionRepositoryQueries(this as ServiceConnectionRepository)
          .watchWorkspaceConnections(workspaceId);

  Future<void> markReauthRequired(String id, {String? error}) =>
      ServiceConnectionRepositoryQueries(this as ServiceConnectionRepository)
          .markReauthRequired(id, error: error);
}

extension ServiceConnectionRepositoryQueries on ServiceConnectionRepository {
  Future<ServiceConnectionEntity?> getById(String id) => _getById(this, id);

  Stream<List<ServiceConnectionEntity>> watchWorkspaceConnections(
    String workspaceId,
  ) => _watchWorkspaceConnections(this, workspaceId);

  Future<void> markReauthRequired(String id, {String? error}) =>
      _markReauthRequired(this, id, error: error);
}

Stream<List<ServiceConnectionEntity>> _watchWorkspaceConnections(
  ServiceConnectionRepository repository,
  String workspaceId,
) {
  final database = repository._database;
  final query = database.select(database.serviceConnections);
  final _ = query.where((table) => table.workspaceId.equals(workspaceId));

  return _watchConnectionRows(query);
}

Stream<List<ServiceConnectionEntity>> _watchConnectionRows(
  Selectable<ServiceConnectionTable> query,
) => query.watch().map((rows) => rows.map(_toEntity).toList());

Future<ServiceConnectionEntity?> _getById(
  ServiceConnectionRepository repository,
  String id,
) async {
  final row = await _getRowById(repository, id);

  return row == null ? null : _toEntity(row);
}

Future<GenericServiceConnectionRecord?> _getConnectorConnectionForEdit(
  ServiceConnectionRepository repository,
  String id, {
  required String workspaceId,
}) async {
  final row = await _getRowById(repository, id);
  if (row == null || !_isConnectorConnection(row, workspaceId)) return null;

  return _genericServiceConnectionRecord(row);
}

GenericServiceConnectionRecord _genericServiceConnectionRecord(
  ServiceConnectionTable row,
) => GenericServiceConnectionRecord(
  id: row.id,
  name: row.name,
  serviceId: row.serviceId,
  hasSecret: row.encryptedAuthValue != null,
  keySuffix: row.keySuffix,
);

bool _isConnectorConnection(ServiceConnectionTable row, String workspaceId) =>
    row.workspaceId == workspaceId &&
    row.kind == ServiceConnectionKindTable.customHttp;

Future<void> _updateConnectorConnection(
  ServiceConnectionRepository repository,
  ConnectorConnectionUpdateRequest request,
) async {
  final existing = await _getRowById(repository, request.id);
  final companion = await _connectorConnectionUpdateCompanion(
    repository,
    request,
  );
  final update = _connectorUpdateStatement(repository, request);
  await _persistCredentialChange(
    _credentialChange(repository, existing?.encryptedAuthValue, companion),
    () => update.write(companion),
  );
}

Expression<bool> _connectorConnectionUpdateFilter(
  ServiceConnections table,
  ConnectorConnectionUpdateRequest request,
) => _connectorConnectionFilter(
  table,
  id: request.id,
  workspaceId: request.workspaceId,
);

Expression<bool> _connectorConnectionFilter(
  ServiceConnections table, {
  required String id,
  required String workspaceId,
}) =>
    table.id.equals(id) &
    table.workspaceId.equals(workspaceId) &
    table.kind.equals(ServiceConnectionKindTable.customHttp.name);

Future<ServiceConnectionsCompanion> _connectorConnectionUpdateCompanion(
  ServiceConnectionRepository repository,
  ConnectorConnectionUpdateRequest request,
) async {
  if (request.clearSecret) return _clearedSecretCompanion(request.name);

  final secret = request.secret;
  if (secret == null) {
    return ServiceConnectionsCompanion(name: .new(request.name));
  }

  return await _replacedSecretCompanion(repository, request.name, secret);
}

Future<ServiceConnectionsCompanion> _replacedSecretCompanion(
  ServiceConnectionRepository repository,
  String name,
  String secret,
) async {
  final encrypted = await _encryptedSecret(
    repository,
    ServiceConnectionSecretApiKey(apiKey: secret),
  );

  return ServiceConnectionsCompanion(
    name: .new(name),
    encryptedAuthValue: .new(encrypted),
    keySuffix: .new(_suffix(secret)),
  );
}

ServiceConnectionsCompanion _clearedSecretCompanion(String name) => .new(
  name: .new(name),
  encryptedAuthValue: const Value(null),
  keySuffix: const Value(null),
);

Future<List<ServiceConnectionCandidate>> _listConnectorConnectionCandidates(
  ServiceConnectionRepository repository,
  ConnectorConnectionCandidatesRequest request,
) async {
  final rows = await _candidateRows(repository, request);

  return rows.map(_candidate).toList(growable: false);
}

Future<List<ServiceConnectionTable>> _candidateRows(
  ServiceConnectionRepository repository,
  ConnectorConnectionCandidatesRequest request,
) {
  final query = repository._database.select(
    repository._database.serviceConnections,
  );
  final _ = query.where((table) => _candidateFilter(table, request));

  return query.get();
}

Expression<bool> _candidateFilter(
  ServiceConnections table,
  ConnectorConnectionCandidatesRequest request,
) {
  final compatibleProviders = request.compatibleModelProviderIds.toSet();

  return table.workspaceId.equals(request.workspaceId) &
      table.isEnabled.equals(true) &
      table.encryptedAuthValue.isNotNull() &
      (_connectorCandidateFilter(table, request) |
          _modelProviderCandidateFilter(table, compatibleProviders));
}

Expression<bool> _connectorCandidateFilter(
  ServiceConnections table,
  ConnectorConnectionCandidatesRequest request,
) =>
    table.kind.equals(ServiceConnectionKindTable.customHttp.name) &
    table.serviceId.equals(request.connectorId);

Expression<bool> _modelProviderCandidateFilter(
  ServiceConnections table,
  Set<String> compatibleProviders,
) => compatibleProviders.isEmpty
    ? const Constant(false)
    : table.kind.equals(ServiceConnectionKindTable.modelProvider.name) &
          table.serviceId.isIn(compatibleProviders);

ServiceConnectionCandidate _candidate(ServiceConnectionTable row) =>
    ServiceConnectionCandidate(
      id: row.id,
      name: _candidateName(row),
      serviceId: row.serviceId,
      kind: row.kind,
    );

Future<ServiceConnectionEntity> _createConnectorConnection(
  ServiceConnectionRepository repository,
  ConnectorConnectionCreateRequest request,
) async {
  final encrypted = await _encryptedApiKey(repository, request.apiKey);
  final companion = _connectorConnectionCompanion(request, encrypted);
  final row = await _insertConnection(repository, companion);

  return _toEntity(row);
}

ServiceConnectionsCompanion _connectorConnectionCompanion(
  ConnectorConnectionCreateRequest request,
  String encrypted,
) =>
    _baseConnectionCompanion((
      name: request.name,
      serviceId: request.connectorId,
      kind: .customHttp,
      authenticationType: .apiKey,
      workspaceId: request.workspaceId,
    )).copyWith(
      encryptedAuthValue: .new(encrypted),
      keySuffix: .new(_suffix(request.apiKey)),
    );

Future<ServiceConnectionSecret> _readSecret(
  ServiceConnectionRepository repository,
  String id,
) async {
  final row = await _requiredRowById(repository, id);
  final encrypted = row.encryptedAuthValue;
  if (encrypted == null || encrypted.isEmpty) {
    throw const FormatException('Service connection has no secret payload.');
  }

  final value = await _readEncryptedOrLegacySecret(repository, row, encrypted);

  return _decodeStoredSecret(row, value);
}

Future<String> _readEncryptedOrLegacySecret(
  ServiceConnectionRepository repository,
  ServiceConnectionTable row,
  String storedValue,
) async {
  final legacyStorage = repository._legacyApiKeyStorage;
  if (!legacyStorage.isLegacyReference(storedValue)) {
    return await _readPlatformOrEncryptedSecret(
      repository,
      row.id,
      storedValue,
    );
  }

  return await _migrateLegacyApiKey(repository, row.id, storedValue);
}

Future<String> _migrateLegacyApiKey(
  ServiceConnectionRepository repository,
  String rowId,
  String storedValue,
) async {
  final legacyStorage = repository._legacyApiKeyStorage;
  final apiKey = await legacyStorage.read(storedValue);
  if (apiKey == null) {
    return await _missingLegacySecret(repository, rowId, storedValue);
  }
  final migrated = await _migrateCredentialPayload(
    _legacyCredentialMigration(repository, rowId, (
      storedValue: storedValue,
      apiKey: apiKey,
    )),
  );
  if (migrated.changed) await legacyStorage.delete(storedValue);

  return migrated.value;
}

Future<String> _readPlatformOrEncryptedSecret(
  ServiceConnectionRepository repository,
  String rowId,
  String storedValue,
) async {
  final service = repository._encryptionService;
  final value = await service.readCredential(storedValue);
  if (service.isCredentialReference(storedValue)) return value;

  return (await _migrateCredentialPayload((
    repository: repository,
    rowId: rowId,
    expectedValue: storedValue,
    value: value,
    keySuffix: const Value.absent(),
  ))).value;
}

typedef _CredentialMigration = ({
  ServiceConnectionRepository repository,
  String rowId,
  String expectedValue,
  String value,
  Value<String?> keySuffix,
});

Future<({String value, bool changed})> _migrateCredentialPayload(
  _CredentialMigration request,
) async {
  final service = request.repository._encryptionService;
  final reference = await service.storeCredential(request.value);
  final changed = await _replaceCredentialPayload(request, reference);
  if (changed > 0) return (value: request.value, changed: true);
  await service.deleteCredential(reference);

  return (
    value: await _currentSecretPayload(request.repository, request.rowId),
    changed: false,
  );
}

Future<int> _replaceCredentialPayload(
  _CredentialMigration request,
  String reference,
) async {
  try {
    return await _credentialMigrationUpdate(request).write(
      ServiceConnectionsCompanion(
        encryptedAuthValue: .new(reference),
        keySuffix: request.keySuffix,
      ),
    );
  } on Object {
    await request.repository._encryptionService.deleteCredential(reference);
    rethrow;
  }
}

UpdateStatement<$ServiceConnectionsTable, ServiceConnectionTable>
_credentialMigrationUpdate(_CredentialMigration request) =>
    request.repository._database.update(
      request.repository._database.serviceConnections,
    )..where(
      (table) =>
          table.id.equals(request.rowId) &
          table.encryptedAuthValue.equals(request.expectedValue),
    );
Future<String> _currentSecretPayload(
  ServiceConnectionRepository repository,
  String rowId,
) async => ServiceConnectionAuthCodec.encodeSecret(
  await _readSecret(repository, rowId),
);

Future<String?> _createMcpServiceConnection(
  ServiceConnectionRepository repository,
  String workspaceId,
  McpServiceConnectionProfile profile,
) => _createMcpAuthentication((
  repository: repository,
  workspaceId: workspaceId,
  profile: profile,
  authentication: profile.authenticationType,
));

Future<String?> _createMcpAuthentication(_McpAuthenticationRequest request) {
  return switch (request.authentication) {
    McpAuthenticationTypeNone() => Future.value(),
    McpAuthenticationTypeBearerToken(:final bearerToken) =>
      _createBearerForAuthentication(request, bearerToken),
    McpAuthenticationTypeHttpHeaders(:final headers) =>
      _createHeadersForAuthentication(request, headers),
    final McpAuthenticationTypeOAuth authenticationType =>
      _createOAuthForAuthentication(request, authenticationType),
  };
}

Future<String> _createHeadersForAuthentication(
  _McpAuthenticationRequest request,
  Map<String, String> headers,
) async {
  final repository = request.repository;
  final encrypted = await _encryptedSecret(
    repository,
    ServiceConnectionSecretHttpHeaders(headers: headers),
  );
  final row = await _insertConnection(
    repository,
    _headersAuthenticationCompanion(request, encrypted),
  );

  return row.id;
}

ServiceConnectionsCompanion _headersAuthenticationCompanion(
  _McpAuthenticationRequest request,
  String encrypted,
) => _baseConnectionCompanion((
  name: request.profile.name,
  serviceId: request.profile.serviceId(),
  kind: .mcpServer,
  authenticationType: .apiKey,
  workspaceId: request.workspaceId,
)).copyWith(encryptedAuthValue: .new(encrypted));

Future<String> _createBearerForAuthentication(
  _McpAuthenticationRequest request,
  String bearerToken,
) => _createBearerForProfile((
  repository: request.repository,
  workspaceId: request.workspaceId,
  profile: request.profile,
  bearerToken: bearerToken,
));

Future<String> _createOAuthForAuthentication(
  _McpAuthenticationRequest request,
  McpAuthenticationTypeOAuth authenticationType,
) => _createOAuthForProfile((
  repository: request.repository,
  workspaceId: request.workspaceId,
  profile: request.profile,
  authenticationType: authenticationType,
));

Future<String> _createBearerForProfile(_McpBearerProfileRequest request) =>
    _createBearer((
      repository: request.repository,
      workspaceId: request.workspaceId,
      name: request.profile.name,
      serviceId: request.profile.serviceId(),
      kind: .mcpServer,
      bearerToken: request.bearerToken,
    ));

Future<String> _createOAuthForProfile(_McpOAuthProfileRequest request) =>
    _createOAuth((
      repository: request.repository,
      workspaceId: request.workspaceId,
      name: request.profile.name,
      serviceId: request.profile.serviceId(),
      kind: .mcpServer,
      authenticationType: request.authenticationType,
      token: request.authenticationType.token,
    ));

Future<String> _createBearer(_McpBearerRequest request) async {
  final encrypted = await _encryptedSecret(
    request.repository,
    ServiceConnectionSecretBearerToken(bearerToken: request.bearerToken),
  );
  final companion = _bearerCompanion(request, encrypted);
  final row = await _insertConnection(request.repository, companion);

  return row.id;
}

ServiceConnectionsCompanion _bearerCompanion(
  _McpBearerRequest request,
  String encrypted,
) =>
    _baseConnectionCompanion((
      name: request.name,
      serviceId: request.serviceId,
      kind: request.kind,
      authenticationType: .bearerToken,
      workspaceId: request.workspaceId,
    )).copyWith(
      encryptedAuthValue: .new(encrypted),
      keySuffix: .new(_suffix(request.bearerToken)),
    );

Future<String> _createOAuth(_McpOAuthRequest request) async {
  final repository = request.repository;
  final token = request.token;
  final encrypted = await _encryptedSecret(repository, _oauthSecret(token));
  final companion = _oauthCompanion(request, encrypted);
  final row = await _insertConnection(repository, companion);

  return row.id;
}

ServiceConnectionMetadata _oauthMetadata(_McpOAuthRequest request) =>
    _oauthMetadataFromValues(request.authenticationType, request.token.scopes);

ServiceConnectionMetadata _oauthMetadataFromValues(
  McpAuthenticationTypeOAuth authenticationType,
  List<String>? scopes,
) => ServiceConnectionMetadata(
  clientId: authenticationType.clientId,
  issuer: authenticationType.issuer,
  resource: authenticationType.resource,
  authorizationEndpoint: authenticationType.authorizationEndpoint,
  tokenEndpoint: authenticationType.tokenEndpoint,
  scopes: scopes ?? const [],
  provider: 'mcp',
);

ServiceConnectionSecretOAuth2 _oauthSecret(OAuthTokenEntity token) =>
    ServiceConnectionSecretOAuth2(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      idToken: token.idToken,
    );

ServiceConnectionsCompanion _oauthCompanion(
  _McpOAuthRequest request,
  String encrypted,
) {
  final credential = _oauthCredentialCompanion(
    _oauthBaseCompanion(request),
    request.token,
    encrypted,
  );

  return _oauthMetadataCompanion(
    credential,
    _oauthMetadata(request),
    request.token,
  );
}

ServiceConnectionsCompanion _oauthBaseCompanion(_McpOAuthRequest request) =>
    _baseConnectionCompanion((
      name: request.name,
      serviceId: request.serviceId,
      kind: request.kind,
      authenticationType: .oauth2,
      workspaceId: request.workspaceId,
    ));

ServiceConnectionsCompanion _oauthMetadataCompanion(
  ServiceConnectionsCompanion credential,
  ServiceConnectionMetadata metadata,
  OAuthTokenEntity token,
) => credential.copyWith(
  metadataJson: .new(ServiceConnectionAuthCodec.encodeMetadata(metadata)),
  expiresAt: .new(_expiresAt(token)),
  lastRefreshedAt: .new(token.issuedAt),
);

ServiceConnectionsCompanion _oauthCredentialCompanion(
  ServiceConnectionsCompanion base,
  OAuthTokenEntity token,
  String encrypted,
) => base.copyWith(
  encryptedAuthValue: .new(encrypted),
  keySuffix: .new(_suffix(token.accessToken)),
);

Future<void> _updateOAuthToken(
  ServiceConnectionRepository repository, {
  required String id,
  required OAuthTokenEntity token,
}) async {
  final companion = await _oauthTokenCompanion(repository, id, token);
  await _writeConnectionUpdate(repository, id, companion);
}

Future<ServiceConnectionsCompanion> _oauthTokenCompanion(
  ServiceConnectionRepository repository,
  String id,
  OAuthTokenEntity token,
) async {
  final existingSecret = await repository.readSecret(id);
  final existingOAuth = _oauthSecretOrNull(existingSecret);
  final secret = _updatedOAuthSecret(token, existingOAuth);
  final encrypted = await _encryptedSecret(repository, secret);

  return _oauthUpdateCompanion(token, encrypted);
}

ServiceConnectionSecretOAuth2? _oauthSecretOrNull(
  ServiceConnectionSecret secret,
) => secret is ServiceConnectionSecretOAuth2 ? secret : null;

ServiceConnectionSecretOAuth2 _updatedOAuthSecret(
  OAuthTokenEntity token,
  ServiceConnectionSecretOAuth2? existingOAuth,
) => ServiceConnectionSecretOAuth2(
  accessToken: token.accessToken,
  refreshToken: token.refreshToken ?? existingOAuth?.refreshToken,
  idToken: token.idToken ?? existingOAuth?.idToken,
  clientSecret: existingOAuth?.clientSecret,
);

ServiceConnectionsCompanion _oauthUpdateCompanion(
  OAuthTokenEntity token,
  String encrypted,
) => ServiceConnectionsCompanion(
  encryptedAuthValue: .new(encrypted),
  keySuffix: .new(_suffix(token.accessToken)),
  authStatus: const Value(ServiceConnectionAuthStatus.connected),
  expiresAt: .new(_expiresAt(token)),
  lastRefreshedAt: .new(token.issuedAt),
  lastAuthError: const Value(null),
);

Future<void> _markReauthRequired(
  ServiceConnectionRepository repository,
  String id, {
  String? error,
}) async {
  await _writeConnectionUpdate(
    repository,
    id,
    .new(
      authStatus: const Value(ServiceConnectionAuthStatus.needsReauth),
      lastAuthError: .new(error),
    ),
  );
}

Future<void> _deleteOwnedMcpCredential(
  ServiceConnectionRepository repository,
  String id,
) async {
  final existing = await _getRowById(repository, id);
  final changed = await _deleteMcpCredentialRow(repository, id);
  if (changed > 0) {
    await repository._encryptionService.deleteCredential(
      existing?.encryptedAuthValue,
    );
  }
}

typedef _McpAuthenticationUpdateRequest = ({
  String? connectionId,
  String workspaceId,
  String name,
  McpAuthenticationType authenticationType,
});

typedef _McpCredentialUpdate = ({
  ServiceConnectionSecret secret,
  String? suffix,
  ServiceAuthenticationTypeTable authenticationType,
});

Future<String?> _updateMcpAuthentication(
  ServiceConnectionRepository repository,
  _McpAuthenticationUpdateRequest request,
) async {
  final connection = await _ownedMcpConnection(repository, request);
  if (request.authenticationType is McpAuthenticationTypeNone) {
    return await _removeMcpCredential(repository, request.connectionId);
  }
  if (request.authenticationType is McpAuthenticationTypeOAuth) {
    throw StateError('OAuth credentials must use the reconnect flow.');
  }
  if (connection == null) {
    return await _createMcpCredential(repository, request);
  }

  return await _replaceMcpCredential(repository, connection, request);
}

Future<ServiceConnectionTable?> _ownedMcpConnection(
  ServiceConnectionRepository repository,
  _McpAuthenticationUpdateRequest request,
) async {
  final connectionId = request.connectionId;
  if (connectionId == null) return null;
  final connection = await _getRowById(repository, connectionId);
  if (connection == null ||
      connection.workspaceId != request.workspaceId ||
      connection.kind != ServiceConnectionKindTable.mcpServer) {
    throw StateError('MCP credential not found.');
  }

  return connection;
}

Future<String?> _removeMcpCredential(
  ServiceConnectionRepository repository,
  String? connectionId,
) async {
  if (connectionId != null) {
    await _deleteOwnedMcpCredential(repository, connectionId);
  }

  return null;
}

Future<String?> _createMcpCredential(
  ServiceConnectionRepository repository,
  _McpAuthenticationUpdateRequest request,
) => repository.createMcpServiceConnection(
  workspaceId: request.workspaceId,
  profile: .new(
    name: request.name,
    authenticationType: request.authenticationType,
  ),
);

Future<String> _replaceMcpCredential(
  ServiceConnectionRepository repository,
  ServiceConnectionTable connection,
  _McpAuthenticationUpdateRequest request,
) async {
  final update = _mcpCredentialUpdate(request.authenticationType);
  final encrypted = await _encryptedSecret(repository, update.secret);
  final _ = await _writeConnectionUpdate(
    repository,
    connection.id,
    _mcpCredentialCompanion(request, update, encrypted),
  );

  return connection.id;
}

ServiceConnectionsCompanion _mcpCredentialCompanion(
  _McpAuthenticationUpdateRequest request,
  _McpCredentialUpdate update,
  String encrypted,
) => _mcpCredentialValuesCompanion(
  _mcpCredentialBaseCompanion(request, update),
  update,
  encrypted,
);

ServiceConnectionsCompanion _mcpCredentialBaseCompanion(
  _McpAuthenticationUpdateRequest request,
  _McpCredentialUpdate update,
) => _baseConnectionCompanion((
  name: request.name,
  serviceId: 'mcp:${request.name}',
  kind: .mcpServer,
  authenticationType: update.authenticationType,
  workspaceId: request.workspaceId,
));

ServiceConnectionsCompanion _mcpCredentialValuesCompanion(
  ServiceConnectionsCompanion base,
  _McpCredentialUpdate update,
  String encrypted,
) => base.copyWith(
  encryptedAuthValue: .new(encrypted),
  keySuffix: .new(update.suffix),
  metadataJson: const Value(null),
  authStatus: const Value(ServiceConnectionAuthStatus.connected),
  expiresAt: const Value(null),
  lastRefreshedAt: const Value(null),
  lastAuthError: const Value(null),
);

_McpCredentialUpdate _mcpCredentialUpdate(
  McpAuthenticationType authenticationType,
) => switch (authenticationType) {
  McpAuthenticationTypeBearerToken(:final bearerToken) => (
    secret: ServiceConnectionSecretBearerToken(bearerToken: bearerToken),
    suffix: _suffix(bearerToken),
    authenticationType: ServiceAuthenticationTypeTable.bearerToken,
  ),
  McpAuthenticationTypeHttpHeaders(:final headers) => (
    secret: ServiceConnectionSecretHttpHeaders(headers: headers),
    suffix: null,
    authenticationType: ServiceAuthenticationTypeTable.apiKey,
  ),
  McpAuthenticationTypeNone() || McpAuthenticationTypeOAuth() =>
    throw StateError('Unsupported MCP authentication update.'),
};

Future<void> _deleteConnectorConnection(
  ServiceConnectionRepository repository,
  String id, {
  required String workspaceId,
}) async {
  final existing = await _getRowById(repository, id);
  final changed = await _deleteConnectorRow(repository, id, workspaceId);
  if (changed > 0) {
    await repository._encryptionService.deleteCredential(
      existing?.encryptedAuthValue,
    );
  }
}

Expression<bool> _ownedMcpCredentialFilter(
  ServiceConnections table,
  String id,
) =>
    table.id.equals(id) &
    table.kind.equals(ServiceConnectionKindTable.mcpServer.name);

Future<void> _writeConnectionUpdate(
  ServiceConnectionRepository repository,
  String id,
  ServiceConnectionsCompanion companion,
) async {
  final existing = await _getRowById(repository, id);
  final update = _connectionUpdateStatement(repository, id);
  await _persistCredentialChange(
    _credentialChange(repository, existing?.encryptedAuthValue, companion),
    () => update.write(companion),
  );
}

Future<String> _encryptedApiKey(
  ServiceConnectionRepository repository,
  String apiKey,
) =>
    _encryptedSecret(repository, ServiceConnectionSecretApiKey(apiKey: apiKey));

Future<String> _encryptedSecret(
  ServiceConnectionRepository repository,
  ServiceConnectionSecret secret,
) {
  final encoded = ServiceConnectionAuthCodec.encodeSecret(secret);

  return repository._encryptionService.storeCredential(encoded);
}

Future<ServiceConnectionTable> _insertConnection(
  ServiceConnectionRepository repository,
  ServiceConnectionsCompanion companion,
) async {
  try {
    return await repository._database
        .into(repository._database.serviceConnections)
        .insertReturning(companion);
  } on Object {
    if (companion.encryptedAuthValue.present) {
      await repository._encryptionService.deleteCredential(
        companion.encryptedAuthValue.value,
      );
    }
    rethrow;
  }
}

ServiceConnectionsCompanion _baseConnectionCompanion(
  _ConnectionInsertRequest request,
) => .insert(
  name: request.name,
  serviceId: request.serviceId,
  kind: request.kind,
  authenticationType: request.authenticationType,
  workspaceId: request.workspaceId,
);

DateTime? _expiresAt(OAuthTokenEntity token) {
  final expiresIn = token.expiresIn;
  if (expiresIn == null) return null;

  return token.issuedAt.add(.new(seconds: expiresIn));
}

String? _suffix(String value) {
  const suffixLength = 6;
  if (value.length <= suffixLength) return null;

  return value.lastCharacters(suffixLength);
}

Future<ServiceConnectionTable?> _getRowById(
  ServiceConnectionRepository repository,
  String id,
) {
  final query = repository._database.select(
    repository._database.serviceConnections,
  );
  final _ = query.where((table) => table.id.equals(id));

  return query.getSingleOrNull();
}

Future<ServiceConnectionTable> _requiredRowById(
  ServiceConnectionRepository repository,
  String id,
) async {
  final row = await _getRowById(repository, id);
  if (row == null) throw StateError('Service connection not found: $id');

  return row;
}

ServiceConnectionEntity _toEntity(ServiceConnectionTable row) =>
    _ServiceConnectionEntityRow(row).value;

class _ServiceConnectionEntityRow(final ServiceConnectionTable row) {
  final value = ServiceConnectionEntity(
    id: row.id,
    workspaceId: row.workspaceId,
    authenticationType: _authenticationType(row.authenticationType),
    isEnabled: row.isEnabled,
    metadataJson: row.metadataJson,
    expiresAt: row.expiresAt,
    lastRefreshedAt: row.lastRefreshedAt,
    updatedAt: row.updatedAt,
    authStatus: row.authStatus,
    lastAuthError: row.lastAuthError,
  );
}

ServiceConnectionAuthenticationType _authenticationType(
  ServiceAuthenticationTypeTable type,
) => switch (type) {
  .none => ServiceConnectionAuthenticationType.none,
  .apiKey => ServiceConnectionAuthenticationType.apiKey,
  .bearerToken => ServiceConnectionAuthenticationType.bearerToken,
  .oauth2 => ServiceConnectionAuthenticationType.oauth2,
};

String _candidateName(ServiceConnectionTable row) {
  final prefix = _candidatePrefixForKind(row.kind, row.serviceId);
  final suffix = row.keySuffix;
  if (suffix == null || suffix.isEmpty) return '$prefix: ${row.name}';

  return '$prefix: ${row.name} ****$suffix';
}

String _candidatePrefixForKind(
  ServiceConnectionKindTable kind,
  String serviceId,
) => switch (kind) {
  .modelProvider => _candidatePrefix(
    LocaleKeys.service_connections_candidate_model_provider,
    'Model provider {serviceId}',
    serviceId,
  ),
  .customHttp => _candidatePrefix(
    LocaleKeys.service_connections_candidate_connector,
    'Connector {serviceId}',
    serviceId,
  ),
  _ => serviceId,
};

String _candidatePrefix(String key, String fallback, String serviceId) {
  final value = switch (key) {
    LocaleKeys.service_connections_candidate_model_provider =>
      LocaleKeys.service_connections_candidate_model_provider.tr(
        namedArgs: {'serviceId': serviceId},
      ),
    LocaleKeys.service_connections_candidate_connector =>
      LocaleKeys.service_connections_candidate_connector.tr(
        namedArgs: {'serviceId': serviceId},
      ),
    _ => key,
  };
  if (value != key) return value;

  return fallback.replaceAll('{serviceId}', serviceId);
}

class const ServiceConnectionCandidate({
  required final String id,
  required final String name,
  required final String serviceId,
  required final ServiceConnectionKindTable kind,
});

class const GenericServiceConnectionRecord({
  required final String id,
  required final String name,
  required final String serviceId,
  required final bool hasSecret,
  required final String? keySuffix,
});

class const McpServiceConnectionProfile({
  required final String name,
  required final McpAuthenticationType authenticationType,
}) {
  String serviceId() => 'mcp:$name';
}

typedef _CredentialChange = ({
  ServiceConnectionRepository repository,
  String? previous,
  ServiceConnectionsCompanion companion,
});
Future<void> _persistCredentialChange(
  _CredentialChange change,
  Future<int> Function() persist,
) async {
  final int count;
  try {
    count = await persist();
  } on Object {
    await _cleanupCredentialChange(change, false);
    rethrow;
  }
  await _cleanupCredentialChange(change, count > 0);
}

Future<void> _cleanupCredentialChange(
  _CredentialChange change,
  bool applied,
) async {
  final value = change.companion.encryptedAuthValue;
  if (!value.present || value.value == change.previous) return;
  await change.repository._encryptionService.deleteCredential(
    applied ? change.previous : value.value,
  );
}

Future<String> _missingLegacySecret(
  ServiceConnectionRepository repository,
  String rowId,
  String storedValue,
) async {
  final current = await _requiredRowById(repository, rowId);
  if (current.encryptedAuthValue != storedValue) {
    return await _currentSecretPayload(repository, rowId);
  }
  throw const FormatException('Legacy API key is unavailable.');
}

Future<int> _deleteMcpCredentialRow(
  ServiceConnectionRepository repository,
  String id,
) async {
  final delete = repository._database.delete(
    repository._database.serviceConnections,
  );
  final _ = delete.where((table) => _ownedMcpCredentialFilter(table, id));

  return await delete.go();
}

Future<int> _deleteConnectorRow(
  ServiceConnectionRepository repository,
  String id,
  String workspaceId,
) async {
  final delete = repository._database.delete(
    repository._database.serviceConnections,
  );
  final _ = delete.where(
    (table) =>
        _connectorConnectionFilter(table, id: id, workspaceId: workspaceId),
  );

  return await delete.go();
}

UpdateStatement<$ServiceConnectionsTable, ServiceConnectionTable>
_connectorUpdateStatement(
  ServiceConnectionRepository repository,
  ConnectorConnectionUpdateRequest request,
) =>
    repository._database.update(repository._database.serviceConnections)
      ..where((table) => _connectorConnectionUpdateFilter(table, request));
UpdateStatement<$ServiceConnectionsTable, ServiceConnectionTable>
_connectionUpdateStatement(ServiceConnectionRepository repository, String id) =>
    repository._database.update(repository._database.serviceConnections)
      ..where((table) => table.id.equals(id));
_CredentialMigration _legacyCredentialMigration(
  ServiceConnectionRepository repository,
  String rowId,
  ({String storedValue, String apiKey}) secret,
) => (
  repository: repository,
  rowId: rowId,
  expectedValue: secret.storedValue,
  value: _apiKeyPayload(secret.apiKey),
  keySuffix: .new(_suffix(secret.apiKey)),
);
String _apiKeyPayload(String apiKey) => ServiceConnectionAuthCodec.encodeSecret(
  ServiceConnectionSecretApiKey(apiKey: apiKey),
);

_CredentialChange _credentialChange(
  ServiceConnectionRepository repository,
  String? previous,
  ServiceConnectionsCompanion companion,
) => (repository: repository, previous: previous, companion: companion);

ServiceConnectionSecret _decodeStoredSecret(
  ServiceConnectionTable row,
  String value,
) {
  try {
    return ServiceConnectionAuthCodec.decodeSecret(value);
  } on FormatException {
    if (row.kind != ServiceConnectionKindTable.modelProvider) rethrow;

    return ServiceConnectionSecretApiKey(apiKey: value);
  }
}
