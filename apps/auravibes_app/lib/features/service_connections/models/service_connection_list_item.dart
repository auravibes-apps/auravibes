import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
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
  factory fromModelConnection(ModelConnectionEntity connection) {
    return ServiceConnectionListItem(
      id: connection.id,
      workspaceId: connection.workspaceId,
      name: connection.name,
      serviceName: connection.modelId,
      kind: ServiceConnectionListItemKind.modelProvider,
      keySuffix: connection.keySuffix,
      credentialDefinitionId: null,
      mcpServerId: null,
      authenticationType: null,
      displayStatus: ServiceConnectionDisplayStatus.unknown,
      expiresAt: null,
      lastRefreshedAt: null,
      lastAuthError: null,
      metadataValues: const [],
      canRefresh: false,
      canReconnect: false,
    );
  }

  factory fromSkillCredential({
    required SkillCredentialEntity credential,
    required SkillCredentialDefinitionEntity? definition,
  }) {
    return ServiceConnectionListItem(
      id: credential.id,
      workspaceId: credential.workspaceId,
      name: credential.name,
      serviceName: definition?.title,
      kind: ServiceConnectionListItemKind.skillCredential,
      keySuffix: credential.keySuffix,
      credentialDefinitionId: credential.credentialDefinitionId,
      mcpServerId: null,
      authenticationType: null,
      displayStatus: ServiceConnectionDisplayStatus.unknown,
      expiresAt: null,
      lastRefreshedAt: null,
      lastAuthError: null,
      metadataValues: const [],
      canRefresh: false,
      canReconnect: false,
    );
  }

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
  }) {
    return ServiceConnectionListItem(
      id: id,
      workspaceId: workspaceId,
      name: name,
      serviceName: _hostFromUrl(url) ?? metadata.provider,
      kind: ServiceConnectionListItemKind.mcpServer,
      keySuffix: null,
      credentialDefinitionId: null,
      mcpServerId: mcpServerId,
      authenticationType: authenticationType,
      displayStatus: _displayStatus(
        authStatus: authStatus,
        expiresAt: expiresAt,
        lastAuthError: lastAuthError,
        isEnabled: isEnabled,
        hasMetadataError: hasMetadataError,
        now: now,
      ),
      expiresAt: expiresAt,
      lastRefreshedAt: lastRefreshedAt,
      lastAuthError: lastAuthError,
      metadataValues: _metadataValues(
        metadata: metadata,
        expiresAt: expiresAt,
        lastRefreshedAt: lastRefreshedAt,
        lastAuthError: lastAuthError,
      ),
      canRefresh: canRefresh,
      canReconnect: true,
    );
  }
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

ServiceConnectionDisplayStatus _displayStatus({
  required ServiceConnectionAuthStatus? authStatus,
  required DateTime? expiresAt,
  required String? lastAuthError,
  required bool isEnabled,
  required bool hasMetadataError,
  required DateTime now,
}) {
  return switch (authStatus) {
    ServiceConnectionAuthStatus.needsReauth =>
      ServiceConnectionDisplayStatus.needsReauth,
    ServiceConnectionAuthStatus.failed => ServiceConnectionDisplayStatus.failed,
    _ when hasMetadataError => ServiceConnectionDisplayStatus.failed,
    _ when _expiresSoon(expiresAt, now) =>
      ServiceConnectionDisplayStatus.expiringSoon,
    _ when isEnabled && (lastAuthError == null || lastAuthError.isEmpty) =>
      ServiceConnectionDisplayStatus.connected,
    _ => ServiceConnectionDisplayStatus.unknown,
  };
}

bool _expiresSoon(DateTime? expiresAt, DateTime now) {
  if (expiresAt == null) return false;

  return expiresAt.isBefore(now.add(_expiryWarningThreshold));
}

List<ServiceConnectionMetadataValue> _metadataValues({
  required ServiceConnectionMetadata metadata,
  required DateTime? expiresAt,
  required DateTime? lastRefreshedAt,
  required String? lastAuthError,
}) {
  return [
    if (metadata.issuer case final issuer?)
      ServiceConnectionMetadataValue(
        key: ServiceConnectionMetadataKey.issuer,
        value: issuer,
      ),
    if (metadata.clientId case final clientId?)
      ServiceConnectionMetadataValue(
        key: ServiceConnectionMetadataKey.clientId,
        value: clientId,
      ),
    if (metadata.scopes.isNotEmpty)
      ServiceConnectionMetadataValue(
        key: ServiceConnectionMetadataKey.scopes,
        value: metadata.scopes.join(', '),
      ),
    if (expiresAt case final expiresAt?)
      ServiceConnectionMetadataValue(
        key: ServiceConnectionMetadataKey.expiresAt,
        value: expiresAt.toIso8601String(),
      ),
    if (lastRefreshedAt case final lastRefreshedAt?)
      ServiceConnectionMetadataValue(
        key: ServiceConnectionMetadataKey.lastRefreshedAt,
        value: lastRefreshedAt.toIso8601String(),
      ),
    if (lastAuthError case final lastAuthError? when lastAuthError.isNotEmpty)
      ServiceConnectionMetadataValue(
        key: ServiceConnectionMetadataKey.lastAuthError,
        value: lastAuthError,
      ),
  ];
}

String? _hostFromUrl(String value) {
  final uri = Uri.tryParse(value);
  final host = uri?.host;
  if (host == null || host.isEmpty) return null;

  return host;
}
