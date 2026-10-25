import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart'
    show ConnectorToolExecutionRequest;
import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef _ReadTarget = ({
  ConnectorDefinition connector,
  ConnectorToolDefinition tool,
});

class const ReadConnectedWorkspaceViewUsecase({
  required final Future<Object?> Function(Map<String, dynamic>) execute,
  final List<ConnectorDefinition>? connectors,
}) {
  Future<Object?> call(WorkspaceConnectedBinding binding) {
    final _ = validate(binding, connectors: connectors);

    return execute(binding.executionArguments());
  }

  static ConnectorToolExecutionRequest accessRequest(
    String workspaceId,
    WorkspaceConnectedBinding binding,
  ) {
    final target = validate(binding);

    return (
      workspaceId: workspaceId,
      connectorId: target.connector.identifier,
      toolSlug: target.tool.slug,
      arguments: _inputs(binding),
      operationId: '',
    );
  }

  static ({ConnectorDefinition connector, ConnectorToolDefinition tool})
  validate(
    WorkspaceConnectedBinding binding, {
    List<ConnectorDefinition>? connectors,
  }) {
    final target = _target(binding.toolId, connectors ?? connectorDefinitions);
    _requireReadContract(binding, target);
    _validateInputs(binding, target.tool);

    return target;
  }
}

Map<String, dynamic> _inputs(WorkspaceConnectedBinding binding) => {
  ...binding.inputs,
  if (binding.connectionId != null) 'connectionId': binding.connectionId,
};
_ReadTarget _target(String id, Iterable<ConnectorDefinition> connectors) {
  for (final connector in connectors) {
    final tool = _findTool(connector, id);
    if (tool != null) return (connector: connector, tool: tool);
  }
  throw const WorkspaceTableException();
}

ConnectorToolDefinition? _findTool(ConnectorDefinition connector, String id) =>
    connector.tools
        .where((tool) => connectorToolId(connector, tool) == id)
        .firstOrNull;
void _requireReadContract(
  WorkspaceConnectedBinding binding,
  _ReadTarget target,
) {
  final tool = target.tool;
  if (tool.urlTemplate == null ||
      connectorToolWrites(tool) ||
      connectorToolRevision(target.connector, tool) != binding.revision ||
      !_hasConnection(binding, tool)) {
    throw const WorkspaceTableException();
  }
}

bool _hasConnection(
  WorkspaceConnectedBinding binding,
  ConnectorToolDefinition tool,
) => tool.requiresConnection
    ? binding.connectionId?.isNotEmpty == true
    : binding.connectionId == null;
void _validateInputs(
  WorkspaceConnectedBinding binding,
  ConnectorToolDefinition tool,
) {
  try {
    validateToolArguments(
      Map<String, Object?>.from(tool.inputJsonSchema),
      binding.inputs,
    );
  } on FormatException catch (_, stack) {
    Error.throwWithStackTrace(const WorkspaceTableException(), stack);
  }
}
