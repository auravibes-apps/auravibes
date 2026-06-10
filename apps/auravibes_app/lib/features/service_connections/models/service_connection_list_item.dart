import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';

class ServiceConnectionListItem {
  const ServiceConnectionListItem({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.serviceName,
    required this.kind,
    required this.keySuffix,
    required this.credentialDefinitionId,
    required this.mcpServerId,
    required this.authenticationType,
    required this.displayStatus,
    required this.expiresAt,
    required this.lastRefreshedAt,
    required this.lastAuthError,
    required this.metadataValues,
    required this.canRefresh,
    required this.canReconnect,
  });

  factory ServiceConnectionListItem.fromModelConnection(
    ModelConnectionEntity connection,
  ) {
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

  factory ServiceConnectionListItem.fromSkillCredential({
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

  factory ServiceConnectionListItem.fromMcpCredential({
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

  final String id;
  final String workspaceId;
  final String name;
  final String? serviceName;
  final ServiceConnectionListItemKind kind;
  final String? keySuffix;
  final String? credentialDefinitionId;
  final String? mcpServerId;
  final String? authenticationType;
  final ServiceConnectionDisplayStatus displayStatus;
  final DateTime? expiresAt;
  final DateTime? lastRefreshedAt;
  final String? lastAuthError;
  final List<ServiceConnectionMetadataValue> metadataValues;
  final bool canRefresh;
  final bool canReconnect;
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

class ServiceConnectionMetadataValue {
  const ServiceConnectionMetadataValue({
    required this.key,
    required this.value,
  });

  final ServiceConnectionMetadataKey key;
  final String value;
}

ServiceConnectionDisplayStatus _displayStatus({
  required ServiceConnectionAuthStatus? authStatus,
  required DateTime? expiresAt,
  required String? lastAuthError,
  required bool isEnabled,
  required DateTime now,
}) {
  return switch (authStatus) {
    ServiceConnectionAuthStatus.needsReauth =>
      ServiceConnectionDisplayStatus.needsReauth,
    ServiceConnectionAuthStatus.failed => ServiceConnectionDisplayStatus.failed,
    _ when _expiresSoon(expiresAt, now) =>
      ServiceConnectionDisplayStatus.expiringSoon,
    _ when isEnabled && (lastAuthError == null || lastAuthError.isEmpty) =>
      ServiceConnectionDisplayStatus.connected,
    _ => ServiceConnectionDisplayStatus.unknown,
  };
}

bool _expiresSoon(DateTime? expiresAt, DateTime now) {
  if (expiresAt == null) return false;

  return expiresAt.isBefore(now.add(const Duration(minutes: 5)));
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
