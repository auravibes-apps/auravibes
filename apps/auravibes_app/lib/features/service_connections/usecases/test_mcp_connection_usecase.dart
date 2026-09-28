import 'dart:async';

import 'package:auravibes_app/data/repositories/mcp_servers_repository_contract.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_connection_test_result.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:auravibes_app/services/mcp_service/mcp_oauth_exception.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:dio/dio.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_mcp_connection_usecase.g.dart';

class const TestMcpConnectionUsecase({
  required final McpServersRepositoryContract repository,
  required final Future<McpAuthenticationType> Function(String?) authentication,
  required final McpManagerService manager,
  required final DateTime Function() clock,
}) {
  static const _timeout = Duration(seconds: 10);

  Future<McpConnectionTestResult> call(String serverId) async {
    final testedAt = clock();
    McpTransportType? transport;
    try {
      final server = await _requiredServer(serverId);
      transport = server.transport;

      return await _runConnectionTest(server, testedAt);
    } on Object catch (error) {
      return _failedResult(error, testedAt, transport);
    }
  }

  Future<McpConnectionTestResult> _runConnectionTest(
    McpServerEntity server,
    DateTime testedAt,
  ) async {
    final client = await _connect(server);
    try {
      await _discoverTools(client);
    } finally {
      await manager.disconnect(client);
    }

    return (
      status: McpConnectionTestStatus.success,
      testedAt: testedAt,
      transport: server.transport,
      errorDetails: null,
    );
  }

  Future<McpServerEntity> _requiredServer(String serverId) async {
    final server = await repository.getMcpServerById(serverId);
    if (server == null) throw const FormatException('MCP server not found.');

    return server;
  }

  Future<McpManagerClient> _connect(McpServerEntity server) async {
    final credentials = await authentication(server.serviceConnectionId);
    final pendingConnection = manager.connectMcp(
      server.copyWith(authenticationType: credentials),
    );

    return await pendingConnection.timeout(
      _timeout,
      onTimeout: () {
        unawaited(_disconnectAfterLateConnect(pendingConnection, manager));
        throw TimeoutException('MCP connection timed out.');
      },
    );
  }

  Future<void> _discoverTools(McpManagerClient client) async {
    final _ = await manager.getTools(client).timeout(_timeout);
  }
}

McpConnectionTestResult _failedResult(
  Object error,
  DateTime testedAt,
  McpTransportType? transport,
) => (
  status: _statusFor(error),
  testedAt: testedAt,
  transport: transport,
  errorDetails: LogRedaction.redact(error.toString()),
);

Future<void> _disconnectAfterLateConnect(
  Future<McpManagerClient> pendingConnection,
  McpManagerService manager,
) async {
  try {
    await manager.disconnect(await pendingConnection);
  } on Object {
    return;
  }
}

McpConnectionTestStatus _statusFor(Object error) {
  return switch (error) {
    TimeoutException() => .network,
    McpOAuthException(:final tokenExpired) =>
      tokenExpired ? .authentication : .protocol,
    DioException() => _dioStatus(error),
    mcp.McpError() => _mcpStatus(error),
    FormatException() => .protocol,
    _ => .unknown,
  };
}

McpConnectionTestStatus _dioStatus(DioException error) {
  if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
    return .authentication;
  }

  return switch (error.type) {
    .connectionTimeout ||
    .sendTimeout ||
    .receiveTimeout ||
    .connectionError => .network,
    _ => .protocol,
  };
}

McpConnectionTestStatus _mcpStatus(mcp.McpError error) {
  if (_isMcpAuthenticationFailure(error)) return .authentication;
  if (_isMcpNetworkFailure(error)) return .network;
  if (error.message.startsWith('Failed to connect after ')) {
    return _retryFailureStatus(error.message);
  }

  return .protocol;
}

bool _isMcpAuthenticationFailure(mcp.McpError error) =>
    const {
      -32001,
      -32104,
      -32120,
      -32121,
      -32122,
      -32123,
      -32124,
    }.contains(error.code) ||
    error.message.startsWith('Authentication failed:') ||
    error.message.startsWith('Authentication required');

bool _isMcpNetworkFailure(mcp.McpError error) =>
    const {-32115, -32130, -32131, -32161}.contains(error.code) ||
    error.message.startsWith('Transport error:') ||
    error.message.startsWith('Request timed out:');

McpConnectionTestStatus _retryFailureStatus(String message) {
  // Ponytail: SDK retries flatten causes; remove when SDK adds typed errors.
  if (message.contains('Authentication required') ||
      message.contains('Unauthorized')) {
    return .authentication;
  }
  if (message.contains('SocketException') ||
      message.contains('TimeoutException')) {
    return .network;
  }

  return .unknown;
}

@riverpod
Future<TestMcpConnectionUsecase> testMcpConnectionUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );

  return TestMcpConnectionUsecase(
    repository: ref.watch(mcpServersRepositoryProvider(session)),
    authentication: ref
        .watch(oauthCredentialServiceProvider)
        .resolveMcpAuthenticationForTest,
    manager: .new(),
    clock: DateTime.now,
  );
}
