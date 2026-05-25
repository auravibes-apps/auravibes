import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

void main() {
  group('ToolsGroupsDao', () {
    late AppDatabase database;
    late String workspaceId;

    setUp(() async {
      database = AppDatabase(connection: createTestConnection());
      final ws = await database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDown(() async {
      await database.close();
    });

    test('insertToolsGroup creates and returns group', () async {
      final group = await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'Test Group',
          permissions: PermissionAccess.ask,
        ),
      );
      expect(group.name, equals('Test Group'));
      expect(group.workspaceId, equals(workspaceId));
    });

    test('getToolsGroupById returns group', () async {
      final created = await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'Group',
          permissions: PermissionAccess.ask,
        ),
      );
      final found = await database.toolsGroupsDao.getToolsGroupById(created.id);
      expect(found, isNotNull);
      expect(found!.name, equals('Group'));
    });

    test('getToolsGroupById returns null for nonexistent', () async {
      final found = await database.toolsGroupsDao.getToolsGroupById('missing');
      expect(found, isNull);
    });

    test('getToolsGroupsForWorkspace returns groups for workspace', () async {
      await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'G1',
          permissions: PermissionAccess.ask,
        ),
      );
      await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'G2',
          permissions: PermissionAccess.ask,
        ),
      );
      final groups = await database.toolsGroupsDao.getToolsGroupsForWorkspace(
        workspaceId,
      );
      expect(groups.length, equals(2));
    });

    test(
      'getToolsGroupsForWorkspace returns empty for other workspace',
      () async {
        await database.toolsGroupsDao.insertToolsGroup(
          ToolsGroupsCompanion.insert(
            workspaceId: workspaceId,
            name: 'G1',
            permissions: PermissionAccess.ask,
          ),
        );
        final groups = await database.toolsGroupsDao.getToolsGroupsForWorkspace(
          'other',
        );
        expect(groups, isEmpty);
      },
    );

    test('getToolsGroupByMcpServerId returns group linked to server', () async {
      final server = await database.mcpServersDao.insertMcpServer(
        McpServersCompanion.insert(
          workspaceId: workspaceId,
          name: 'MCP',
          url: 'http://localhost',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
        ),
      );
      await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          mcpServerId: Value(server.id),
          name: 'Linked Group',
          permissions: PermissionAccess.ask,
        ),
      );
      final found = await database.toolsGroupsDao.getToolsGroupByMcpServerId(
        server.id,
      );
      expect(found, isNotNull);
      expect(found!.name, equals('Linked Group'));
    });

    test('getToolsGroupByMcpServerId returns null when not found', () async {
      final found = await database.toolsGroupsDao.getToolsGroupByMcpServerId(
        'missing',
      );
      expect(found, isNull);
    });

    test('deleteToolsGroupById removes group', () async {
      final created = await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'ToDelete',
          permissions: PermissionAccess.ask,
        ),
      );
      final deleted = await database.toolsGroupsDao.deleteToolsGroupById(
        created.id,
      );
      expect(deleted, isTrue);
      expect(
        await database.toolsGroupsDao.getToolsGroupById(created.id),
        isNull,
      );
    });

    test('deleteToolsGroupById returns false for nonexistent', () async {
      final deleted = await database.toolsGroupsDao.deleteToolsGroupById(
        'missing',
      );
      expect(deleted, isFalse);
    });

    test('setToolsGroupEnabled updates enabled state', () async {
      final created = await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'Group',
          permissions: PermissionAccess.ask,
        ),
      );
      final updated = await database.toolsGroupsDao.setToolsGroupEnabled(
        created.id,
        isEnabled: false,
      );
      expect(updated, isTrue);
      final found = await database.toolsGroupsDao.getToolsGroupById(created.id);
      expect(found!.isEnabled, isFalse);
    });
  });
}
