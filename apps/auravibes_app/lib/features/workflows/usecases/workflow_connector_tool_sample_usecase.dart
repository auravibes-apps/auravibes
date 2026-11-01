import 'dart:convert';

import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_connector_tool_sample_usecase.g.dart';

typedef WorkflowConnectorToolSampleRequest = ({
  String workspaceId,
  String toolId,
  String connectorId,
  String toolSlug,
  String revision,
  Map<String, dynamic> arguments,
  String? connectionId,
});

typedef WorkflowConnectorToolSampleRunner = Future<Object?> Function(
  WorkflowConnectorToolSampleRequest request,
);

class WorkflowConnectorToolSampleUsecase(
  final WorkflowConnectorToolSampleRunner _runner,
  final Iterable<ConnectorDefinition> _connectors,
) {
  Future<Object?> call({
    required String workspaceId,
    required String toolId,
    required Map<String, dynamic> arguments,
    required String? connectionId,
  }) async {
    for (final connector in _connectors) {
      for (final tool in connector.tools) {
        if (connectorToolId(connector, tool) != toolId ||
            tool.urlTemplate == null) {
          continue;
        }
        if (connectorToolWrites(tool)) {
          throw UnsupportedError('Write tools require a pasted sample.');
        }

        final sample = await _runner((
          workspaceId: workspaceId,
          toolId: toolId,
          connectorId: connector.identifier,
          toolSlug: tool.slug,
          revision: connectorToolRevision(connector, tool),
          arguments: arguments,
          connectionId: connectionId,
        ));

        return connectorToolSampleShape(sample);
      }
    }

    throw UnsupportedError('Unknown Connector tool: $toolId');
  }
}

@riverpod
Future<WorkflowConnectorToolSampleUsecase> workflowConnectorToolSampleUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final cloud = session.cloud;
  if (cloud == null) {
    final runner = ref.watch(runConnectorToolUsecaseProvider);

    return WorkflowConnectorToolSampleUsecase(
      (request) => runner.call((
        workspaceId: request.workspaceId,
        connectorId: request.connectorId,
        toolSlug: request.toolSlug,
        arguments: {
          ...request.arguments,
          'connectionId': ?request.connectionId,
        },
        operationId: '',
      )),
      connectorDefinitions,
    );
  }

  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (gateway == null) throw StateError('Cloud workspace is unavailable.');

  Future<Object?> runner(WorkflowConnectorToolSampleRequest request) async {
    final response = await gateway.client.connectorTool.sampleRead(
      cloud.cloudWorkspaceId,
      request.toolId,
      request.revision,
      jsonEncode(request.arguments),
      request.connectionId,
    );

    return jsonDecode(response);
  }

  return WorkflowConnectorToolSampleUsecase(runner, connectorDefinitions);
}
