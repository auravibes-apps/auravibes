import 'dart:convert';

import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/connector_command_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/read_connected_workspace_view_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart'
    show WorkspaceResourceKind;
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_connected_view_provider.g.dart';

typedef WorkspaceConnectedResult = ({Object? value, DateTime fetchedAt});

@riverpod
Future<WorkspaceConnectedResult> workspaceConnectedView(
  Ref ref,
  String workspaceId,
  String viewId,
) async {
  final access = ref.watch(workspaceConnectedAccessProvider(workspaceId));
  if (access.hasError) throw const WorkspaceTableException(denied: true);
  final _ = await ref.watch(
    workspaceConnectedAccessProvider(workspaceId).future,
  );
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final _ = ref.watch(serviceConnectionsProvider(workspaceId));
  final view = (await ref.watch(
    workspaceViewDataProvider(workspaceId, viewId).future,
  )).view;
  final binding = view.connected;
  if (binding == null) throw const WorkspaceTableException();
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted) throw const WorkspaceTableException(denied: true);
  final cloud = session.cloud;
  if (cloud != null) {
    if (gateway == null) throw const WorkspaceTableException(denied: true);
    final result = await gateway.client.workspaceView.readConnected(
      cloud.cloudWorkspaceId,
      viewId,
    );

    return (value: jsonDecode(result), fetchedAt: DateTime.now());
  }
  final commands = ref.watch(connectorCommandUsecaseProvider);
  final result = await ReadConnectedWorkspaceViewUsecase(
    execute: (arguments) => commands.call(
      workspaceId: workspaceId,
      commandName: executeConnectorToolName,
      arguments: arguments,
    ),
  )(binding);
  if (!ref.mounted) throw const WorkspaceTableException(denied: true);
  await ref
      .read(runConnectorToolUsecaseProvider)
      .requireCurrent(
        ReadConnectedWorkspaceViewUsecase.accessRequest(workspaceId, binding),
      );
  if (!ref.mounted) throw const WorkspaceTableException(denied: true);
  // A Connection or grant update invalidates this provider and drops its result.
  return (value: result, fetchedAt: DateTime.now());
}

@riverpod
Stream<Object?> workspaceConnectedAccess(Ref ref, String workspaceId) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (session.cloud != null) {
    if (gateway == null) throw const WorkspaceTableException(denied: true);
    yield* gateway.watchResources(const [
      WorkspaceResourceKind.tool,
      WorkspaceResourceKind.toolPermission,
      WorkspaceResourceKind.toolGroup,
      WorkspaceResourceKind.serviceConnection,
    ]);
    return;
  }
  final database = ref.watch(appDatabaseProvider);
  yield null;
  yield* database.tableUpdates(
    TableUpdateQuery.onAllTables([
      database.tools,
      database.toolsGroups,
      database.serviceConnections,
    ]),
  );
}

@riverpod
Future<List<ConnectorConnectionCandidate>> workspaceConnectedConnections(
  Ref ref,
  String workspaceId,
  String connectorId,
) async {
  final _ = ref.watch(serviceConnectionsProvider(workspaceId));
  final _ = ref.watch(workspaceConnectedAccessProvider(workspaceId));
  final connector = connectorDefinitions
      .where((item) => item.identifier == connectorId)
      .firstOrNull;
  if (connector == null) throw const WorkspaceTableException();

  return await ref
      .watch(listConnectorConnectionCandidatesUsecaseProvider)
      .forConnector(workspaceId: workspaceId, connector: connector);
}
