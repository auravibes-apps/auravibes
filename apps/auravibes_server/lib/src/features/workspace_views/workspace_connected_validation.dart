import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/workspace_state/usecases/workspace_connector_access_usecases.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

abstract final class WorkspaceConnectedValidation {
  static Map<String, dynamic> arguments(Object? value) =>
      _executionArguments(_checked(_parse(value)));

  static Future<bool> visible(
    Session session,
    WorkspaceMember member,
    Object? value, {
    Transaction? transaction,
  }) async {
    if (value is! Map) return false;
    if (member.role == 'owner') return true;
    for (final connector in connectorDefinitions) {
      for (final tool in connector.tools) {
        if (connectorToolId(connector, tool) != value['toolId']) continue;
        await const WorkspaceConnectorAccessUsecases().requireEnabled(
          session,
          workspaceId: member.workspaceId,
          userId: member.userId,
          toolId: value['toolId'] as String,
          tool: tool,
          transaction: transaction,
        );

        return true;
      }
    }

    return false;
  }

  static Future<void> access(
    Session session,
    WorkspaceMember member,
    Object? value, {
    Transaction? transaction,
  }) async {
    if (value == null) return;
    final input = arguments(value);
    try {
      await const ServerToolExecutorService().readConnectorAccess(
        session,
        workspaceId: member.workspaceId,
        userId: member.userId,
        arguments: input,
        transaction: transaction,
      );
    } on AgentToolExecutionFailure {
      _invalid();
    }
  }
}

Never _invalid() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.validationFailed,
);

typedef _ConnectedBinding = ({
  String toolId,
  String revision,
  String? connectionId,
  Map<String, dynamic> inputs,
});
_ConnectedBinding _parse(Object? value) {
  final source = _source(value);

  return (
    toolId: _requiredString(source['toolId']),
    revision: _requiredString(source['revision']),
    connectionId: _connectionId(source['connectionId']),
    inputs: _inputs(source['inputs']),
  );
}

Map<String, Object?> _source(Object? value) {
  if (value is! Map || value.keys.any((key) => !_sourceKeys.contains(key))) {
    _invalid();
  }

  return Map<String, Object?>.from(value);
}

const _sourceKeys = {'toolId', 'revision', 'connectionId', 'inputs'};
String _requiredString(Object? value) {
  if (value is! String || value.isEmpty) _invalid();

  return value;
}

String? _connectionId(Object? value) =>
    value == null ? null : _requiredString(value);
Map<String, dynamic> _inputs(Object? value) {
  if (value is! Map) _invalid();

  return Map<String, dynamic>.from(value);
}

_ConnectedBinding _checked(_ConnectedBinding binding) {
  final target = resolveCloudConnectorTool(
    toolId: binding.toolId,
    arguments: binding.inputs,
    revision: binding.revision,
  );
  if (connectorToolWrites(target.tool) ||
      !_hasConnection(binding, target.tool)) {
    _invalid();
  }

  return binding;
}

bool _hasConnection(_ConnectedBinding binding, ConnectorToolDefinition tool) =>
    tool.requiresConnection
    ? binding.connectionId != null
    : binding.connectionId == null;
Map<String, dynamic> _executionArguments(_ConnectedBinding binding) => {
  'toolId': binding.toolId,
  'revision': binding.revision,
  'args': binding.inputs,
  'connectionId': ?binding.connectionId,
};
