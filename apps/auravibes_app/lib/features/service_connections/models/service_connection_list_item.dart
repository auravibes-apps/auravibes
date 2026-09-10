import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';

typedef ServiceConnectionMcpCredential = ({
  String id,
  String workspaceId,
  String name,
  String url,
  String mcpServerId,
  String authenticationType,
  bool isEnabled,
  ServiceConnectionAuthStatus? authStatus,
  DateTime? expiresAt,
  DateTime? lastRefreshedAt,
  String? lastAuthError,
  ServiceConnectionMetadata metadata,
  bool canRefresh,
  DateTime now,
  bool hasMetadataError,
});

class const ServiceConnectionListItem({
  required final String id,
  required final String workspaceId,
  required final String name,
  required final String? serviceName,
  required final ServiceConnectionListItemKind kind,
  required final String? keySuffix,
  required final String? credentialDefinitionId,
  required final String? mcpServerId,
  required final String? authenticationType,
  required final ServiceConnectionDisplayStatus displayStatus,
  required final DateTime? expiresAt,
  required final DateTime? lastRefreshedAt,
  required final String? lastAuthError,
  required final List<ServiceConnectionMetadataValue> metadataValues,
  required final bool canRefresh,
  required final bool canReconnect,
}) {
  new _fromModelConnection(ModelConnectionEntity connection)
    : this(
        id: connection.id,
        workspaceId: connection.workspaceId,
        name: connection.name,
        serviceName: connection.modelId,
        kind: .modelProvider,
        keySuffix: connection.keySuffix,
        credentialDefinitionId: null,
        mcpServerId: null,
        authenticationType: null,
        displayStatus: .unknown,
        expiresAt: null,
        lastRefreshedAt: null,
        lastAuthError: null,
        metadataValues: const [],
        canRefresh: false,
        canReconnect: false,
      );

  new _fromSkillCredential({
    required SkillCredentialEntity credential,
    required SkillCredentialDefinitionEntity? definition,
  }) : this(
         id: credential.id,
         workspaceId: credential.workspaceId,
         name: credential.name,
         serviceName: definition?.title,
         kind: .skillCredential,
         keySuffix: credential.keySuffix,
         credentialDefinitionId: credential.credentialDefinitionId,
         mcpServerId: null,
         authenticationType: null,
         displayStatus: .unknown,
         expiresAt: null,
         lastRefreshedAt: null,
         lastAuthError: null,
         metadataValues: const [],
         canRefresh: false,
         canReconnect: false,
       );

  factory fromMcpCredential(ServiceConnectionMcpCredential data) =
      ServiceConnectionListItem._fromMcpCredential;

  new _fromMcpCredential(ServiceConnectionMcpCredential data)
    : this(
        id: data.id,
        workspaceId: data.workspaceId,
        name: data.name,
        serviceName: _hostFromUrl(data.url) ?? data.metadata.provider,
        kind: .mcpServer,
        keySuffix: null,
        credentialDefinitionId: null,
        mcpServerId: data.mcpServerId,
        authenticationType: data.authenticationType,
        displayStatus: _displayStatus(
          .new(
            authStatus: data.authStatus,
            expiresAt: data.expiresAt,
            lastAuthError: data.lastAuthError,
            isEnabled: data.isEnabled,
            hasMetadataError: data.hasMetadataError,
            now: data.now,
          ),
        ),
        expiresAt: data.expiresAt,
        lastRefreshedAt: data.lastRefreshedAt,
        lastAuthError: data.lastAuthError,
        metadataValues: _metadataValues(
          .new(
            metadata: data.metadata,
            expiresAt: data.expiresAt,
            lastRefreshedAt: data.lastRefreshedAt,
            lastAuthError: data.lastAuthError,
          ),
        ),
        canRefresh: data.canRefresh,
        canReconnect: true,
      );

  factory fromSkillCredential({
    required SkillCredentialEntity credential,
    required SkillCredentialDefinitionEntity? definition,
  }) => ._fromSkillCredential(credential: credential, definition: definition);

  static ServiceConnectionListItem fromModelConnection(
    ModelConnectionEntity connection,
  ) => ._fromModelConnection(connection);

  bool hasActions() => canRefresh || canReconnect;
}

