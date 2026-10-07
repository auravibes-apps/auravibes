import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_connection_test_summary.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';
import '../database/drift/database_test_utils.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('McpServersRepository', () {
    final fixture = _McpServersRepositoryFixture();

    setUp(fixture.resetForTest);

    tearDownAll(() async {
      await fixture.database.close();
    });

    final now = DateTime(2026);

    McpServersTable createServerRow({
      String id = 'mcp-1',
      String name = 'Test Server',
      String? serviceConnectionId,
      String workspaceId = 'ws-1',
    }) {
      return McpServersTable(
        id: id,
        createdAt: now,
        updatedAt: now,
        workspaceId: workspaceId,
        name: name,
        url: 'http://localhost:3000',
        transport: const McpTransportTypeSSE(),
        serviceConnectionId: serviceConnectionId,
        description: 'A test server',
        isEnabled: true,
      );
    }

    ToolsGroupsTable createGroupRow({
      String id = 'group-1',
      String workspaceId = 'ws-1',
      String? mcpServerId,
      bool isEnabled = true,
    }) {
      return ToolsGroupsTable(
        id: id,
        createdAt: now,
        updatedAt: now,
        workspaceId: workspaceId,
        mcpServerId: mcpServerId,
        name: 'Test Group',
        isEnabled: isEnabled,
        permissions: .ask,
      );
    }

    group('addMcpServerWithTools', () {
      test('stores copied catalog metadata for the active workspace', () async {
        final serverRow = createServerRow(workspaceId: 'workspace-a')
            .copyWith(catalogSnapshotJson: const Value('{"name":"Original"}'));
        final groupRow = createGroupRow(workspaceId: 'workspace-a');
        when(() => fixture.mockMcpServersDao.insertMcpServer(any()))
            .thenAnswer((_) async => serverRow);
        when(() => fixture.mockToolsGroupsDao.insertToolsGroup(any()))
            .thenAnswer((_) async => groupRow);

        const serverToCreate = McpServerToCreate(
          name: 'Original',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: .none(),
          catalogSnapshotJson: '{"name":"Original"}',
        );
        final result = await fixture.repository.addMcpServerWithTools(
          workspaceId: 'workspace-a',
          serverToCreate: serverToCreate,
          tools: [],
        );

        final inserted =
            verify(
                  () => fixture.mockMcpServersDao.insertMcpServer(captureAny()),
                ).captured.single
                as McpServersCompanion;
        expect(inserted.workspaceId.value, 'workspace-a');
        expect(inserted.catalogSnapshotJson.value, '{"name":"Original"}');
        expect(result.catalogSnapshotJson, '{"name":"Original"}');
      });

      test('creates server with tools in transaction', () async {
        final serverRow = createServerRow();
        final groupRow = createGroupRow(mcpServerId: 'mcp-1');

        when(() => fixture.mockMcpServersDao.insertMcpServer(any()))
            .thenAnswer((_) async => serverRow);
        when(() => fixture.mockToolsGroupsDao.insertToolsGroup(any()))
            .thenAnswer((_) async => groupRow);
        when(() => fixture.mockWorkspaceToolsDao.insertToolsBatch(any()))
            .thenAnswer((_) async {
              return;
            });

        final tools = [
          const McpToolInfo(
            toolName: 'tool1',
            description: 'Tool 1',
            inputSchema: {'type': 'object'},
            outputSchema: {'type': 'object'},
          ),
        ];

        const serverToCreate = McpServerToCreate(
          name: 'Test Server',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: .none(),
        );

        final result = await fixture.repository.addMcpServerWithTools(
          workspaceId: 'ws-1',
          serverToCreate: serverToCreate,
          tools: tools,
        );

        expect(result.id, 'mcp-1');
        expect(result.name, 'Test Server');
        verify(() => fixture.mockMcpServersDao.insertMcpServer(any()))
            .called(1);
        verify(() => fixture.mockToolsGroupsDao.insertToolsGroup(any()))
            .called(1);
        final inserted =
            verify(
                  () => fixture.mockWorkspaceToolsDao.insertToolsBatch(
                    captureAny(),
                  ),
                ).captured.single
                as List<ToolsCompanion>;
        expect(inserted.single.outputSchema.value, '{"type":"object"}');
      });

      test('creates server with empty tools list', () async {
        final serverRow = createServerRow();
        final groupRow = createGroupRow(mcpServerId: 'mcp-1');

        when(() => fixture.mockMcpServersDao.insertMcpServer(any()))
            .thenAnswer((_) async => serverRow);
        when(() => fixture.mockToolsGroupsDao.insertToolsGroup(any()))
            .thenAnswer((_) async => groupRow);

        const serverToCreate = McpServerToCreate(
          name: 'Test Server',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: .none(),
        );

        final result = await fixture.repository.addMcpServerWithTools(
          workspaceId: 'ws-1',
          serverToCreate: serverToCreate,
          tools: [],
        );

        expect(result.id, 'mcp-1');
        final _ = verifyNever(
          () => fixture.mockWorkspaceToolsDao.insertToolsBatch(any()),
        );
      });

      test('throws McpServersException on dao failure', () async {
        when(() => fixture.mockMcpServersDao.insertMcpServer(any()))
            .thenThrow(Exception('DB error'));

        const serverToCreate = McpServerToCreate(
          name: 'Test Server',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: .none(),
        );

        await expectLater(
          fixture.repository.addMcpServerWithTools(
            workspaceId: 'ws-1',
            serverToCreate: serverToCreate,
            tools: [],
          ),
          throwsA(isA<McpServersException>()),
        );
      });
    });

    group('deleteMcpServer', () {
      test('returns true when deleted', () async {
        when(() => fixture.mockMcpServersDao.getMcpServerById('mcp-1'))
            .thenAnswer((_) async => createServerRow());
        when(() => fixture.mockMcpServersDao.deleteMcpServer('mcp-1'))
            .thenAnswer((_) async => true);

        final result = await fixture.repository.deleteMcpServer('mcp-1');

        expect(result, true);
      });

      test('returns false when not found', () async {
        when(() => fixture.mockMcpServersDao.getMcpServerById('nonexistent'))
            .thenAnswer((_) async => null);

        final result = await fixture.repository.deleteMcpServer('nonexistent');

        expect(result, false);
        final _ = verifyNever(
          () => fixture.mockMcpServersDao.deleteMcpServer(any()),
        );
      });

      test(
        'deletes linked service connection when server is deleted',
        () async {
          final _ = await fixture.database
              .into(fixture.database.workspaces)
              .insert(
                WorkspacesCompanion.insert(
                  id: const Value('ws-1'),
                  name: 'Workspace',
                  type: .local,
                ),
              );
          final _ = await fixture.database
              .into(fixture.database.serviceConnections)
              .insert(
                ServiceConnectionsCompanion.insert(
                  id: const Value('service-1'),
                  name: 'MCP Credential',
                  serviceId: 'mcp:test-server',
                  kind: .mcpServer,
                  authenticationType: .bearerToken,
                  workspaceId: 'ws-1',
                ),
              );
          when(() => fixture.mockMcpServersDao.getMcpServerById('mcp-1'))
              .thenAnswer(
                (_) async => createServerRow(serviceConnectionId: 'service-1'),
              );
          when(() => fixture.mockMcpServersDao.deleteMcpServer('mcp-1'))
              .thenAnswer((_) async => true);

          final result = await fixture.repository.deleteMcpServer('mcp-1');

          final rows = await fixture.database
              .select(fixture.database.serviceConnections)
              .get();
          expect(result, true);
          expect(rows, isEmpty);
        },
      );

      test('throws McpServersException on failure', () async {
        when(() => fixture.mockMcpServersDao.getMcpServerById('mcp-1'))
            .thenAnswer((_) async => createServerRow());
        when(() => fixture.mockMcpServersDao.deleteMcpServer('mcp-1'))
            .thenThrow(Exception('DB error'));

        await expectLater(
          fixture.repository.deleteMcpServer('mcp-1'),
          throwsA(isA<McpServersException>()),
        );
      });
    });

    group('syncMcpTools', () {
      test('adds new tools and removes old tools', () async {
        final groupRow = createGroupRow(id: 'g1', mcpServerId: 'mcp-1');
        final existingTool = ToolsTable(
          id: 't1',
          createdAt: now,
          updatedAt: now,
          workspaceId: 'ws-1',
          toolId: 'old_tool',
          isEnabled: true,
          permissions: .ask,
        );

        when(
          () => fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer((_) async => groupRow);
        when(() => fixture.mockWorkspaceToolsDao.getToolsByGroupId('g1'))
            .thenAnswer((_) async => [existingTool]);
        when(() => fixture.mockWorkspaceToolsDao.insertToolsBatch(any()))
            .thenAnswer((_) async {
              return;
            });
        when(() => fixture.mockWorkspaceToolsDao.deleteWorkspaceToolById('t1'))
            .thenAnswer((_) async => true);

        await fixture.repository.syncMcpTools(
          mcpServerId: 'mcp-1',
          currentTools: [
            const McpToolInfo(
              toolName: 'new_tool',
              description: 'New Tool',
              inputSchema: {'type': 'object'},
            ),
          ],
        );

        expect(
          () => verify(
            () => fixture.mockWorkspaceToolsDao.insertToolsBatch(any()),
          ).called(1),
          returnsNormally,
        );
        expect(
          () => verify(
            () => fixture.mockWorkspaceToolsDao.deleteWorkspaceToolById('t1'),
          ).called(1),
          returnsNormally,
        );
      });

      test('throws McpServerNotFoundException when group missing', () async {
        when(
          () => fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId(
            'nonexistent',
          ),
        ).thenAnswer((_) async => null);

        await expectLater(
          fixture.repository.syncMcpTools(
            mcpServerId: 'nonexistent',
            currentTools: [],
          ),
          throwsA(isA<McpServerNotFoundException>()),
        );
      });

      test('does nothing when tools are identical', () async {
        final groupRow = createGroupRow(id: 'g1', mcpServerId: 'mcp-1');
        final existingTool = ToolsTable(
          id: 't1',
          createdAt: now,
          updatedAt: now,
          workspaceId: 'ws-1',
          toolId: 'tool1',
          description: 'Tool 1',
          inputSchema: '{}',
          isEnabled: true,
          permissions: .ask,
        );

        when(
          () => fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer((_) async => groupRow);
        when(() => fixture.mockWorkspaceToolsDao.getToolsByGroupId('g1'))
            .thenAnswer((_) async => [existingTool]);

        await fixture.repository.syncMcpTools(
          mcpServerId: 'mcp-1',
          currentTools: [
            const McpToolInfo(
              toolName: 'tool1',
              description: 'Tool 1',
              inputSchema: {},
            ),
          ],
        );

        expect(
          () => verifyNever(
            () => fixture.mockWorkspaceToolsDao.insertToolsBatch(any()),
          ),
          returnsNormally,
        );
        expect(
          () => verifyNever(
            () => fixture.mockWorkspaceToolsDao.deleteWorkspaceToolById(any()),
          ),
          returnsNormally,
        );
        expect(
          () => verifyNever(
            () => fixture.mockWorkspaceToolsDao.updateToolMetadata(
              id: any(named: 'id'),
              description: any(named: 'description'),
              inputSchema: any(named: 'inputSchema'),
            ),
          ),
          returnsNormally,
        );
      });

      test(
        'updates metadata while preserving existing permission and enablement',
        () async {
          final groupRow = createGroupRow(id: 'g1', mcpServerId: 'mcp-1');
          final existingTool = ToolsTable(
            id: 't1',
            createdAt: now,
            updatedAt: now,
            workspaceId: 'ws-1',
            toolId: 'tool1',
            description: 'Old',
            inputSchema: '{}',
            outputSchema: '{"type":"object"}',
            isEnabled: false,
            permissions: .granted,
          );
          when(
            () =>
                fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
          ).thenAnswer((_) async => groupRow);
          when(() => fixture.mockWorkspaceToolsDao.getToolsByGroupId('g1'))
              .thenAnswer((_) async => [existingTool]);
          when(
            () => fixture.mockWorkspaceToolsDao.updateToolMetadata(
              id: 't1',
              description: 'New',
              inputSchema: '{"type":"object"}',
              outputSchema: const Value(null),
            ),
          ).thenAnswer((_) => Future<void>.value());

          await fixture.repository.syncMcpTools(
            mcpServerId: 'mcp-1',
            currentTools: [
              const McpToolInfo(
                toolName: 'tool1',
                description: 'New',
                inputSchema: {'type': 'object'},
              ),
            ],
          );

          verify(
            () => fixture.mockWorkspaceToolsDao.updateToolMetadata(
              id: 't1',
              description: 'New',
              inputSchema: '{"type":"object"}',
              outputSchema: const Value(null),
            ),
          ).called(1);
          expect(
            () => verifyNever(
              () => fixture.mockWorkspaceToolsDao.insertToolsBatch(any()),
            ),
            returnsNormally,
          );
          expect(
            () => verifyNever(
              () =>
                  fixture.mockWorkspaceToolsDao.deleteWorkspaceToolById(any()),
            ),
            returnsNormally,
          );
        },
      );
    });

    group('getMcpServersForWorkspace', () {
      test('returns mapped entities', () async {
        when(() => fixture.mockMcpServersDao.getMcpServersForWorkspace('ws-1'))
            .thenAnswer((_) async => [createServerRow()]);

        final result = await fixture.repository.getMcpServersForWorkspace(
          'ws-1',
        );

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'mcp-1');
        expect(result.firstOrNull?.name, 'Test Server');
        expect(result.firstOrNull?.workspaceId, 'ws-1');
      });

      test('throws McpServersException on failure', () async {
        when(() => fixture.mockMcpServersDao.getMcpServersForWorkspace('ws-1'))
            .thenThrow(Exception('DB error'));

        await expectLater(
          fixture.repository.getMcpServersForWorkspace('ws-1'),
          throwsA(isA<McpServersException>()),
        );
      });
    });

    group('getEnabledMcpServersForWorkspace', () {
      test('returns enabled servers', () async {
        when(
          () => fixture.mockMcpServersDao.getEnabledMcpServersForWorkspace(
            'ws-1',
          ),
        ).thenAnswer((_) async => [createServerRow()]);
        when(
          () => fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer((_) async => createGroupRow(mcpServerId: 'mcp-1'));

        final result = await fixture.repository
            .getEnabledMcpServersForWorkspace('ws-1');

        expect(result, hasLength(1));
      });

      test('excludes servers whose tools group is disabled', () async {
        when(
          () => fixture.mockMcpServersDao.getEnabledMcpServersForWorkspace(
            'ws-1',
          ),
        ).thenAnswer((_) async => [createServerRow()]);
        when(
          () => fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer(
          (_) async => createGroupRow(mcpServerId: 'mcp-1', isEnabled: false),
        );

        final result = await fixture.repository
            .getEnabledMcpServersForWorkspace('ws-1');

        expect(result, isEmpty);
      });
    });

    group('getMcpServerById', () {
      test('returns entity when found', () async {
        when(() => fixture.mockMcpServersDao.getMcpServerById('mcp-1'))
            .thenAnswer((_) async => createServerRow());

        final result = await fixture.repository.getMcpServerById('mcp-1');

        expect(result, isNotNull);
        expect((result ?? fail('Expected result to be non-null')).id, 'mcp-1');
      });

      test('returns null when not found', () async {
        when(() => fixture.mockMcpServersDao.getMcpServerById('nonexistent'))
            .thenAnswer((_) async => null);

        final result = await fixture.repository.getMcpServerById('nonexistent');

        expect(result, isNull);
      });
    });

    group('updateMcpServerSettings', () {
      Future<({McpServersTable server, ToolsGroupsTable group})> seedServer({
        bool oauth = false,
      }) async {
        final db = fixture.database;
        final _ = await db
            .into(db.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: const Value('ws-1'),
                name: 'Workspace',
                type: .local,
              ),
            );
        final connection = oauth
            ? await db
                  .into(db.serviceConnections)
                  .insertReturning(
                    ServiceConnectionsCompanion.insert(
                      name: 'OAuth MCP',
                      serviceId: 'mcp-1',
                      kind: .mcpServer,
                      authenticationType: .oauth2,
                      encryptedAuthValue: const .new('encrypted-oauth'),
                      workspaceId: 'ws-1',
                    ),
                  )
            : null;
        if (connection != null) {
          when(
            () => fixture.mockEncryptionService.decrypt('encrypted-oauth'),
          ).thenAnswer((_) async => '{"type":"oauth2","access_token":"token"}');
        }
        final summary = McpConnectionTestSummary(
          status: 'success',
          testedAt: now,
          transport: const McpTransportTypeSSE(),
          toolCount: 2,
          durationMilliseconds: 150,
        );
        final _ = await db
            .into(db.mcpServers)
            .insert(
              McpServersCompanion.insert(
                id: const Value('mcp-1'),
                workspaceId: 'ws-1',
                name: 'Test Server',
                url: 'https://old.example.com/mcp',
                transport: const McpTransportTypeSSE(),
                serviceConnectionId: .new(connection?.id),
                testSummaryJson: .new(summary.toJson()),
              ),
            );
        final _ = await db
            .into(db.toolsGroups)
            .insert(
              ToolsGroupsCompanion.insert(
                id: const Value('group-1'),
                workspaceId: 'ws-1',
                mcpServerId: const Value('mcp-1'),
                name: 'Test Group',
                permissions: .granted,
              ),
            );
        final _ = await db
            .into(db.tools)
            .insert(
              ToolsCompanion.insert(
                id: const Value('tool-1'),
                workspaceId: 'ws-1',
                workspaceToolsGroupId: const Value('group-1'),
                toolId: 'lookup',
                isEnabled: const .new(true),
                permissions: const .new(PermissionAccess.granted),
              ),
            );
        final server = await (db.select(
          db.mcpServers,
        )..where((row) => row.id.equals('mcp-1'))).getSingle();
        final group = await (db.select(
          db.toolsGroups,
        )..where((row) => row.id.equals('group-1'))).getSingle();
        when(() => fixture.mockMcpServersDao.getMcpServerById('mcp-1'))
            .thenAnswer((_) async => server);
        when(
          () => fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer((_) async => group);

        return (server: server, group: group);
      }

      test(
        'clears summary and resets permissions when endpoint changes',
        () async {
          final server = (await seedServer()).server;

          await fixture.repository.updateMcpServerSettings(
            .new(
              serverId: server.id,
              name: server.name,
              url: 'https://new.example.com/mcp',
              transport: server.transport,
              authMode: .none,
              secretChange: .preserve,
              secret: null,
            ),
          );

          final updatedServer = await (fixture.database.select(
            fixture.database.mcpServers,
          )..where((row) => row.id.equals(server.id))).getSingle();
          final updatedGroup = await (fixture.database.select(
            fixture.database.toolsGroups,
          )..where((row) => row.id.equals('group-1'))).getSingle();
          final updatedTool = await (fixture.database.select(
            fixture.database.tools,
          )..where((row) => row.id.equals('tool-1'))).getSingle();

          expect(updatedServer.url, 'https://new.example.com/mcp');
          expect(updatedServer.testSummaryJson, isNull);
          expect(updatedGroup.permissions, PermissionAccess.ask);
          expect(updatedTool.permissions, PermissionAccess.ask);
        },
      );

      test('preserves summary and permissions on a name-only edit', () async {
        final server = (await seedServer()).server;
        final savedSummary = server.testSummaryJson;

        await fixture.repository.updateMcpServerSettings(
          .new(
            serverId: server.id,
            name: 'Renamed Server',
            url: server.url,
            transport: server.transport,
            authMode: .none,
            secretChange: .preserve,
            secret: null,
          ),
        );

        final updatedServer = await (fixture.database.select(
          fixture.database.mcpServers,
        )..where((row) => row.id.equals(server.id))).getSingle();
        final updatedGroup = await (fixture.database.select(
          fixture.database.toolsGroups,
        )..where((row) => row.id.equals('group-1'))).getSingle();
        final updatedTool = await (fixture.database.select(
          fixture.database.tools,
        )..where((row) => row.id.equals('tool-1'))).getSingle();

        expect(updatedServer.name, 'Renamed Server');
        expect(updatedServer.testSummaryJson, savedSummary);
        expect(updatedGroup.permissions, PermissionAccess.granted);
        expect(updatedTool.permissions, PermissionAccess.granted);
      });

      test('marks OAuth for reauth when transport changes', () async {
        final server = (await seedServer(oauth: true)).server;

        await fixture.repository.updateMcpServerSettings(
          .new(
            serverId: server.id,
            name: server.name,
            url: server.url,
            transport: const McpTransportTypeStreamableHttp(),
            authMode: .oauth,
            secretChange: .preserve,
            secret: null,
          ),
        );

        final connectionId = server.serviceConnectionId;
        if (connectionId == null) fail('Expected OAuth connection.');
        final connection = await (fixture.database.select(
          fixture.database.serviceConnections,
        )..where((row) => row.id.equals(connectionId))).getSingle();

        expect(connection.authStatus, ServiceConnectionAuthStatus.needsReauth);
      });
    });
  });
}

