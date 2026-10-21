import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_connection_test_summary.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/features/service_connections/models/connector_capability_filter.dart';
import 'package:auravibes_app/features/service_connections/models/connector_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

final _logger = Logger('watch_service_connection_list_items_usecase');

typedef _ConnectionLists = ({
  List<ModelConnectionEntity> modelConnections,
  List<ServiceConnectionListItem> mcpCredentials,
  List<ServiceConnectionListItem> connectorConnections,
});

typedef _AdditionalConnectionLists = ({
  List<ServiceConnectionListItem> mcpCredentials,
  List<ServiceConnectionListItem> connectorConnections,
});

typedef _McpCredentialItemRequest = ({
  McpServersTable server,
  ServiceConnectionTable? credential,
  ({ServiceConnectionMetadata metadata, bool hasError})? metadataResult,
});

class const WatchServiceConnectionListItemsUsecase(
  final AppDatabase _database,
  final ModelConnectionRepository _modelConnectionRepository,
  final DateTime Function() _now,
) {
  Stream<List<ServiceConnectionListItem>> call(String workspaceId) {
    return Rx.combineLatest2(
      _modelConnectionRepository.watchModelConnections(
        .new(workspaces: [workspaceId]),
      ),
      Rx.combineLatest2(
        _watchMcpCredentialItems(workspaceId),
        _watchConnectorConnectionItems(workspaceId),
        (mcpCredentials, connectorConnections) => (
          mcpCredentials: mcpCredentials,
          connectorConnections: connectorConnections,
        ),
      ),
      _combineConnectionItems,
    );
  }

  Stream<List<ConnectorCatalogItem>> watchConnectorCatalog(
    String workspaceId, {
    required List<ConnectorCatalogOffering> offerings,
    ConnectorCapabilityFilter filter = .all,
  }) => call(workspaceId).map(
    (connections) => ConnectorCatalogItem.fromOfferings(
      offerings,
      connections: connections,
      filter: filter,
    ),
  );

  Stream<List<ServiceConnectionListItem>> _watchMcpCredentialItems(
    String workspaceId,
  ) {
    final query = _database.select(_database.mcpServers).join([
      leftOuterJoin(
        _database.serviceConnections,
        _database.serviceConnections.id.equalsExp(
          _database.mcpServers.serviceConnectionId,
        ),
      ),
    ])..where(_database.mcpServers.workspaceId.equals(workspaceId));

    return query.watch().map(_mcpCredentialRows);
  }

  Stream<List<ServiceConnectionListItem>> _watchConnectorConnectionItems(
    String workspaceId,
  ) {
    final query = _database.select(_database.serviceConnections);
    final _ = query.where(
      (table) => _connectorWorkspaceFilter(table, workspaceId),
    );

    return query.watch().map((rows) => rows.map(_connectorItem).toList());
  }

  ServiceConnectionListItem _connectorItem(ServiceConnectionTable connection) =>
      ServiceConnectionListItem.fromConnectorConnection(
        id: connection.id,
        workspaceId: connection.workspaceId,
        name: connection.name,
        serviceId: connection.serviceId,
        keySuffix: connection.keySuffix,
        hasSecret: connection.encryptedAuthValue != null,
      );

  List<ServiceConnectionListItem> _mcpCredentialRows(List<TypedResult> rows) =>
      rows.map(_mcpCredentialItem).toList();

  ServiceConnectionListItem _mcpCredentialItem(TypedResult row) {
    final server = row.readTable(_database.mcpServers);
    final credential = row.readTableOrNull(_database.serviceConnections);

    return ServiceConnectionListItem.fromMcpCredential(
      _buildMcpCredentialItem((
        server: server,
        credential: credential,
        metadataResult: credential == null ? null : _decodeMetadata(credential),
      )),
    );
  }

  ServiceConnectionMcpCredential _buildMcpCredentialItem(
    _McpCredentialItemRequest request,
  ) => _McpCredentialItem(
    request,
    _now(),
    canRefresh: _canRefresh(request.credential),
  ).value;

  bool _canRefresh(ServiceConnectionTable? credential) =>
      credential?.authenticationType == ServiceAuthenticationTypeTable.oauth2;

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
  new(
    _McpCredentialItemRequest request,
    DateTime now, {
    required bool canRefresh,
  }) : value = (
         id: request.server.id,
         workspaceId: request.server.workspaceId,
         name: request.server.name,
         url: request.server.url,
         mcpServerId: request.server.id,
         transport: request.server.transport,
         authenticationType:
             request.credential?.authenticationType.value ?? 'none',
         isEnabled: request.credential?.isEnabled ?? true,
         authStatus: request.credential?.authStatus,
         expiresAt: request.credential?.expiresAt,
         lastRefreshedAt: request.credential?.lastRefreshedAt,
         lastAuthError: request.credential?.lastAuthError,
         metadata:
             request.metadataResult?.metadata ??
             const ServiceConnectionMetadata(),
         canRefresh: canRefresh,
         now: now,
         hasMetadataError: request.metadataResult?.hasError ?? false,
         lastTestSummary: McpConnectionTestSummary.fromJson(
           request.server.testSummaryJson,
         ),
       );

  final ServiceConnectionMcpCredential value;
}

List<ServiceConnectionListItem> _combineConnectionItems(
  List<ModelConnectionEntity> models,
  _AdditionalConnectionLists additional,
) => _buildConnectionItems((
  modelConnections: models,
  mcpCredentials: additional.mcpCredentials,
  connectorConnections: additional.connectorConnections,
));

Expression<bool> _connectorWorkspaceFilter(
  ServiceConnections table,
  String workspaceId,
) =>
    table.workspaceId.equals(workspaceId) &
    table.kind.equals(ServiceConnectionKindTable.customHttp.name);

List<ServiceConnectionListItem> _buildConnectionItems(_ConnectionLists input) {
  return [
    ...input.modelConnections.map(
      ServiceConnectionListItem.fromModelConnection,
    ),
    ...input.connectorConnections,
    ...input.mcpCredentials,
  ]..sort((a, b) => a.name.compareTo(b.name));
}
