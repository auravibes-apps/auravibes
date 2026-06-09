// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: missing-test-assertion
// Required: Repository tests verify side effects through database state.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

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
    final initialFixture = _McpServersRepositoryFixture();
    var fixture = initialFixture;

    setUp(() {
      fixture = _McpServersRepositoryFixture();
    });

    tearDown(() async {
      await fixture.database.close();
    });

    tearDownAll(() async {
      await initialFixture.database.close();
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
          fixture.mockMcpServersDao.insertMcpServer(any),
        ).thenAnswer((_) async => serverRow);
        when(
          fixture.mockToolsGroupsDao.insertToolsGroup(any),
        ).thenAnswer((_) async => groupRow);
        when(fixture.mockWorkspaceToolsDao.insertToolsBatch(any)).thenAnswer((
          _,
        ) async {
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

        final result = await fixture.repository.addMcpServerWithTools(
          workspaceId: 'ws-1',
          serverToCreate: serverToCreate,
          tools: tools,
        );

        expect(result.id, 'mcp-1');
        expect(result.name, 'Test Server');
        verify(fixture.mockMcpServersDao.insertMcpServer(any)).called(1);
        verify(fixture.mockToolsGroupsDao.insertToolsGroup(any)).called(1);
        verify(fixture.mockWorkspaceToolsDao.insertToolsBatch(any)).called(1);
      });

      test('creates server with empty tools list', () async {
        final serverRow = createServerRow();
        final groupRow = createGroupRow(mcpServerId: 'mcp-1');

        when(
          fixture.mockMcpServersDao.insertMcpServer(any),
        ).thenAnswer((_) async => serverRow);
        when(
          fixture.mockToolsGroupsDao.insertToolsGroup(any),
        ).thenAnswer((_) async => groupRow);

        const serverToCreate = McpServerToCreate(
          name: 'Test Server',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationType.none(),
        );

        final result = await fixture.repository.addMcpServerWithTools(
          workspaceId: 'ws-1',
          serverToCreate: serverToCreate,
          tools: [],
        );

        expect(result.id, 'mcp-1');
        final _ = verifyNever(
          fixture.mockWorkspaceToolsDao.insertToolsBatch(any),
        );
      });

      test('throws McpServersException on dao failure', () async {
        when(
          fixture.mockMcpServersDao.insertMcpServer(any),
        ).thenThrow(Exception('DB error'));

        const serverToCreate = McpServerToCreate(
          name: 'Test Server',
          url: 'http://localhost:3000',
          transport: McpTransportTypeSSE(),
          authenticationType: McpAuthenticationType.none(),
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
        when(
          fixture.mockMcpServersDao.deleteMcpServer('mcp-1'),
        ).thenAnswer((_) async => true);

        final result = await fixture.repository.deleteMcpServer('mcp-1');

        expect(result, true);
      });

      test('returns false when not found', () async {
        when(
          fixture.mockMcpServersDao.deleteMcpServer('nonexistent'),
        ).thenAnswer((_) async => false);

        final result = await fixture.repository.deleteMcpServer('nonexistent');

        expect(result, false);
      });

      test('throws McpServersException on failure', () async {
        when(
          fixture.mockMcpServersDao.deleteMcpServer('mcp-1'),
        ).thenThrow(Exception('DB error'));

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
          permissions: PermissionAccess.ask,
        );

        when(
          fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer((_) async => groupRow);
        when(
          fixture.mockWorkspaceToolsDao.getToolsByGroupId('g1'),
        ).thenAnswer((_) async => [existingTool]);
        when(fixture.mockWorkspaceToolsDao.insertToolsBatch(any)).thenAnswer((
          _,
        ) async {
          return;
        });
        when(
          fixture.mockWorkspaceToolsDao.deleteWorkspaceToolById('t1'),
        ).thenAnswer((_) async => true);

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

        verify(fixture.mockWorkspaceToolsDao.insertToolsBatch(any)).called(1);
        verify(
          fixture.mockWorkspaceToolsDao.deleteWorkspaceToolById('t1'),
        ).called(1);
      });

      test('throws McpServerNotFoundException when group missing', () async {
        when(
          fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('nonexistent'),
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
          isEnabled: true,
          permissions: PermissionAccess.ask,
        );

        when(
          fixture.mockToolsGroupsDao.getToolsGroupByMcpServerId('mcp-1'),
        ).thenAnswer((_) async => groupRow);
        when(
          fixture.mockWorkspaceToolsDao.getToolsByGroupId('g1'),
        ).thenAnswer((_) async => [existingTool]);

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

        final _ = verifyNever(
          fixture.mockWorkspaceToolsDao.insertToolsBatch(any),
        );
        final _ = verifyNever(
          fixture.mockWorkspaceToolsDao.deleteWorkspaceToolById(any),
        );
      });
    });

    group('getMcpServersForWorkspace', () {
      test('returns mapped entities', () async {
        when(
          fixture.mockMcpServersDao.getMcpServersForWorkspace('ws-1'),
        ).thenAnswer((_) async => [createServerRow()]);

        final result = await fixture.repository.getMcpServersForWorkspace(
          'ws-1',
        );

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'mcp-1');
        expect(result.firstOrNull?.name, 'Test Server');
        expect(result.firstOrNull?.workspaceId, 'ws-1');
      });

      test('throws McpServersException on failure', () async {
        when(
          fixture.mockMcpServersDao.getMcpServersForWorkspace('ws-1'),
        ).thenThrow(Exception('DB error'));

        await expectLater(
          fixture.repository.getMcpServersForWorkspace('ws-1'),
          throwsA(isA<McpServersException>()),
        );
      });
    });

    group('getEnabledMcpServersForWorkspace', () {
      test('returns enabled servers', () async {
        when(
          fixture.mockMcpServersDao.getEnabledMcpServersForWorkspace('ws-1'),
        ).thenAnswer((_) async => [createServerRow()]);

        final result = await fixture.repository
            .getEnabledMcpServersForWorkspace(
              'ws-1',
            );

        expect(result, hasLength(1));
      });
    });

    group('getMcpServerById', () {
      test('returns entity when found', () async {
        when(
          fixture.mockMcpServersDao.getMcpServerById('mcp-1'),
        ).thenAnswer((_) async => createServerRow());

        final result = await fixture.repository.getMcpServerById('mcp-1');

        expect(result, isNotNull);
        expect((result ?? fail('Expected result to be non-null')).id, 'mcp-1');
      });

      test('returns null when not found', () async {
        when(
          fixture.mockMcpServersDao.getMcpServerById('nonexistent'),
        ).thenAnswer((_) async => null);

        final result = await fixture.repository.getMcpServerById('nonexistent');

        expect(result, isNull);
      });
    });
  });
}

class _McpServersRepositoryFixture {
  factory _McpServersRepositoryFixture() {
    final mcpServersDao = MockMcpServersDao();
    final toolsGroupsDao = MockToolsGroupsDao();
    final workspaceToolsDao = MockWorkspaceToolsDao();
    final database = _TestAppDatabase(
      mcpServersDao,
      toolsGroupsDao,
      workspaceToolsDao,
    );
    return _McpServersRepositoryFixture._(
      mockMcpServersDao: mcpServersDao,
      mockToolsGroupsDao: toolsGroupsDao,
      mockWorkspaceToolsDao: workspaceToolsDao,
      database: database,
      repository: McpServersRepositoryImpl(database),
    );
  }

  const _McpServersRepositoryFixture._({
    required this.mockMcpServersDao,
    required this.mockToolsGroupsDao,
    required this.mockWorkspaceToolsDao,
    required this.database,
    required this.repository,
  });

  final MockMcpServersDao mockMcpServersDao;
  final MockToolsGroupsDao mockToolsGroupsDao;
  final MockWorkspaceToolsDao mockWorkspaceToolsDao;
  final _TestAppDatabase database;
  final McpServersRepositoryImpl repository;
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
