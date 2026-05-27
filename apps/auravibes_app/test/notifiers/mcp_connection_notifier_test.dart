// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

// ignore_for_file: cascade_invocations
import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

final _server = McpServerEntity(
  id: 'server-1',
  workspaceId: 'workspace-1',
  name: 'Test Server',
  url: 'https://example.com',
  transport: const McpTransportTypeSSE(),
  authenticationType: const McpAuthenticationTypeNone(),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _server2 = McpServerEntity(
  id: 'server-2',
  workspaceId: 'workspace-1',
  name: 'Another Server',
  url: 'https://example.org',
  transport: const McpTransportTypeSSE(),
  authenticationType: const McpAuthenticationTypeNone(),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const _toolInfo = McpToolInfo(
  toolName: 'sum',
  description: 'Sum numbers',
  inputSchema: {},
);

McpConnectionState _connectedState({
  McpManagerClient? client,
  List<McpToolInfo> tools = const [],
}) {
  return McpConnectionState(
    server: _server,
    status: McpConnectionStatus.connected,
    client: client,
    tools: tools,
  );
}

void main() {
  group('McpToolIdComponents', () {
    group('fromComposite', () {
      test('parses valid composite ID', () {
        final result = McpToolIdComponents.fromComposite(
          'mcp_abc123_myserver_read_file',
        );
        expect(result, isNotNull);
        expect(result!.mcpServerId, 'abc123');
        expect(result.slugName, 'myserver');
        expect(result.toolIdentifier, 'read_file');
      });

      test('returns null for non-mcp prefix', () {
        expect(
          McpToolIdComponents.fromComposite('built_in_123_tool'),
          isNull,
        );
      });

      test('returns null when no underscores after prefix', () {
        expect(
          McpToolIdComponents.fromComposite('mcp_nounderscore'),
          isNull,
        );
      });

      test('returns null when only one underscore after prefix', () {
        expect(
          McpToolIdComponents.fromComposite('mcp_id_onlyslug'),
          isNull,
        );
      });

      test('returns null for empty parts', () {
        expect(
          McpToolIdComponents.fromComposite('mcp__slug_tool'),
          isNull,
        );
      });

      test('returns null for empty slug', () {
        expect(
          McpToolIdComponents.fromComposite('mcp_id__tool'),
          isNull,
        );
      });

      test('returns null for empty tool identifier', () {
        expect(
          McpToolIdComponents.fromComposite('mcp_id_slug_'),
          isNull,
        );
      });

      test('parses composite ID with underscores in tool name', () {
        final result = McpToolIdComponents.fromComposite(
          'mcp_abc_myserver_read_file_name',
        );
        expect(result, isNotNull);
        expect(result!.mcpServerId, 'abc');
        expect(result.slugName, 'myserver');
        expect(result.toolIdentifier, 'read_file_name');
      });
    });
  });

  group('McpConnectionState', () {
    test('isReady returns false when no client', () {
      final state = McpConnectionState(
        server: _server,
        status: McpConnectionStatus.connected,
      );
      expect(state.isReady, isFalse);
    });

    test('isReady returns false when connecting', () {
      final state = McpConnectionState(
        server: _server,
        status: McpConnectionStatus.connecting,
      );
      expect(state.isReady, isFalse);
    });

    test('isReady returns false when disconnected', () {
      final state = McpConnectionState(
        server: _server,
        status: McpConnectionStatus.disconnected,
      );
      expect(state.isReady, isFalse);
    });

    test('isReady returns false when error', () {
      final state = McpConnectionState(
        server: _server,
        status: McpConnectionStatus.error,
        errorMessage: 'fail',
      );
      expect(state.isReady, isFalse);
    });

    test('hasTools returns true when tools present', () {
      final state = McpConnectionState(
        server: _server,
        status: McpConnectionStatus.connected,
        tools: [_toolInfo],
      );
      expect(state.hasTools, isTrue);
    });

    test('hasTools returns false when no tools', () {
      final state = McpConnectionState(
        server: _server,
        status: McpConnectionStatus.connected,
      );
      expect(state.hasTools, isFalse);
    });
  });

  group('McpConnectionNotifier', () {
    late _FakeMcpServersRepository mcpServersRepository;
    late McpManagerService mcpManagerService;
    late ProviderContainer container;

    setUp(() {
      mcpServersRepository = _FakeMcpServersRepository();
      mcpManagerService = McpManagerService();
      container = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(mcpManagerService),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('initial state is empty list', () {
      final state = container.read(mcpConnectionProvider);
      expect(state, isEmpty);
    });

    test('getConnection returns null for missing server', () {
      final notifier = container.read(mcpConnectionProvider.notifier);
      expect(notifier.getConnection('nonexistent'), isNull);
    });

    test('getConnection returns state for existing server', () {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
          ),
        ];
      final conn = notifier.getConnection('server-1');
      expect(conn, isNotNull);
      expect(conn!.server.id, 'server-1');
    });

    test('getMcpConnectionTimeout returns 10 seconds', () {
      final notifier = container.read(mcpConnectionProvider.notifier);
      expect(
        notifier.getMcpConnectionTimeout(),
        const Duration(seconds: 10),
      );
    });

    test(
      'waitForConnectionsReady returns immediately for empty list',
      () async {
        final notifier = container.read(mcpConnectionProvider.notifier);

        final sw = Stopwatch()..start();
        await notifier.waitForConnectionsReady(mcpServerIds: const []);
        sw.stop();
        expect(sw.elapsed, lessThan(const Duration(milliseconds: 100)));
      },
    );

    test(
      'waitForConnectionsReady returns immediately with zero duration',
      () async {
        container.read(mcpConnectionProvider.notifier).state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
          ),
        ];

        final notifier = container.read(mcpConnectionProvider.notifier);
        final sw = Stopwatch()..start();
        await notifier.waitForConnectionsReady(
          mcpServerIds: const ['server-1'],
          timeout: Duration.zero,
        );
        sw.stop();
        expect(sw.elapsed, lessThan(const Duration(milliseconds: 50)));
      },
    );

    test(
      'waitForConnectionsReady returns immediately when not connecting',
      () async {
        container.read(mcpConnectionProvider.notifier).state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
          ),
        ];

        final notifier = container.read(mcpConnectionProvider.notifier);
        final sw = Stopwatch()..start();
        await notifier.waitForConnectionsReady(
          mcpServerIds: const ['server-1'],
          timeout: const Duration(seconds: 5),
        );
        sw.stop();
        expect(sw.elapsed, lessThan(const Duration(milliseconds: 100)));
      },
    );

    test('waitForConnectionsReady honors timeout', () async {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connecting,
          ),
        ];

      final sw = Stopwatch()..start();
      await notifier.waitForConnectionsReady(
        mcpServerIds: const ['server-1'],
        timeout: const Duration(milliseconds: 50),
      );
      sw.stop();
      expect(
        sw.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 50)),
      );
      expect(sw.elapsed, lessThan(const Duration(milliseconds: 500)));
    });

    test('waitForConnectionsReady resolves when status changes', () async {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connecting,
          ),
        ];

      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 20), () {
          notifier.state = [
            McpConnectionState(
              server: _server,
              status: McpConnectionStatus.connected,
            ),
          ];
        }),
      );

      final sw = Stopwatch()..start();
      await notifier.waitForConnectionsReady(
        mcpServerIds: const ['server-1'],
        timeout: const Duration(milliseconds: 200),
      );
      sw.stop();
      expect(sw.elapsed, lessThan(const Duration(milliseconds: 150)));
    });

    test('getConnectingServers filters by status', () {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connecting,
          ),
          McpConnectionState(
            server: _server2,
            status: McpConnectionStatus.connected,
          ),
        ];

      final connecting = notifier.getConnectingServers(const [
        'server-1',
        'server-2',
      ]);
      expect(connecting.length, 1);
      expect(connecting.firstOrNull?.server.id, 'server-1');
    });

    test('getConnectingServers returns empty when none match', () {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
          ),
        ];

      final connecting = notifier.getConnectingServers(const ['server-1']);
      expect(connecting, isEmpty);
    });

    test('callTool throws when server not found', () async {
      final notifier = container.read(mcpConnectionProvider.notifier);
      await expectLater(
        notifier.callTool(
          mcpServerId: 'server-1',
          toolIdentifier: 'sum',
          arguments: const {},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('getToolSpec returns null when server not connected', () {
      final notifier = container.read(mcpConnectionProvider.notifier);
      expect(
        notifier.getToolSpec(mcpServerId: 'server-1', toolName: 'sum'),
        isNull,
      );
    });

    test('getToolSpec returns null when tool not found', () {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
            tools: [_toolInfo],
          ),
        ];

      expect(
        notifier.getToolSpec(mcpServerId: 'server-1', toolName: 'missing'),
        isNull,
      );
    });

    test('getToolSpec returns null when no client (not isReady)', () {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
            tools: const [_toolInfo],
          ),
        ];

      expect(
        notifier.getToolSpec(mcpServerId: 'server-1', toolName: 'sum'),
        isNull,
      );
    });

    test('disconnectMcpServer sets disconnected and clears client', () {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          _connectedState(),
        ];

      notifier.disconnectMcpServer('server-1');

      final state = container.read(mcpConnectionProvider);
      expect(state.length, 1);
      expect(state.firstOrNull?.status, McpConnectionStatus.disconnected);
      expect(state.firstOrNull?.client, isNull);
    });

    test('disconnectMcpServer does nothing for missing server', () {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          _connectedState(),
        ];

      notifier.disconnectMcpServer('nonexistent');

      final state = container.read(mcpConnectionProvider);
      expect(state.length, 1);
      expect(state.firstOrNull?.status, McpConnectionStatus.connected);
    });

    test('deleteMcpServer removes from state and database', () async {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.disconnected,
          ),
          McpConnectionState(
            server: _server2,
            status: McpConnectionStatus.connected,
          ),
        ];

      await notifier.deleteMcpServer('server-1');

      final state = container.read(mcpConnectionProvider);
      expect(state.length, 1);
      expect(state.firstOrNull?.server.id, 'server-2');
      expect(mcpServersRepository.deletedIds, ['server-1']);
    });

    test('deleteMcpServer works for server not in state', () async {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
          ),
        ];

      await notifier.deleteMcpServer('server-2');

      final state = container.read(mcpConnectionProvider);
      expect(state.length, 1);
      expect(mcpServersRepository.deletedIds, ['server-2']);
    });

    test(
      'reconnectMcpServer does nothing when server not in state or db',
      () async {
        final notifier = container.read(mcpConnectionProvider.notifier);
        await notifier.reconnectMcpServer('nonexistent');

        final state = container.read(mcpConnectionProvider);
        expect(state, isEmpty);
      },
    );

    test(
      'callTool throws descriptive message for missing server',
      () async {
        final notifier = container.read(mcpConnectionProvider.notifier);

        try {
          final _ = await notifier.callTool(
            mcpServerId: 'missing',
            toolIdentifier: 'sum',
            arguments: const {},
          );
          fail('Should have thrown');
        } on Exception catch (e) {
          expect(e.toString(), contains('MCP server not found'));
        }
      },
    );

    test(
      'callTool throws descriptive message for not connected',
      () async {
        final notifier = container.read(mcpConnectionProvider.notifier)
          ..state = [
            McpConnectionState(
              server: _server,
              status: McpConnectionStatus.disconnected,
            ),
          ];

        try {
          final _ = await notifier.callTool(
            mcpServerId: 'server-1',
            toolIdentifier: 'sum',
            arguments: const {},
          );
          fail('Should have thrown');
        } on Exception catch (e) {
          expect(e.toString(), contains('MCP server not connected'));
        }
      },
    );

    test('reconnectMcpServer with server in state handles error', () async {
      final fakeService = _FailingMcpManagerService();
      final testContainer = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(testContainer.dispose);

      final notifier = testContainer.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.disconnected,
          ),
        ];

      await notifier.reconnectMcpServer('server-1');

      final state = testContainer.read(mcpConnectionProvider);
      expect(state.length, 1);
      expect(state.firstOrNull?.status, McpConnectionStatus.error);
    });

    test('reconnectMcpServer loads from repo when not in state', () async {
      mcpServersRepository.serverById = _server2;
      final fakeService = _FailingMcpManagerService();
      final testContainer = ProviderContainer(
        overrides: [
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(testContainer.dispose);

      final notifier = testContainer.read(mcpConnectionProvider.notifier);

      await notifier.reconnectMcpServer('server-2');

      final state = testContainer.read(mcpConnectionProvider);
      expect(state.length, 1);
      expect(state.firstOrNull?.status, McpConnectionStatus.error);
      expect(state.firstOrNull?.server.id, 'server-2');
    });

    test('dispose cleans up connections', () async {
      container.read(mcpConnectionProvider.notifier).state = [
        McpConnectionState(
          server: _server,
          status: McpConnectionStatus.connected,
        ),
      ];

      expect(container.read(mcpConnectionProvider), hasLength(1));
      container.dispose();
    });

    test('callTool throws when tool not found on connected server', () async {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
            tools: const [_toolInfo],
          ),
        ];

      await expectLater(
        notifier.callTool(
          mcpServerId: 'server-1',
          toolIdentifier: 'missing_tool',
          arguments: const {},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('McpToolIdComponents handles first underscore at position 0', () {
      expect(
        McpToolIdComponents.fromComposite('mcp_'),
        isNull,
      );
    });

    test('McpToolIdComponents handles second underscore at position 0', () {
      expect(
        McpToolIdComponents.fromComposite('mcp_abc_'),
        isNull,
      );
    });

    test('reconnectMcpServer with server not in db returns empty', () async {
      mcpServersRepository.serverById = null;
      final notifier = container.read(mcpConnectionProvider.notifier);

      await notifier.reconnectMcpServer('nonexistent');

      final state = container.read(mcpConnectionProvider);
      expect(state, isEmpty);
    });

    test('disconnectMcpServer for missing server is no-op', () async {
      final notifier = container.read(mcpConnectionProvider.notifier);
      notifier.disconnectMcpServer('nonexistent');

      final state = container.read(mcpConnectionProvider);
      expect(state, isEmpty);
    });
  });
}

class _FakeMcpServersRepository implements McpServersRepository {
  List<String> deletedIds = [];
  McpServerEntity? serverById;

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteMcpServer(String serverId) async {
    deletedIds.add(serverId);
    return true;
  }

  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) async => const [];

  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) async =>
      serverById;

  @override
  Future<List<McpServerEntity>> getMcpServersForWorkspace(
    String workspaceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  }) async {}
}

class _FailingMcpManagerService extends McpManagerService {
  @override
  Future<McpManagerClient> connectMcp(McpServerToCreate serverInfo) async {
    throw Exception('Connection refused');
  }
}
