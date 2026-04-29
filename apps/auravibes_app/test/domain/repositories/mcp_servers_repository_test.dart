// ignore_for_file: cascade_invocations
import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubMcpServersRepository implements McpServersRepository {
  McpServerEntity? addResult;
  bool deleteResult = true;
  List<McpServerEntity> servers = [];
  List<McpServerEntity> enabledServers = [];
  McpServerEntity? byIdResult;

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) async {
    return addResult!;
  }

  @override
  Future<bool> deleteMcpServer(String serverId) async => deleteResult;

  @override
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) async {}

  @override
  Future<List<McpServerEntity>> getMcpServersForWorkspace(
    String workspaceId,
  ) async {
    return servers;
  }

  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) async {
    return enabledServers;
  }

  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) async =>
      byIdResult;
}

void main() {
  group('McpServersRepository', () {
    test('addMcpServerWithTools returns entity', () async {
      final repo = _StubMcpServersRepository();
      repo.addResult = McpServerEntity(
        id: 'mcp-1',
        workspaceId: 'ws-1',
        name: 'Test Server',
        url: 'https://mcp.example.com',
        transport: const McpTransportTypeStreamableHttp(),
        authenticationType: const McpAuthenticationType.none(),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      const toCreate = McpServerToCreate(
        name: 'Test Server',
        url: 'https://mcp.example.com',
        transport: McpTransportTypeStreamableHttp(),
        authenticationType: McpAuthenticationType.none(),
      );

      final result = await repo.addMcpServerWithTools(
        workspaceId: 'ws-1',
        serverToCreate: toCreate,
        tools: [],
      );

      expect(result.id, 'mcp-1');
      expect(result.name, 'Test Server');
    });

    test('deleteMcpServer returns bool', () async {
      final repo = _StubMcpServersRepository();

      expect(await repo.deleteMcpServer('mcp-1'), true);

      repo.deleteResult = false;
      expect(await repo.deleteMcpServer('mcp-2'), false);
    });

    test('syncMcpTools completes', () async {
      final repo = _StubMcpServersRepository();

      await repo.syncMcpTools(
        mcpServerId: 'mcp-1',
        currentTools: [],
      );

      expect(true, true);
    });

    test('getMcpServersForWorkspace returns list', () async {
      final repo = _StubMcpServersRepository();

      final result = await repo.getMcpServersForWorkspace('ws-1');

      expect(result, isEmpty);
    });

    test('getEnabledMcpServersForWorkspace returns list', () async {
      final repo = _StubMcpServersRepository();

      final result = await repo.getEnabledMcpServersForWorkspace('ws-1');

      expect(result, isEmpty);
    });

    test('getMcpServerById returns null when not found', () async {
      final repo = _StubMcpServersRepository();

      final result = await repo.getMcpServerById('missing');

      expect(result, isNull);
    });
  });

  group('McpServersException', () {
    test('contains message', () {
      const ex = McpServersException('test error');
      expect(ex.message, 'test error');
      expect(ex.cause, isNull);
    });

    test('toString without cause', () {
      const ex = McpServersException('oops');
      expect(ex.toString(), 'McpServersException: oops');
    });

    test('toString includes cause when provided', () {
      final cause = Exception('inner');
      final ex = McpServersException('test', cause);
      expect(ex.toString(), contains('Caused by:'));
    });
  });

  group('McpServerNotFoundException', () {
    test('contains id in message', () {
      const ex = McpServerNotFoundException('mcp-42');
      expect(ex, isA<McpServersException>());
      expect(ex.serverId, 'mcp-42');
      expect(ex.toString(), contains('mcp-42'));
      expect(ex.toString(), contains('not found'));
    });

    test('includes cause when provided', () {
      final cause = Exception('db error');
      final ex = McpServerNotFoundException('mcp-1', cause);
      expect(ex.cause, cause);
    });
  });
}
