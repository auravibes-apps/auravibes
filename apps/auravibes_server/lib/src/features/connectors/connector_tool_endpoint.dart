import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/accounts/authenticated_account_resolver.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class ConnectorToolEndpoint extends Endpoint {
  ConnectorToolEndpoint({ServerToolExecutorService? executor})
    : _executor = executor ?? const ServerToolExecutorService();

  final ServerToolExecutorService _executor;

  Future<String> sampleRead(
    Session session,
    int workspaceId,
    String toolId,
    String revision,
    String argumentsJson,
    String? connectionId,
  ) async {
    if (utf8.encode(argumentsJson).length > 131072) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    final account = await const AuthenticatedAccountResolver()(session);
    final arguments = _sampleArguments(
      toolId: toolId,
      revision: revision,
      argumentsJson: argumentsJson,
      connectionId: connectionId,
    );

    try {
      await _executor.readConnectorAccess(
        session,
        workspaceId: workspaceId,
        userId: account.userId,
        arguments: arguments,
      );
      final result = await _executor.readConnector(
        session,
        workspaceId: workspaceId,
        userId: account.userId,
        arguments: arguments,
      );
      await _executor.readConnectorAccess(
        session,
        workspaceId: workspaceId,
        userId: account.userId,
        arguments: arguments,
      );

      return jsonEncode(connectorToolSampleShape(result));
    } on AgentToolExecutionFailure catch (failure) {
      throw WorkspaceConnectedReadException(code: _failureCode(failure));
    }
  }
}

Map<String, dynamic> _sampleArguments({
  required String toolId,
  required String revision,
  required String argumentsJson,
  required String? connectionId,
}) {
  Object? decoded;
  try {
    decoded = jsonDecode(argumentsJson);
  } on FormatException {
    throw CloudWorkspaceException(
      code: CloudWorkspaceErrorCode.validationFailed,
    );
  }
  if (toolId.isEmpty ||
      revision.isEmpty ||
      decoded is! Map ||
      decoded.keys.any((key) => key is! String)) {
    throw CloudWorkspaceException(
      code: CloudWorkspaceErrorCode.validationFailed,
    );
  }

  return {
    'toolId': toolId,
    'revision': revision,
    'args': Map<String, dynamic>.from(decoded),
    'connectionId': ?connectionId,
  };
}

String _failureCode(AgentToolExecutionFailure failure) {
  Object? code;
  try {
    final data = jsonDecode(failure.responseRaw) as Map<String, dynamic>;
    code = (data['error'] as Map?)?['code'];
  } on Object {
    return 'failed';
  }

  return switch (code) {
    'stale_contract' || 'invalid_tool_arguments' => 'repair',
    final String value when value.startsWith('connection_') => 'disconnected',
    'tool_access_denied' => 'denied',
    _ => 'failed',
  };
}
