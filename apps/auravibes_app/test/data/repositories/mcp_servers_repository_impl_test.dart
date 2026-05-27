// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository_impl.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mcp_servers_repository_impl_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<McpServersDao>(),
  MockSpec<ToolsGroupsDao>(),
  MockSpec<WorkspaceToolsDao>(),
])
void main() {
  group('McpServersRepositoryImpl', () {
    late MockMcpServersDao mockMcpServersDao;
    late MockToolsGroupsDao mockToolsGroupsDao;
    late MockWorkspaceToolsDao mockWorkspaceToolsDao;
    late _TestAppDatabase database;
    late McpServersRepositoryImpl repository;

    setUp(() {
      mockMcpServersDao = MockMcpServersDao();
      mockToolsGroupsDao = MockToolsGroupsDao();
      mockWorkspaceToolsDao = MockWorkspaceToolsDao();
      database = _TestAppDatabase(
        mockMcpServersDao,
        mockToolsGroupsDao,
        mockWorkspaceToolsDao,
      );
      repository = McpServersRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    final now = DateTime(2026);

    McpServersTable createServerRow({
      String id = 'mcp-1',
      String workspaceId = 'ws-1',
      String name = 'Test Server',
    }) {
      return McpServersTable(
        id: id,
        createdAt: now,
        updatedAt: now,
        workspaceId: workspaceId,
        name: name,
        url: 'http://localhost:3000',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationType.none(),
        description: 'A test server',
        isEnabled: true,
      );
    }

    ToolsGroupsTable createGroupRow({
      String id = 'group-1',
      String workspaceId = 'ws-1',
      String? mcpServerId,
    }) {
      return ToolsGroupsTable(
        id: id,
        createdAt: now,
        updatedAt: now,
        workspaceId: workspaceId,
        mcpServerId: mcpServerId,
        name: 'Test Group',
        isEnabled: true,
        permissions: PermissionAccess.ask,
      );
    }

    group('addMcpServerWithTools', () {
      test('creates server with tools in transaction', () async {
        final serverRow = createServerRow();
        final groupRow = createGroupRow(mcpServerId: 'mcp-1');

        when(
          mockMcpServersDao.insertMcpServer(any),
        ).thenAnswer((_) async => serverRow);
        when(
          mockToolsGroupsDao.insertToolsGroup(any),
        ).thenAnswer((_) async => groupRow);
        when(mockWorkspaceToolsDao.insertToolsBatch(any)).thenAnswer((_) async {
          return;
        });

        final tools = [
          const McpToolInfo(
            toolName: 'tool1',
            description: 'Tool 1',
            inputSchema: {'type': 'object'},
          ),
        ];

        const serverToCreate = McpServerToCreate(
          name: 'Test Server',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationType.none(),
        );

        final result = await repository.addMcpServerWithTools(
          workspaceId: 'ws-1',
          serverToCreate: serverToCreate,
          tools: tools,
        );

        expect(result.id, 'mcp-1');
        expect(result.name, 'Test Server');
        verify(mockMcpServersDao.insertMcpServer(any)).called(1);
        verify(mockToolsGroupsDao.insertToolsGroup(any)).called(1);
        verify(mockWorkspaceToolsDao.insertToolsBatch(any)).called(1);
      });

      test('creates server with empty tools list', () async {
        final serverRow = createServerRow();
        final groupRow = createGroupRow(mcpServerId: 'mcp-1');

        when(
          mockMcpServersDao.insertMcpServer(any),
        ).thenAnswer((_) async => serverRow);
        when(
          mockToolsGroupsDao.insertToolsGroup(any),
        ).thenAnswer((_) async => groupRow);

        const serverToCreate = McpServerToCreate(
          name: 'Test Server',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationType.none(),
        );

        final result = await repository.addMcpServerWithTools(
          workspaceId: 'ws-1',
          serverToCreate: serverToCreate,
          tools: [],
        );

        expect(result.id, 'mcp-1');
        final _ = verifyNever(mockWorkspaceToolsDao.insertToolsBatch(any));
      });

      test('throws McpServersException on dao failure', () async {
        when(
          mockMcpServersDao.insertMcpServer(any),
        ).thenThrow(Exception('DB error'));

        const serverToCreate = McpServerToCreate(
          name: 'Test Server',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationType.none(),
        );

        await expectLater(
          repository.addMcpServerWithTools(
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
        when(
          mockMcpServersDao.deleteMcpServer('mcp-1'),
        ).thenAnswer((_) async => true);

        final result = await repository.deleteMcpServer('mcp-1');

        expect(result, true);
      });

      test('returns false when not found', () async {
        when(
          mockMcpServersDao.deleteMcpServer('nonexistent'),
        ).thenAnswer((_) async => false);

        final result = await repository.deleteMcpServer('nonexistent');

        expect(result, false);
      });

      test('throws McpServersException on failure', () async {
        when(
          mockMcpServersDao.deleteMcpServer('mcp-1'),
        ).thenThrow(Exception('DB error'));

        await expectLater(
          repository.deleteMcpServer('mcp-1'),
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
          permissions: PermissionAccess.ask,
        );

        when(
          mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer((_) async => groupRow);
        when(
          mockWorkspaceToolsDao.getToolsByGroupId('g1'),
        ).thenAnswer((_) async => [existingTool]);
        when(mockWorkspaceToolsDao.insertToolsBatch(any)).thenAnswer((_) async {
          return;
        });
        when(
          mockWorkspaceToolsDao.deleteWorkspaceToolById('t1'),
        ).thenAnswer((_) async => true);

        await repository.syncMcpTools(
          mcpServerId: 'mcp-1',
          currentTools: [
            const McpToolInfo(
              toolName: 'new_tool',
              description: 'New Tool',
              inputSchema: {'type': 'object'},
            ),
          ],
        );

        verify(mockWorkspaceToolsDao.insertToolsBatch(any)).called(1);
        verify(mockWorkspaceToolsDao.deleteWorkspaceToolById('t1')).called(1);
      });

      test('throws McpServerNotFoundException when group missing', () async {
        when(
          mockToolsGroupsDao.getToolsGroupByMcpServerId('nonexistent'),
        ).thenAnswer((_) async => null);

        await expectLater(
          repository.syncMcpTools(
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
          isEnabled: true,
          permissions: PermissionAccess.ask,
        );

        when(
          mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer((_) async => groupRow);
        when(
          mockWorkspaceToolsDao.getToolsByGroupId('g1'),
        ).thenAnswer((_) async => [existingTool]);

        await repository.syncMcpTools(
          mcpServerId: 'mcp-1',
          currentTools: [
            const McpToolInfo(
              toolName: 'tool1',
              description: 'Tool 1',
              inputSchema: {},
            ),
          ],
        );

        final _ = verifyNever(mockWorkspaceToolsDao.insertToolsBatch(any));
        final _ = verifyNever(
          mockWorkspaceToolsDao.deleteWorkspaceToolById(any),
        );
      });
    });

    group('getMcpServersForWorkspace', () {
      test('returns mapped entities', () async {
        when(
          mockMcpServersDao.getMcpServersForWorkspace('ws-1'),
        ).thenAnswer((_) async => [createServerRow()]);

        final result = await repository.getMcpServersForWorkspace('ws-1');

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'mcp-1');
        expect(result.firstOrNull?.name, 'Test Server');
        expect(result.firstOrNull?.workspaceId, 'ws-1');
      });

      test('throws McpServersException on failure', () async {
        when(
          mockMcpServersDao.getMcpServersForWorkspace('ws-1'),
        ).thenThrow(Exception('DB error'));

        await expectLater(
          repository.getMcpServersForWorkspace('ws-1'),
          throwsA(isA<McpServersException>()),
        );
      });
    });

    group('getEnabledMcpServersForWorkspace', () {
      test('returns enabled servers', () async {
        when(
          mockMcpServersDao.getEnabledMcpServersForWorkspace('ws-1'),
        ).thenAnswer((_) async => [createServerRow()]);

        final result = await repository.getEnabledMcpServersForWorkspace(
          'ws-1',
        );

        expect(result, hasLength(1));
      });
    });

    group('getMcpServerById', () {
      test('returns entity when found', () async {
        when(
          mockMcpServersDao.getMcpServerById('mcp-1'),
        ).thenAnswer((_) async => createServerRow());

        final result = await repository.getMcpServerById('mcp-1');

        expect(result, isNotNull);
        expect(result!.id, 'mcp-1');
      });

      test('returns null when not found', () async {
        when(
          mockMcpServersDao.getMcpServerById('nonexistent'),
        ).thenAnswer((_) async => null);

        final result = await repository.getMcpServerById('nonexistent');

        expect(result, isNull);
      });
    });
  });
}

class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(
    this._mcpServersDao,
    this._toolsGroupsDao,
    this._workspaceToolsDao,
  ) : super(connection: DatabaseConnection(NativeDatabase.memory()));
  final McpServersDao _mcpServersDao;
  final ToolsGroupsDao _toolsGroupsDao;
  final WorkspaceToolsDao _workspaceToolsDao;

  @override
  McpServersDao get mcpServersDao => _mcpServersDao;

  @override
  ToolsGroupsDao get toolsGroupsDao => _toolsGroupsDao;

  @override
  WorkspaceToolsDao get workspaceToolsDao => _workspaceToolsDao;
}