class const _McpServersRepositoryFixture._({
  required final MockMcpServersDao mockMcpServersDao,
  required final MockToolsGroupsDao mockToolsGroupsDao,
  required final MockWorkspaceToolsDao mockWorkspaceToolsDao,
  required final MockEncryptionService mockEncryptionService,
  required final _TestAppDatabase database,
  required final McpServersRepository repository,
}) {
  factory() {
    final mcpServersDao = MockMcpServersDao();
    final toolsGroupsDao = MockToolsGroupsDao();
    final workspaceToolsDao = MockWorkspaceToolsDao();
    final encryptionService = MockEncryptionService();
    final database = _TestAppDatabase(
      mcpServersDao,
      toolsGroupsDao,
      workspaceToolsDao,
    );

    return _McpServersRepositoryFixture._(
      mockMcpServersDao: mcpServersDao,
      mockToolsGroupsDao: toolsGroupsDao,
      mockWorkspaceToolsDao: workspaceToolsDao,
      mockEncryptionService: encryptionService,
      database: database,
      repository: .new(database, .new(database, encryptionService)),
    );
  }

  Future<void> resetForTest() async {
    reset(mockMcpServersDao);
    reset(mockToolsGroupsDao);
    reset(mockWorkspaceToolsDao);
    reset(mockEncryptionService);
    await clearAppDatabase(database);
  }
}

class _TestAppDatabase(
  final McpServersDao _mcpServersDao,
  final ToolsGroupsDao _toolsGroupsDao,
  final WorkspaceToolsDao _workspaceToolsDao,
) extends AppDatabase {
  this : super(connection: DatabaseConnection(NativeDatabase.memory()));

  @override
  McpServersDao get mcpServersDao => _mcpServersDao;

  @override
  ToolsGroupsDao get toolsGroupsDao => _toolsGroupsDao;

  @override
  WorkspaceToolsDao get workspaceToolsDao => _workspaceToolsDao;
}
