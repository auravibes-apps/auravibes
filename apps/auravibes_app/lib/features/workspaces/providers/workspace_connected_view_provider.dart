import 'dart:convert';

import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/connector_command_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/read_connected_workspace_view_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart'
    show
        CloudWorkspaceException,
        WorkspaceConnectedReadException,
        WorkspaceResourceKind;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_connected_view_provider.g.dart';

typedef WorkspaceConnectedResult = ({Object? value, DateTime fetchedAt});

typedef _ViewKey = ({String workspaceId, String viewId});

@Riverpod(retry: _connectedRetry)
Future<WorkspaceConnectedResult> workspaceConnectedView(
  Ref ref,
  String workspaceId,
  String viewId,
) async {
  await _observeAccess(ref, workspaceId);
  _requireMounted(ref);
  final result = await _readSource(ref, (
    workspaceId: workspaceId,
    viewId: viewId,
  ));
  _requireMounted(ref);

  return (value: result, fetchedAt: DateTime.now());
}

Future<Object?> _readSource(Ref ref, _ViewKey key) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(key.workspaceId).future,
  );
  _requireMounted(ref);
  final binding = await _currentBinding(ref, key);
  _requireMounted(ref);

  return await _readForSession(ref, session, key, binding);
}

Future<WorkspaceConnectedBinding> _currentBinding(Ref ref, _ViewKey key) async {
  final data = await ref.watch(
    workspaceViewDataProvider(key.workspaceId, key.viewId).future,
  );
  final binding = data.view.connected;
  if (binding == null) throw const WorkspaceTableException();

  return binding;
}

Future<Object?> _readForSession(
  Ref ref,
  WorkspaceSession session,
  _ViewKey key,
  WorkspaceConnectedBinding binding,
) => session.cloud == null
    ? _localRead(ref, key.workspaceId, binding)
    : _cloudRead(ref, session, key.viewId);

Future<void> _observeAccess(Ref ref, String workspaceId) async {
  final access = ref.watch(workspaceConnectedAccessProvider(workspaceId));
  if (access.hasError) throw const WorkspaceTableException(denied: true);
  final _ = await ref.watch(
    workspaceConnectedAccessProvider(workspaceId).future,
  );
}

Future<Object?> _localRead(
  Ref ref,
  String workspaceId,
  WorkspaceConnectedBinding binding,
) async {
  final commands = ref.watch(connectorCommandUsecaseProvider);
  final result = await ReadConnectedWorkspaceViewUsecase(
    execute: (arguments) => _commandRead(commands, workspaceId, arguments),
  )(binding);
  _requireMounted(ref);
  await ref
      .read(runConnectorToolUsecaseProvider)
      .requireCurrent(
        ReadConnectedWorkspaceViewUsecase.accessRequest(workspaceId, binding),
      );

  return result;
}

Future<Object?> _commandRead(
  ConnectorCommandUsecase commands,
  String workspaceId,
  Map<String, dynamic> arguments,
) => commands.call(
  workspaceId: workspaceId,
  commandName: executeConnectorToolName,
  arguments: arguments,
);

Future<Object?> _cloudRead(
  Ref ref,
  WorkspaceSession session,
  String viewId,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  _requireMounted(ref);
  final cloud = session.cloud;
  if (gateway == null || cloud == null) {
    throw const WorkspaceTableException(denied: true);
  }
  final result = await gateway.client.workspaceView.readConnected(
    cloud.cloudWorkspaceId,
    viewId,
  );

  return jsonDecode(result);
}

void _requireMounted(Ref ref) {
  if (!ref.mounted) throw const WorkspaceTableException(denied: true);
}

@riverpod
Stream<Object?> workspaceConnectedAccess(Ref ref, String workspaceId) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  _requireMounted(ref);
  if (session.cloud == null) {
    yield* _localAccessChanges(ref);

    return;
  }
  yield* _cloudAccessChanges(ref, session);
}

Stream<Object?> _cloudAccessChanges(Ref ref, WorkspaceSession session) async* {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (gateway == null) throw const WorkspaceTableException(denied: true);
  yield* gateway.watchResources(const [
    WorkspaceResourceKind.tool,
    WorkspaceResourceKind.toolPermission,
    WorkspaceResourceKind.toolGroup,
    WorkspaceResourceKind.serviceConnection,
    WorkspaceResourceKind.modelConnection,
  ]);
}

Stream<Object?> _localAccessChanges(Ref ref) async* {
  final database = ref.watch(appDatabaseProvider);
  yield null;
  yield* database.tableUpdates(
    .onAllTables([
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
  final connector = _connector(connectorId);

  return await ref
      .watch(listConnectorConnectionCandidatesUsecaseProvider)
      .forConnector(workspaceId: workspaceId, connector: connector);
}

Duration? _connectedRetry(int attempt, Object error) => switch (error) {
  WorkspaceTableException() ||
  CloudWorkspaceException() ||
  WorkspaceConnectedReadException() ||
  AgentToolExecutionFailure() => null,
  _ => ProviderContainer.defaultRetry(attempt, error),
};

ConnectorDefinition _connector(String id) {
  final value = connectorDefinitions
      .where((item) => item.identifier == id)
      .firstOrNull;
  if (value == null) throw const WorkspaceTableException();

  return value;
}