enum ServiceConnectionListItemKind { modelProvider, skillCredential, mcpServer }

enum ServiceConnectionDisplayStatus {
  connected,
  expiringSoon,
  needsReauth,
  failed,
  unknown,
}

enum ServiceConnectionMetadataKey {
  issuer,
  clientId,
  scopes,
  expiresAt,
  lastRefreshedAt,
  lastAuthError,
}

class const ServiceConnectionMetadataValue({
  required final ServiceConnectionMetadataKey key,
  required final String value,
});

// Keep the warning window short so reconnect prompts appear only when a token
// is close enough to expiry that a failed refresh would affect the user soon.
const _expiryWarningThreshold = Duration(minutes: 5);

class const _DisplayStatusRequest({
  required final ServiceConnectionAuthStatus? authStatus,
  required final DateTime? expiresAt,
  required final String? lastAuthError,
  required final bool isEnabled,
  required final bool hasMetadataError,
  required final DateTime now,
});

class const _MetadataValuesRequest({
  required final ServiceConnectionMetadata metadata,
  required final DateTime? expiresAt,
  required final DateTime? lastRefreshedAt,
  required final String? lastAuthError,
});

ServiceConnectionDisplayStatus _displayStatus(_DisplayStatusRequest request) {
  final authStatus = _authStatus(request.authStatus);
  if (authStatus != null) return authStatus;
  if (request.hasMetadataError) return .failed;
  if (_expiresSoon(request.expiresAt, request.now)) return .expiringSoon;
  if (_isConnected(request)) return .connected;

  return .unknown;
}

ServiceConnectionDisplayStatus? _authStatus(
  ServiceConnectionAuthStatus? status,
) => switch (status) {
  .needsReauth => .needsReauth,
  .failed => .failed,
  _ => null,
};

bool _isConnected(_DisplayStatusRequest request) {
  return request.isEnabled && (request.lastAuthError?.isEmpty ?? true);
}

bool _expiresSoon(DateTime? expiresAt, DateTime now) {
  if (expiresAt == null) return false;

  return expiresAt.isBefore(now.add(_expiryWarningThreshold));
}

List<ServiceConnectionMetadataValue> _metadataValues(
  _MetadataValuesRequest request,
) {
  return [
    ..._providerMetadataValues(request.metadata),
    ..._credentialMetadataValues(request),
  ];
}

List<ServiceConnectionMetadataValue> _providerMetadataValues(
  ServiceConnectionMetadata metadata,
) {
  return [
    if (metadata.issuer case final issuer?)
      ServiceConnectionMetadataValue(key: .issuer, value: issuer),
    if (metadata.clientId case final clientId?)
      ServiceConnectionMetadataValue(key: .clientId, value: clientId),
    if (metadata.scopes.isNotEmpty)
      ServiceConnectionMetadataValue(
        key: .scopes,
        value: metadata.scopes.join(', '),
      ),
  ];
}

List<ServiceConnectionMetadataValue> _credentialMetadataValues(
  _MetadataValuesRequest request,
) => [
  _credentialMetadataValue(.expiresAt, request.expiresAt?.toIso8601String()),
  _credentialMetadataValue(
    .lastRefreshedAt,
    request.lastRefreshedAt?.toIso8601String(),
  ),
  _credentialMetadataValue(.lastAuthError, request.lastAuthError),
].whereType<ServiceConnectionMetadataValue>().toList();

ServiceConnectionMetadataValue? _credentialMetadataValue(
  ServiceConnectionMetadataKey key,
  String? value,
) => value == null || value.isEmpty
    ? null
    : ServiceConnectionMetadataValue(key: key, value: value);

String? _hostFromUrl(String value) {
  final uri = Uri.tryParse(value);
  final host = uri?.host;
  if (host == null || host.isEmpty) return null;

  return host;
}
