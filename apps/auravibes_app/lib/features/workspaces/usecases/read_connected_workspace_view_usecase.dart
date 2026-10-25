import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart'
    show ConnectorToolExecutionRequest;
import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ReadConnectedWorkspaceViewUsecase({
  required final Future<Object?> Function(Map<String, dynamic>) execute,
  final List<ConnectorDefinition>? connectors,
}) {
  Future<Object?> call(WorkspaceConnectedBinding binding) {
    validate(binding, connectors: connectors);

    return execute(binding.executionArguments());
  }

  static ConnectorToolExecutionRequest accessRequest(
    String workspaceId,
    WorkspaceConnectedBinding binding,
  ) {
    validate(binding);
    for (final connector in connectorDefinitions) {
      for (final tool in connector.tools) {
        if (connectorToolId(connector, tool) != binding.toolId) continue;

        return (
          workspaceId: workspaceId,
          connectorId: connector.identifier,
          toolSlug: tool.slug,
          arguments: {
            ...binding.inputs,
            if (binding.connectionId != null)
              'connectionId': binding.connectionId,
          },
          operationId: '',
        );
      }
    }
    throw const WorkspaceTableException();
  }

  static void validate(
    WorkspaceConnectedBinding binding, {
    List<ConnectorDefinition>? connectors,
  }) {
    for (final connector in connectors ?? connectorDefinitions) {
      for (final tool in connector.tools) {
        if (connectorToolId(connector, tool) != binding.toolId) continue;
        if (tool.urlTemplate == null ||
            connectorToolWrites(tool) ||
            connectorToolRevision(connector, tool) != binding.revision ||
            (tool.requiresConnection && binding.connectionId == null)) {
          throw const WorkspaceTableException();
        }
        validateToolArguments(
          Map<String, Object?>.from(tool.inputJsonSchema),
          binding.inputs,
        );
        return;
      }
    }
    throw const WorkspaceTableException();
  }
}
