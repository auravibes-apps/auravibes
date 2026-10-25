import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/workspace_state/usecases/workspace_connector_access_usecases.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

abstract final class WorkspaceConnectedValidation {
  static Map<String, dynamic> arguments(Object? value) {
    if (value is! Map ||
        value.keys.any(
          (key) =>
              !{'toolId', 'revision', 'connectionId', 'inputs'}.contains(key),
        )) {
      _invalid();
    }
    final toolId = value['toolId'];
    final revision = value['revision'];
    final inputs = value['inputs'];
    final connectionId = value['connectionId'];
    if (toolId is! String ||
        revision is! String ||
        revision.isEmpty ||
        inputs is! Map ||
        (connectionId != null && connectionId is! String)) {
      _invalid();
    }
    final arguments = Map<String, dynamic>.from(inputs);
    final resolved = resolveCloudConnectorTool(
      toolId: toolId,
      arguments: arguments,
      revision: revision,
    );
    if (connectorToolWrites(resolved.tool) ||
        (resolved.tool.requiresConnection &&
            (connectionId == null || connectionId.isEmpty))) {
      _invalid();
    }

    return {
      'toolId': toolId,
      'revision': revision,
      'args': arguments,
      'connectionId': ?connectionId,
    };
  }

  static Future<bool> visible(
    Session session,
    WorkspaceMember member,
    Object? value,
  ) async {
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
        );

        return true;
      }
    }

    return false;
  }

  static Future<void> access(
    Session session,
    WorkspaceMember member,
    Object? value,
  ) async {
    if (value == null) return;
    final input = arguments(value);
    await const ServerToolExecutorService().readConnectorAccess(
      session,
      workspaceId: member.workspaceId,
      userId: member.userId,
      arguments: input,
    );
  }
}

Never _invalid() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.validationFailed,
);
