// Required: Existing test and UI helpers keep compact return flow.

// ignore_for_file: cascade_invocations
import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
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
        expect(
          (result ?? fail('Expected result to be non-null')).mcpServerId,
          'abc123',
        );
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
        expect(
          (result ?? fail('Expected result to be non-null')).mcpServerId,
          'abc',
        );
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
    var mcpServersRepository = _FakeMcpServersRepository();
    var mcpManagerService = McpManagerService();
    AppDatabase? database;
    var container = ProviderContainer();

    AppDatabase getDatabase() =>
        database ?? fail('Expected test database to be initialized');

    setUp(() {
      mcpServersRepository = _FakeMcpServersRepository();
      mcpManagerService = McpManagerService();
      final testDatabase = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      database = testDatabase;
      addTearDown(testDatabase.close);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(getDatabase()),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(mcpManagerService),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
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
      expect(
        (conn ?? fail('Expected conn to be non-null')).server.id,
        'server-1',
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

    test('getToolSpec returns tool spec for ready server tool', () {
      final notifier = container.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
            client: _FakeMcpManagerClient(),
            tools: const [_toolInfo],
          ),
        ];

      final spec = notifier.getToolSpec(
        mcpServerId: 'server-1',
        toolName: 'sum',
      );

      expect(spec, isNotNull);
      expect(spec?.name, 'mcp_server-1_test-server_sum');
      expect(spec?.description, 'Sum numbers');
      expect(spec?.inputJsonSchema, isEmpty);
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
          appDatabaseProvider.overrideWithValue(getDatabase()),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(fakeService),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
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
          appDatabaseProvider.overrideWithValue(getDatabase()),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(fakeService),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
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

    test('dispose cleans up connections', () {
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

    test(
      'addMcpServer persists credential, server, tools, and state',
      () async {
        final fakeService = _SuccessfulMcpManagerService();
        final testContainer = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(getDatabase()),
            mcpServersRepositoryProvider.overrideWithValue(
              mcpServersRepository,
            ),
            mcpManagerServiceProvider.overrideWithValue(fakeService),
            encryptionServiceProvider.overrideWithValue(
              _FakeEncryptionService(),
            ),
          ],
        );
        addTearDown(testContainer.dispose);

        await testContainer
            .read(mcpConnectionProvider.notifier)
            .addMcpServer(
              const McpServerFormToCreate(
                name: 'Bearer MCP',
                url: 'https://example.com',
                transport: McpTransportTypeSSE(),
                authenticationType: McpAuthenticationTypeOptions.bearerToken,
                bearerToken: 'test-token',
              ),
              workspaceId: 'workspace-1',
            );

        final state = testContainer.read(mcpConnectionProvider);
        expect(state, hasLength(1));
        expect(state.firstOrNull?.status, McpConnectionStatus.connected);
        expect(state.firstOrNull?.tools, const [_toolInfo]);
        expect(mcpServersRepository.addedServers, hasLength(1));
        expect(
          mcpServersRepository.addedServers.single.serviceConnectionId,
          isNotEmpty,
        );
        expect(fakeService.connectedServers.single.serviceConnectionId, isNull);
      },
    );

    test('addMcpServer cleans up credential when persistence fails', () async {
      mcpServersRepository.addServerError = Exception('insert failed');
      final testContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(getDatabase()),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(
            _SuccessfulMcpManagerService(),
          ),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
        ],
      );
      addTearDown(testContainer.dispose);

      await expectLater(
        testContainer
            .read(mcpConnectionProvider.notifier)
            .addMcpServer(
              const McpServerFormToCreate(
                name: 'Bearer MCP',
                url: 'https://example.com',
                transport: McpTransportTypeSSE(),
                authenticationType: McpAuthenticationTypeOptions.bearerToken,
                bearerToken: 'test-token',
              ),
              workspaceId: 'workspace-1',
            ),
        throwsA(isA<Exception>()),
      );

      final credentials = await getDatabase()
          .select(
            getDatabase().serviceConnections,
          )
          .get();
      expect(credentials, isEmpty);
      expect(testContainer.read(mcpConnectionProvider), isEmpty);
    });

    test('disconnectMcpServer for missing server is no-op', () {
      final notifier = container.read(mcpConnectionProvider.notifier);
      notifier.disconnectMcpServer('nonexistent');

      final state = container.read(mcpConnectionProvider);
      expect(state, isEmpty);
    });

    test('logs and skips workspace load failures', () async {
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      final previousLevel = Logger.root.level;
      Logger.root.level = Level.ALL;
      addTearDown(() {
        Logger.root.level = previousLevel;
      });

      final expectedError = Exception('db offline');
      mcpServersRepository.enabledServersError = expectedError;
      final testContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(getDatabase()),
          currentRouteWorkspaceIdProvider.overrideWithValue('workspace-1'),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(mcpManagerService),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
        ],
      );
      addTearDown(testContainer.dispose);

      expect(testContainer.read(mcpConnectionProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);

      expect(testContainer.read(mcpConnectionProvider), isEmpty);
      final record = records.firstWhere(
        (record) =>
            record.loggerName == 'McpConnectionNotifier' &&
            record.level == Level.WARNING &&
            record.message == 'Failed to load MCP servers from database',
      );
      expect(record.error, same(expectedError));
      expect(record.stackTrace, isNotNull);
    });

    test('logs tool sync failures without failing connection', () async {
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      final previousLevel = Logger.root.level;
      Logger.root.level = Level.ALL;
      addTearDown(() {
        Logger.root.level = previousLevel;
      });

      final expectedError = Exception('sync failed');
      mcpServersRepository
        ..serverById = _server
        ..syncToolsError = expectedError;
      final testContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(getDatabase()),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(
            _SuccessfulMcpManagerService(),
          ),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
        ],
      );
      addTearDown(testContainer.dispose);

      final notifier = testContainer.read(mcpConnectionProvider.notifier);
      await notifier.reconnectMcpServer('server-1');

      final state = testContainer.read(mcpConnectionProvider);
      expect(state, hasLength(1));
      expect(state.firstOrNull?.status, McpConnectionStatus.connected);
      final record = records.firstWhere(
        (record) =>
            record.loggerName == 'McpConnectionNotifier' &&
            record.level == Level.WARNING &&
            record.message == 'Failed to sync MCP tools to database',
      );
      expect(record.error, same(expectedError));
      expect(record.stackTrace, isNotNull);
    });

    test('callTool returns service result for connected server tool', () async {
      final fakeService = _SuccessfulMcpManagerService();
      final testContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(getDatabase()),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(fakeService),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
        ],
      );
      addTearDown(testContainer.dispose);
      final client = _FakeMcpManagerClient();
      final notifier = testContainer.read(mcpConnectionProvider.notifier)
        ..state = [
          McpConnectionState(
            server: _server,
            status: McpConnectionStatus.connected,
            client: client,
            tools: const [_toolInfo],
          ),
        ];

      final result = await notifier.callTool(
        mcpServerId: 'server-1',
        toolIdentifier: 'sum',
        arguments: const {'a': 1, 'b': 2},
      );

      expect(result, 'tool result');
      expect(fakeService.calledToolIdentifiers, ['sum']);
    });

    test('token updates are persisted for added MCP credential', () async {
      final tokenController = StreamController<OAuthTokenEntity>();
      addTearDown(tokenController.close);
      final fakeService = _SuccessfulMcpManagerService(
        client: _FakeMcpManagerClient(tokenUpdates: tokenController.stream),
      );
      final testContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(getDatabase()),
          mcpServersRepositoryProvider.overrideWithValue(mcpServersRepository),
          mcpManagerServiceProvider.overrideWithValue(fakeService),
          encryptionServiceProvider.overrideWithValue(
            _FakeEncryptionService(),
          ),
        ],
      );
      addTearDown(testContainer.dispose);

      await testContainer
          .read(mcpConnectionProvider.notifier)
          .addMcpServer(
            const McpServerFormToCreate(
              name: 'Bearer MCP',
              url: 'https://example.com',
              transport: McpTransportTypeSSE(),
              authenticationType: McpAuthenticationTypeOptions.bearerToken,
              bearerToken: 'test-token',
            ),
            workspaceId: 'workspace-1',
          );
      tokenController.add(
        OAuthTokenEntity(
          accessToken: 'updated-access-token',
          issuedAt: DateTime(2026, 1, 2),
          expiresIn: 3600,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final credentials = await getDatabase()
          .select(
            getDatabase().serviceConnections,
          )
          .get();
      expect(credentials, hasLength(1));
      expect(credentials.single.keySuffix, '-token');
      expect(credentials.single.lastRefreshedAt, DateTime(2026, 1, 2));
    });
  });
}

