import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';

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
  ServiceConnectionListItem._fromModelConnection(
    ModelConnectionEntity connection,
  ) : this(
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

  ServiceConnectionListItem._fromSkillCredential({
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

  factory fromMcpCredential({
    required String id,
    required String workspaceId,
    required String name,
    required String url,
    required String mcpServerId,
    required String authenticationType,
    required bool isEnabled,
    required ServiceConnectionAuthStatus? authStatus,
    required DateTime? expiresAt,
    required DateTime? lastRefreshedAt,
    required String? lastAuthError,
    required ServiceConnectionMetadata metadata,
    required bool canRefresh,
    required DateTime now,
    required bool hasMetadataError,
  }) = ServiceConnectionListItem._fromMcpCredential;

  ServiceConnectionListItem._fromMcpCredential({
    required String id,
    required String workspaceId,
    required String name,
    required String url,
    required String mcpServerId,
    required String authenticationType,
    required bool isEnabled,
    required ServiceConnectionAuthStatus? authStatus,
    required DateTime? expiresAt,
    required DateTime? lastRefreshedAt,
    required String? lastAuthError,
    required ServiceConnectionMetadata metadata,
    required bool canRefresh,
    required DateTime now,
    required bool hasMetadataError,
  }) : this(
         id: id,
         workspaceId: workspaceId,
         name: name,
         serviceName: _hostFromUrl(url) ?? metadata.provider,
         kind: .mcpServer,
         keySuffix: null,
         credentialDefinitionId: null,
         mcpServerId: mcpServerId,
         authenticationType: authenticationType,
         displayStatus: _displayStatus(
           _DisplayStatusRequest(
             authStatus: authStatus,
             expiresAt: expiresAt,
             lastAuthError: lastAuthError,
             isEnabled: isEnabled,
             hasMetadataError: hasMetadataError,
             now: now,
           ),
         ),
         expiresAt: expiresAt,
         lastRefreshedAt: lastRefreshedAt,
         lastAuthError: lastAuthError,
         metadataValues: _metadataValues(
           _MetadataValuesRequest(
             metadata: metadata,
             expiresAt: expiresAt,
             lastRefreshedAt: lastRefreshedAt,
             lastAuthError: lastAuthError,
           ),
         ),
         canRefresh: canRefresh,
         canReconnect: true,
       );

  static ServiceConnectionListItem fromModelConnection(
    ModelConnectionEntity connection,
  ) => ServiceConnectionListItem._fromModelConnection(connection);

  static ServiceConnectionListItem fromSkillCredential({
    required SkillCredentialEntity credential,
    required SkillCredentialDefinitionEntity? definition,
  }) => ServiceConnectionListItem._fromSkillCredential(
    credential: credential,
    definition: definition,
  );
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
  return request.isEnabled &&
      (request.lastAuthError == null || request.lastAuthError!.isEmpty);
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
