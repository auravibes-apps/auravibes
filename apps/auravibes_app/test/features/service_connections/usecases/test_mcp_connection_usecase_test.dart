import 'dart:async';

import 'package:auravibes_app/data/repositories/mcp_servers_repository_contract.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_connection_diagnostic_report.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_connection_test_result.dart';
import 'package:auravibes_app/features/service_connections/usecases/test_mcp_connection_usecase.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;
import 'package:mocktail/mocktail.dart';

void main() {
  final attemptedAt = DateTime.utc(2026, 9, 27, 12, 30);

  test(
    'connects, discovers, and disconnects without invoking a tool',
    () async {
      final fixture = _createFixture(attemptedAt);
      final repository = fixture.repository;
      final manager = fixture.manager;
      final usecase = fixture.usecase;
      final authenticationCalls = fixture.authenticationCalls;
      final result = await usecase('server');

      expect(result.status, McpConnectionTestStatus.success);
      expect(result.testedAt, attemptedAt);
      expect(result.transport, isA<McpTransportTypeStreamableHttp>());
      expect(authenticationCalls, ['credential']);
      expect(manager.calls, ['connect', 'list', 'disconnect']);
      expect(manager.toolCalls, 0);
      expect(
        manager.connectedServer?.authenticationType,
        isA<McpAuthenticationTypeBearerToken>(),
      );
      final _ = verifyNever(
        () => repository.syncMcpTools(
          mcpServerId: any(named: 'mcpServerId'),
          currentTools: any(named: 'currentTools'),
        ),
      );
    },
  );

  test(
    'classifies authentication, network, protocol, and unknown failures',
    () async {
      final fixture = _createFixture(attemptedAt);
      final manager = fixture.manager;
      final usecase = fixture.usecase;
      final failures =
          <({void Function() fail, McpConnectionTestStatus expected})>[
            (
              fail: () => throw const mcp.McpError(
                'Authentication required',
                code: -32001,
              ),
              expected: McpConnectionTestStatus.authentication,
            ),
            (
              fail: () => throw TimeoutException('MCP timed out'),
              expected: McpConnectionTestStatus.network,
            ),
            (
              fail: () => throw const mcp.McpError(
                'Failed to connect after 3 attempts: SocketException',
              ),
              expected: McpConnectionTestStatus.network,
            ),
            (
              fail: () => throw const mcp.McpError(
                'Failed to connect after 3 attempts: Authentication required',
              ),
              expected: McpConnectionTestStatus.authentication,
            ),
            (
              fail: () => throw const FormatException('Invalid MCP response'),
              expected: McpConnectionTestStatus.protocol,
            ),
            (
              fail: () => throw StateError('Unexpected response'),
              expected: McpConnectionTestStatus.unknown,
            ),
          ];

      for (final (:fail, :expected) in failures) {
        manager
          ..calls.clear()
          ..connectFailure = fail;
        final result = await usecase('server');

        expect(result.status, expected);
        expect(manager.calls, ['connect']);
        expect(manager.toolCalls, 0);
      }
    },
  );

  test('closes temporary client when discovery fails', () async {
    final fixture = _createFixture(attemptedAt);
    final manager = fixture.manager;
    final usecase = fixture.usecase;
    manager.listFailure = () =>
        throw const FormatException('Invalid tools/list response');

    final result = await usecase('server');

    expect(result.status, McpConnectionTestStatus.protocol);
    expect(manager.calls, ['connect', 'list', 'disconnect']);
  });

  test('diagnostic report includes useful fields but no raw error content', () {
    final McpConnectionTestResult result = (
      status: McpConnectionTestStatus.network,
      testedAt: attemptedAt,
      transport: const McpTransportTypeStreamableHttp(),
      errorDetails:
          'https://mcp.example.com/path?api_key=secret Authorization: Bearer secret '
          'arguments={"message":"private conversation"}',
    );
    final report = McpConnectionDiagnosticReport.fromTest(result).format(
      appVersion: '0.0.4',
      localizedSummary: 'MCP network or timeout failure',
      labels: (
        transport: 'Transport',
        category: 'Status category',
        attemptedAt: 'Attempt time',
        appVersion: 'App version',
        summary: 'Summary',
        unavailable: 'Not recorded',
      ),
    );

    expect(report, contains('Transport: streamableHttp'));
    expect(report, contains('Status category: network'));
    expect(report, contains('Attempt time: 2026-09-27T12:30:00.000Z'));
    expect(report, contains('App version: 0.0.4'));
    expect(report, contains('Summary: MCP network or timeout failure'));
    for (final secret in [
      'mcp.example.com',
      'secret',
      'Authorization',
      'arguments',
      'private conversation',
    ]) {
      expect(report, isNot(contains(secret)));
    }
  });
}

({
  _Repository repository,
  _Manager manager,
  TestMcpConnectionUsecase usecase,
  List<String> authenticationCalls,
})
_createFixture(DateTime attemptedAt) {
  final repository = _Repository();
  final manager = _Manager();
  final authenticationCalls = <String>[];
  when(() => repository.getMcpServerById('server')).thenAnswer(
    (_) async => McpServerEntity(
      id: 'server',
      workspaceId: 'workspace',
      name: 'MCP',
      url: 'https://mcp.example.com/path?api_key=secret',
      transport: const McpTransportTypeStreamableHttp(),
      authenticationType: const McpAuthenticationType.none(),
      createdAt: attemptedAt,
      updatedAt: attemptedAt,
      serviceConnectionId: 'credential',
    ),
  );
  final usecase = TestMcpConnectionUsecase(
    repository: repository,
    authentication: (id) async {
      if (id case final credentialId?) {
        authenticationCalls.add(credentialId);
      }
      expect(id, 'credential');

      return const McpAuthenticationType.bearerToken(bearerToken: 'secret');
    },
    manager: manager,
    clock: () => attemptedAt,
  );

  return (
    repository: repository,
    manager: manager,
    usecase: usecase,
    authenticationCalls: authenticationCalls,
  );
}

class _Repository extends Mock implements McpServersRepositoryContract {
  new();
}

class _Manager extends McpManagerService {
  final calls = <String>[];
  McpServerToCreate? connectedServer;
  void Function()? connectFailure;
  void Function()? listFailure;
  int toolCalls = 0;
  final _client = _Client();

  @override
  Future<McpManagerClient> connectMcp(McpServerToCreate serverInfo) async {
    calls.add('connect');
    connectedServer = serverInfo;
    connectFailure?.call();

    return _client;
  }

  @override
  Future<List<McpToolInfo>> getTools(McpManagerClient client) async {
    calls.add('list');
    listFailure?.call();

    return const [];
  }

  @override
  Future<void> disconnect(McpManagerClient? client) async {
    calls.add('disconnect');
  }

  @override
  Future<String> callToolString(
    McpManagerClient client, {
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    toolCalls++;

    return '';
  }
}

class _Client extends Mock implements McpManagerClient {
  new();
}