class _FakeMcpServersRepository implements McpServersRepository {
  List<String> deletedIds = [];
  List<McpServerToCreate> addedServers = [];
  Exception? addServerError;
  Exception? enabledServersError;
  Exception? syncToolsError;
  McpServerEntity? serverById;

  @override
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  }) async {
    if (addServerError case final error?) {
      throw error;
    }

    addedServers.add(serverToCreate);

    return McpServerEntity(
      id: 'server-${addedServers.length}',
      workspaceId: workspaceId,
      name: serverToCreate.name,
      url: serverToCreate.url,
      transport: serverToCreate.transport,
      authenticationType: serverToCreate.authenticationType,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      serviceConnectionId: serverToCreate.serviceConnectionId,
      description: serverToCreate.description,
    );
  }

  @override
  Future<bool> deleteMcpServer(String serverId) async {
    deletedIds.add(serverId);

    return true;
  }

  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) async {
    if (enabledServersError case final error?) {
      throw error;
    }

    return const [];
  }

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
  }) async {
    if (syncToolsError case final error?) {
      throw error;
    }
  }
}

final class _FakeEncryptionService extends EncryptionService {
  _FakeEncryptionService() : super(SecretKeyManager());

  @override
  Future<String> decrypt(String encryptedBase64) async => encryptedBase64;

