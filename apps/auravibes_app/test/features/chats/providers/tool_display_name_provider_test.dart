
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeMcpServersRepository implements McpServersRepository {
  _FakeMcpServersRepository(this._servers);
  final Map<String, McpServerEntity> _servers;

  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) async =>
      _servers[serverId];

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteMcpServer(String serverId) {
    throw UnimplementedError();
  }

  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<McpServerEntity>> getMcpServersForWorkspace(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('toolDisplayNameProvider', () {
    test('returns display name for MCP tool with server name', () async {
      final server = McpServerEntity(
        id: 'srv1',
        workspaceId: 'ws1',
        name: 'My Server',
        url: 'https://example.com',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final container = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(
            _FakeMcpServersRepository({'srv1': server}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('mcp_srv1_myserver_read_file').future,
      );
      expect(name, 'My Server: Read File');
    });

    test('returns display name for built-in tool', () async {
      final container = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(
            _FakeMcpServersRepository({}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('built_in_123_calculator').future,
      );
      expect(name, 'Calculator');
    });

    test('returns display name for native tool', () async {
      final container = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(
            _FakeMcpServersRepository({}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('native_456_read_file').future,
      );
      expect(name, 'Read File');
    });

    test('falls back to raw name for unknown format', () async {
      final container = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(
            _FakeMcpServersRepository({}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('unknown_tool').future,
      );
      expect(name, 'Unknown Tool');
    });

    test('falls back to slug when server not found', () async {
      final container = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(
            _FakeMcpServersRepository({}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final name = await container.read(
        toolDisplayNameProvider('mcp_missing_myserver_do_stuff').future,
      );
      expect(name, 'Myserver: Do Stuff');
    });
  });

  group('mcpServerNameProvider', () {
    test('returns null when server not found', () async {
      final container = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(
            _FakeMcpServersRepository({}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final name = await container.read(
        mcpServerNameProvider('nonexistent').future,
      );
      expect(name, isNull);
    });

    test('returns server name when found', () async {
      final server = McpServerEntity(
        id: 'srv1',
        workspaceId: 'ws1',
        name: 'Test Server',
        url: 'https://example.com',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final container = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(
            _FakeMcpServersRepository({'srv1': server}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final name = await container.read(
        mcpServerNameProvider('srv1').future,
      );
      expect(name, 'Test Server');
    });
  });
}
