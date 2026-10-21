import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/models/models/cloud_model_connection.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/usecases/cloud_model_connection_usecases.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/models/connector_connection_candidate.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

export '../models/connector_connection_candidate.dart';

typedef CloudServiceConnectionsReader =
    Future<List<CloudServiceConnection>?> Function(String workspaceId);
typedef CloudModelConnectionsReader =
    Future<List<CloudModelConnection>?> Function(String workspaceId);

class const ListConnectorConnectionCandidatesUsecase(
  final ServiceConnectionRepository Function() _serviceConnectionRepository, {
  final CloudServiceConnectionsReader? _cloudServiceConnectionsReader,
  final CloudModelConnectionsReader? _cloudModelConnectionsReader,
}) {
  Future<List<ConnectorConnectionCandidate>> forConnector({
    required String workspaceId,
    required ConnectorDefinition connector,
  }) async {
    final connections = await _cloudServiceConnectionsReader?.call(workspaceId);
    if (connections != null) {
      return _cloudConnectorCandidates(
        connections,
        await _cloudModelConnectionsReader?.call(workspaceId) ?? const [],
        connector,
      );
    }

    return await _localConnectorCandidates(workspaceId, connector);
  }

  Future<List<ConnectorConnectionCandidate>> _localConnectorCandidates(
    String workspaceId,
    ConnectorDefinition connector,
  ) async {
    final candidates = await _serviceConnectionRepository()
        .listConnectorConnectionCandidates((
          workspaceId: workspaceId,
          connectorId: connector.identifier,
          compatibleModelProviderIds: connector.compatibleModelProviderIds,
        ));

    return [
      for (final candidate in candidates)
        ConnectorConnectionCandidate(
          id: _prefixedId(candidate),
          name: candidate.name,
        ),
    ];
  }

  List<ConnectorConnectionCandidate> _cloudConnectorCandidates(
    List<CloudServiceConnection> connections,
    List<CloudModelConnection> modelConnections,
    ConnectorDefinition connector,
  ) => [
    for (final connection in connections)
      if (_isUsableCloudConnector(connection, connector.identifier))
        ConnectorConnectionCandidate(
          id: 'service:${connection.id}',
          name: connection.name,
        ),
    for (final connection in modelConnections)
      if (connector.compatibleModelProviderIds.contains(
            connection.providerId,
          ) &&
          connection.hasSecret)
        ConnectorConnectionCandidate(
          id: 'model:${connection.id}',
          name: connection.name,
        ),
  ];

  String _prefixedId(ServiceConnectionCandidate candidate) =>
      candidate.kind == ServiceConnectionKindTable.modelProvider
      ? 'model:${candidate.id}'
      : 'service:${candidate.id}';
}

bool _isUsableCloudConnector(
  CloudServiceConnection connection,
  String connectorId,
) =>
    connection.kind == 'customHttp' &&
    connection.serviceId == connectorId &&
    connection.isEnabled &&
    connection.hasSecret;

final listConnectorConnectionCandidatesUsecaseProvider =
    Provider<ListConnectorConnectionCandidatesUsecase>((ref) {
      return ListConnectorConnectionCandidatesUsecase(
        () => ref.read(serviceConnectionRepositoryProvider),
        cloudServiceConnectionsReader: (workspaceId) async {
          final session = await ref.read(
            workspaceSessionForRouteProvider(workspaceId).future,
          );
          if (session.cloud == null) return null;

          final gateway = await ref.read(
            cloudWorkspaceStateGatewayProvider(session).future,
          );
          if (gateway == null) {
            throw StateError('Cloud workspace gateway is unavailable.');
          }

          return await CloudServiceConnectionUsecases(.new(gateway))
              .watch()
              .first;
        },
        cloudModelConnectionsReader: (workspaceId) async {
          final gateway = await ref.read(
            cloudModelGatewayForWorkspaceProvider(workspaceId).future,
          );
          if (gateway == null) return null;

          return await CloudModelConnectionUsecases(gateway)
              .watchConnections()
              .first;
        },
      );
    });