  @override
  Future<String> encrypt(String plaintext) async => plaintext;
}

class _FailingMcpManagerService extends McpManagerService {
  @override
  Future<McpManagerClient> connectMcp(McpServerToCreate serverInfo) async {
    throw Exception('Connection refused');
  }
}

class _SuccessfulMcpManagerService extends McpManagerService {
  _SuccessfulMcpManagerService({
    _FakeMcpManagerClient? client,
  }) : _client = client ?? _FakeMcpManagerClient();

  final _FakeMcpManagerClient _client;
  final connectedServers = <McpServerToCreate>[];
  final calledToolIdentifiers = <String>[];

  @override
  Future<McpManagerClient> connectMcp(McpServerToCreate serverInfo) async {
    connectedServers.add(serverInfo);

    return _client;
  }

  @override
  Future<void> disconnect(McpManagerClient? client) async {
    final _ = Object();
  }

  @override
  Future<List<McpToolInfo>> getTools(McpManagerClient client) async {
    return const [_toolInfo];
  }

  @override
  Future<String> callToolString(
    McpManagerClient client, {
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    calledToolIdentifiers.add(toolIdentifier);

    return 'tool result';
  }
}

class _FakeMcpManagerClient implements McpManagerClient {
  _FakeMcpManagerClient({
    Stream<OAuthTokenEntity>? tokenUpdates,
  }) : this._(tokenUpdates);

  _FakeMcpManagerClient._(this._tokenUpdates);

  final Stream<OAuthTokenEntity>? _tokenUpdates;

  @override
  Stream<OAuthTokenEntity>? get onTokenUpdate => _tokenUpdates;
}
