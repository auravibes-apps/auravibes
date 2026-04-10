import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/providers/mcp_connection_controller.dart';
import 'package:auravibes_app/services/mcp_service/mcp_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('McpConnectionController', () {
    late _FakeSelectedWorkspace selectedWorkspace;
    late _FakeMcpServersRepository mcpServersRepository;
    late _FakeMcpManagerService mcpManagerService;
    late ProviderContainer container;

    setUp(() {
      selectedWorkspace = _FakeSelectedWorkspace(_workspace);
      mcpServersRepository = _FakeMcpServersRepository();
      mcpManagerService = _FakeMcpManagerService();
      container = ProviderContainer(
        overrides: [
          selectedWorkspaceProvider.overrideWith(() => selectedWorkspace),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(mcpManagerService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('waitForConnectionsReady honors sub-second timeout values', () async {
      final notifier = container.read(mcpConnectionControllerProvider.notifier)
        ..state = [_connectingState];

      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 20), () {
          notifier.state = [
            _connectingState.copyWith(status: McpConnectionStatus.connected),
          ];
        }),
      );

      final stopwatch = Stopwatch()..start();
      await notifier.waitForConnectionsReady(
        mcpServerIds: const ['server-1'],
        timeout: const Duration(milliseconds: 50),
      );
      stopwatch.stop();

      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 20)),
      );
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 500)),
      );
    });

    test(
      'waitForConnectionsReady returns close to timeout when never ready',
      () async {
        final notifier = container.read(
          mcpConnectionControllerProvider.notifier,
        )..state = [_connectingState];

        final stopwatch = Stopwatch()..start();
        await notifier.waitForConnectionsReady(
          mcpServerIds: const ['server-1'],
          timeout: const Duration(milliseconds: 50),
        );
        stopwatch.stop();

        expect(
          stopwatch.elapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 50)),
        );
        expect(
          stopwatch.elapsed,
          lessThan(const Duration(milliseconds: 500)),
        );
      },
    );

    test('callTool throws when server is missing', () async {
      final notifier = container.read(mcpConnectionControllerProvider.notifier);

      await expectLater(
        notifier.callTool(
          mcpServerId: 'missing',
          toolIdentifier: 'sum',
          arguments: const {},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('callTool throws when server is not connected', () async {
      final notifier = container.read(mcpConnectionControllerProvider.notifier)
        ..state = [
          _connectingState.copyWith(status: McpConnectionStatus.disconnected),
        ];

      await expectLater(
        notifier.callTool(
          mcpServerId: 'server-1',
          toolIdentifier: 'sum',
          arguments: const {},
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}

final _workspace = WorkspaceEntity(
  id: 'workspace-1',
  name: 'Workspace',
  type: WorkspaceType.local,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _server = McpServerEntity(
  id: 'server-1',
  workspaceId: 'workspace-1',
  name: 'Server',
  url: 'https://example.com',
  transport: const McpTransportTypeSSE(),
  authenticationType: const McpAuthenticationTypeNone(),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _connectingState = McpConnectionState(
  server: _server,
  status: McpConnectionStatus.connecting,
  tools: const [
    McpToolInfo(
      toolName: 'sum',
      description: 'Sum numbers',
      inputSchema: {},
    ),
  ],
);

class _FakeSelectedWorkspace extends SelectedWorkspace {
  _FakeSelectedWorkspace(this.workspace);

  final WorkspaceEntity workspace;

  @override
  Future<WorkspaceEntity> build() async => workspace;
}

class _FakeMcpManagerService extends McpManagerService {}

class _FakeMcpServersRepository implements McpServersRepository {
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
  ) async {
    return const [];
  }

  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) {
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
