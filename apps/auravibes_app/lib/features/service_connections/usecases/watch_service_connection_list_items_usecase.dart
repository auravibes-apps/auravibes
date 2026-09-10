import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

final _logger = Logger('watch_service_connection_list_items_usecase');

typedef _ConnectionLists = ({
  List<ModelConnectionEntity> modelConnections,
  List<SkillCredentialDefinitionEntity> definitions,
  List<SkillCredentialEntity> credentials,
  List<ServiceConnectionListItem> mcpCredentials,
});

typedef _McpCredentialItemRequest = ({
  McpServersTable server,
  ServiceConnectionTable credential,
  ({ServiceConnectionMetadata metadata, bool hasError}) metadataResult,
});

class const WatchServiceConnectionListItemsUsecase(
  final AppDatabase _database,
  final ModelConnectionRepository _modelConnectionRepository,
  final SkillCredentialDefinitionsRepository _credentialDefinitionsRepository,
  final SkillCredentialsRepository _credentialsRepository,
  final DateTime Function() _now,
) {
  Stream<List<ServiceConnectionListItem>> call(String workspaceId) {
    return Rx.combineLatest4(
      _modelConnectionRepository.watchModelConnections(
        .new(workspaces: [workspaceId]),
      ),
      _credentialDefinitionsRepository.watchDefinitions(workspaceId),
      _credentialsRepository.watchCredentialsForWorkspace(workspaceId),
      _watchMcpCredentialItems(workspaceId),
      _combineConnectionItems,
    );
  }

  Stream<List<ServiceConnectionListItem>> _watchMcpCredentialItems(
    String workspaceId,
  ) {
    final query = _database.select(_database.mcpServers).join([
      innerJoin(
        _database.serviceConnections,
        _database.serviceConnections.id.equalsExp(
          _database.mcpServers.serviceConnectionId,
        ),
      ),
    ])..where(_database.mcpServers.workspaceId.equals(workspaceId));

    return query.watch().map(_mcpCredentialRows);
  }

  List<ServiceConnectionListItem> _mcpCredentialRows(List<TypedResult> rows) =>
      rows.map(_mcpCredentialItem).toList();

  ServiceConnectionListItem _mcpCredentialItem(TypedResult row) {
    final server = row.readTable(_database.mcpServers);
    final credential = row.readTable(_database.serviceConnections);
    return ServiceConnectionListItem.fromMcpCredential(
      _buildMcpCredentialItem((
        server: server,
        credential: credential,
        metadataResult: _decodeMetadata(credential),
      )),
    );
  }

  ServiceConnectionMcpCredential _buildMcpCredentialItem(
    _McpCredentialItemRequest request,
  ) => _McpCredentialItem(
    request,
    _canRefresh(request.credential),
    _now(),
  ).value;

  bool _canRefresh(ServiceConnectionTable credential) =>
      credential.authenticationType == ServiceAuthenticationTypeTable.oauth2;

  ({ServiceConnectionMetadata metadata, bool hasError}) _decodeMetadata(
    ServiceConnectionTable credential,
  ) {
    try {
      return (
        metadata: ServiceConnectionAuthCodec.decodeMetadata(
          credential.metadataJson,
        ),
        hasError: false,
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Invalid service connection metadata '
        'connectionId=${credential.id} workspace=${credential.workspaceId}',
        error,
        stackTrace,
      );

      return (metadata: const ServiceConnectionMetadata(), hasError: true);
    }
  }
}

class _McpCredentialItem {
  _McpCredentialItem(
    _McpCredentialItemRequest request,
    bool canRefresh,
    DateTime now,
  ) : value = (
        id: request.credential.id,
        workspaceId: request.credential.workspaceId,
        name: request.server.name,
        url: request.server.url,
        mcpServerId: request.server.id,
        authenticationType: request.credential.authenticationType.value,
        isEnabled: request.credential.isEnabled,
        authStatus: request.credential.authStatus,
        expiresAt: request.credential.expiresAt,
        lastRefreshedAt: request.credential.lastRefreshedAt,
        lastAuthError: request.credential.lastAuthError,
        metadata: request.metadataResult.metadata,
        canRefresh: canRefresh,
        now: now,
        hasMetadataError: request.metadataResult.hasError,
      );

  final ServiceConnectionMcpCredential value;
}

List<ServiceConnectionListItem> _combineConnectionItems(
  List<ModelConnectionEntity> models,
  List<SkillCredentialDefinitionEntity> definitions,
  List<SkillCredentialEntity> credentials,
  List<ServiceConnectionListItem> mcpCredentials,
) => _buildConnectionItems((
  modelConnections: models,
  definitions: definitions,
  credentials: credentials,
  mcpCredentials: mcpCredentials,
));

List<ServiceConnectionListItem> _buildConnectionItems(_ConnectionLists input) {
  return [
    ...input.modelConnections.map(
      ServiceConnectionListItem.fromModelConnection,
    ),
    ..._skillCredentialItems(input.definitions, input.credentials),
    ...input.mcpCredentials,
  ]..sort((a, b) => a.name.compareTo(b.name));
}

Iterable<ServiceConnectionListItem> _skillCredentialItems(
  List<SkillCredentialDefinitionEntity> definitions,
  List<SkillCredentialEntity> credentials,
) {
  final definitionsById = {
    for (final definition in definitions) definition.id: definition,
  };

  return credentials.map((credential) {
    return ServiceConnectionListItem.fromSkillCredential(
      credential: credential,
      definition: definitionsById[credential.credentialDefinitionId],
    );
  });
}
