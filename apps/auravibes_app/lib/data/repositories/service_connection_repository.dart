import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:drift/drift.dart';
import 'package:easy_localization/easy_localization.dart';

typedef AppSkillCredentialUpdateRequest = ({
  String id,
  String workspaceId,
  String name,
  bool clearSecret,
  String? secret,
});

typedef AppSkillCredentialCreateRequest = ({
  String workspaceId,
  String appSkillServiceId,
  String name,
  String apiKey,
});

typedef AppSkillCredentialCandidatesRequest = ({
  String workspaceId,
  String appSkillServiceId,
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

class const ServiceConnectionRepository(
  final AppDatabase _database,
  final EncryptionService _encryptionService,
) with _ServiceConnectionRepositoryQueries {
  Future<GenericServiceConnectionRecord?> getAppSkillCredentialForEdit(
    String id, {
    required String workspaceId,
  }) => _getAppSkillCredentialForEdit(this, id, workspaceId: workspaceId);

  Future<void> updateAppSkillCredential(
    AppSkillCredentialUpdateRequest request,
  ) => _updateAppSkillCredential(this, request);

  Future<List<ServiceConnectionCandidate>> listAppSkillCredentialCandidates(
    AppSkillCredentialCandidatesRequest request,
  ) => _listAppSkillCredentialCandidates(this, request);

  Future<ServiceConnectionEntity> createAppSkillCredential(
    AppSkillCredentialCreateRequest request,
  ) => _createAppSkillCredential(this, request);

  Future<ServiceConnectionSecret> readSecret(String id) =>
      _readSecret(this, id);

  Future<String?> createMcpServiceConnection({
    required String workspaceId,
    required McpServiceConnectionProfile profile,
  }) => _createMcpServiceConnection(this, workspaceId, profile);

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

Future<GenericServiceConnectionRecord?> _getAppSkillCredentialForEdit(
  ServiceConnectionRepository repository,
  String id, {
  required String workspaceId,
}) async {
  final row = await _getRowById(repository, id);
  if (row == null || !_isAppSkillCredential(row, workspaceId)) return null;

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

bool _isAppSkillCredential(ServiceConnectionTable row, String workspaceId) =>
    row.workspaceId == workspaceId &&
    row.kind == ServiceConnectionKindTable.appSkillCredential;

Future<void> _updateAppSkillCredential(
  ServiceConnectionRepository repository,
  AppSkillCredentialUpdateRequest request,
) async {
  final companion = await _appSkillCredentialUpdateCompanion(
    repository,
    request,
  );
  final update = repository._database.update(
    repository._database.serviceConnections,
  );
  final _ = update.where(
    (table) => _appSkillCredentialUpdateFilter(table, request),
  );
  final _ = await update.write(companion);
}

Expression<bool> _appSkillCredentialUpdateFilter(
  ServiceConnections table,
  AppSkillCredentialUpdateRequest request,
) =>
    table.id.equals(request.id) &
    table.workspaceId.equals(request.workspaceId) &
    table.kind.equals(ServiceConnectionKindTable.appSkillCredential.name);

Future<ServiceConnectionsCompanion> _appSkillCredentialUpdateCompanion(
  ServiceConnectionRepository repository,
  AppSkillCredentialUpdateRequest request,
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

Future<List<ServiceConnectionCandidate>> _listAppSkillCredentialCandidates(
  ServiceConnectionRepository repository,
  AppSkillCredentialCandidatesRequest request,
) async {
  final rows = await _candidateRows(repository, request);

  return rows.map(_candidate).toList(growable: false);
}

Future<List<ServiceConnectionTable>> _candidateRows(
  ServiceConnectionRepository repository,
  AppSkillCredentialCandidatesRequest request,
) {
  final query = repository._database.select(
    repository._database.serviceConnections,
  );
  final _ = query.where((table) => _candidateFilter(table, request));

  return query.get();
}

Expression<bool> _candidateFilter(
  ServiceConnections table,
  AppSkillCredentialCandidatesRequest request,
) {
  final compatibleProviders = request.compatibleModelProviderIds.toSet();

  return table.workspaceId.equals(request.workspaceId) &
      table.isEnabled.equals(true) &
      table.encryptedAuthValue.isNotNull() &
      (_appSkillCandidateFilter(table, request) |
          _modelProviderCandidateFilter(table, compatibleProviders));
}

Expression<bool> _appSkillCandidateFilter(
  ServiceConnections table,
  AppSkillCredentialCandidatesRequest request,
) =>
    table.kind.equals(ServiceConnectionKindTable.appSkillCredential.name) &
    table.serviceId.equals(request.appSkillServiceId);

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

Future<ServiceConnectionEntity> _createAppSkillCredential(
  ServiceConnectionRepository repository,
  AppSkillCredentialCreateRequest request,
) async {
  final encrypted = await _encryptedApiKey(repository, request.apiKey);
  final companion = _appSkillCredentialCompanion(request, encrypted);
  final row = await _insertConnection(repository, companion);

  return _toEntity(row);
}

ServiceConnectionsCompanion _appSkillCredentialCompanion(
  AppSkillCredentialCreateRequest request,
  String encrypted,
) =>
    _baseConnectionCompanion((
      name: request.name,
      serviceId: request.appSkillServiceId,
      kind: .appSkillCredential,
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

  final value = await repository._encryptionService.decrypt(encrypted);

  return ServiceConnectionAuthCodec.decodeSecret(value);
}

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
    final McpAuthenticationTypeOAuth authenticationType =>
      _createOAuthForAuthentication(request, authenticationType),
  };
}

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
  final delete = repository._database.delete(
    repository._database.serviceConnections,
  );
  final _ = delete.where((table) => _ownedMcpCredentialFilter(table, id));
  final _ = await delete.go();
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
  final update = repository._database.update(
    repository._database.serviceConnections,
  );
  final _ = update.where((table) => table.id.equals(id));
  final _ = await update.write(companion);
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

  return repository._encryptionService.encrypt(encoded);
}

Future<ServiceConnectionTable> _insertConnection(
  ServiceConnectionRepository repository,
  ServiceConnectionsCompanion companion,
) => repository._database
    .into(repository._database.serviceConnections)
    .insertReturning(companion);

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

String _suffix(String value) => value.lastCharacters(6);

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
  .appSkillCredential => _candidatePrefix(
    LocaleKeys.service_connections_candidate_app_skill,
    'Service skill {serviceId}',
    serviceId,
  ),
  _ => serviceId,
};

String _candidatePrefix(String key, String fallback, String serviceId) {
  final value = tr(key, namedArgs: {'serviceId': serviceId});
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
