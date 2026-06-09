// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
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

final class _DatabaseFixture {
  _DatabaseFixture(this.createConnection);

  final QueryExecutor Function() createConnection;
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = AppDatabase(connection: createConnection());
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('WorkspaceToolsDao', () {
    final fixture = _DatabaseFixture(createTestConnection);
    var workspaceId = '';

    setUp(() async {
      fixture.reset();
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDown(() async {
      await fixture.close();
    });

    Future<ToolsTable> seedTool({
      String toolId = 'web_search',
      bool isEnabled = false,
      String? groupId,
      String? config,
    }) async {
      final companion = ToolsCompanion.insert(
        workspaceId: workspaceId,
        workspaceToolsGroupId: groupId != null
            ? Value(groupId)
            : const Value.absent(),
        toolId: toolId,
        config: config != null ? Value(config) : const Value.absent(),
        isEnabled: Value(isEnabled),
      );

      await fixture.database.workspaceToolsDao.insertToolsBatch([companion]);
      final tool = await fixture.database.workspaceToolsDao
          .getWorkspaceToolByToolId(
            workspaceId,
            toolId,
          );

      return tool ?? fail('Expected workspace tool');
    }

    test('getWorkspaceTools returns empty when no tools', () async {
      final tools = await fixture.database.workspaceToolsDao.getWorkspaceTools(
        workspaceId,
      );
      expect(tools, isEmpty);
    });

    test('insertToolsBatch inserts tools', () async {
      await fixture.database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          toolId: 'tool1',
        ),
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          toolId: 'tool2',
        ),
      ]);
      final tools = await fixture.database.workspaceToolsDao.getWorkspaceTools(
        workspaceId,
      );
      expect(tools.length, equals(2));
    });

    test('getWorkspaceTool returns tool by workspace and id', () async {
      final created = await seedTool(toolId: 'my_tool');
      final found = await fixture.database.workspaceToolsDao.getWorkspaceTool(
        workspaceId,
        created.id,
      );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).toolId,
        equals('my_tool'),
      );
    });

    test('getWorkspaceTool returns null for wrong workspace', () async {
      final created = await seedTool();
      final found = await fixture.database.workspaceToolsDao.getWorkspaceTool(
        'other-ws',
        created.id,
      );
      expect(found, isNull);
    });

    test('getWorkspaceToolByToolId returns tool', () async {
      final _ = await seedTool();
      final found = await fixture.database.workspaceToolsDao
          .getWorkspaceToolByToolId(
            workspaceId,
            'web_search',
          );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).toolId,
        equals('web_search'),
      );
    });

    test('setWorkspaceToolEnabled inserts new when not exists', () async {
      final result = await fixture.database.workspaceToolsDao
          .setWorkspaceToolEnabled(
            workspaceId,
            'new_tool',
            isEnabled: true,
          );
      expect(result.toolId, equals('new_tool'));
      expect(result.isEnabled, isTrue);
    });

    test('setWorkspaceToolEnabled updates existing', () async {
      final _ = await seedTool(toolId: 'existing');
      final result = await fixture.database.workspaceToolsDao
          .setWorkspaceToolEnabled(
            workspaceId,
            'existing',
            isEnabled: true,
          );
      expect(result.isEnabled, isTrue);
    });

    test('setWorkspaceToolEnabledById updates by id', () async {
      final created = await seedTool(toolId: 't1');
      final updated = await fixture.database.workspaceToolsDao
          .setWorkspaceToolEnabledById(
            created.id,
            isEnabled: true,
          );
      expect(updated.isEnabled, isTrue);
    });

    test('patchWorkspaceToolConfig updates config', () async {
      final _ = await seedTool(toolId: 'cfg_tool');
      final results = await fixture.database.workspaceToolsDao
          .patchWorkspaceToolConfig(
            workspaceId,
            'cfg_tool',
            '{"key":"val"}',
          );
      expect(results.firstOrNull?.config, equals('{"key":"val"}'));
    });

    test('deleteWorkspaceToolByToolId deletes by toolId', () async {
      final _ = await seedTool(toolId: 'del_me');
      final deleted = await fixture.database.workspaceToolsDao
          .deleteWorkspaceToolByToolId(
            workspaceId,
            'del_me',
          );
      expect(deleted, isTrue);
    });

    test('deleteWorkspaceToolByToolId returns false when not found', () async {
      final deleted = await fixture.database.workspaceToolsDao
          .deleteWorkspaceToolByToolId(
            workspaceId,
            'missing',
          );
      expect(deleted, isFalse);
    });

    test('deleteWorkspaceTool deletes by id', () async {
      final created = await seedTool(toolId: 'del_id');
      final deleted = await fixture.database.workspaceToolsDao
          .deleteWorkspaceTool(
            workspaceId,
            created.id,
          );
      expect(deleted, isTrue);
    });

    test('deleteWorkspaceToolById deletes by id only', () async {
      final created = await seedTool(toolId: 'del_by_id');
      final deleted = await fixture.database.workspaceToolsDao
          .deleteWorkspaceToolById(
            created.id,
          );
      expect(deleted, isTrue);
    });

    test('getEnabledWorkspaceTools returns only enabled', () async {
      final _ = await seedTool(toolId: 'on', isEnabled: true);
      final _ = await seedTool(toolId: 'off');
      final enabled = await fixture.database.workspaceToolsDao
          .getEnabledWorkspaceTools(
            workspaceId,
          );
      expect(enabled.length, equals(1));
      expect(enabled.firstOrNull?.toolId, equals('on'));
    });

    test('getEnabledToolByToolName returns enabled tool in group', () async {
      final group = await fixture.database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'G',
          permissions: PermissionAccess.ask,
        ),
      );
      await fixture.database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          workspaceToolsGroupId: Value(group.id),
          toolId: 'mcp_tool',
          isEnabled: const Value(true),
        ),
      ]);
      final found = await fixture.database.workspaceToolsDao
          .getEnabledToolByToolName(
            toolGroupId: group.id,
            toolName: 'mcp_tool',
          );
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).toolId,
        equals('mcp_tool'),
      );
    });

    test('isWorkspaceToolEnabled returns correct state', () async {
      final created = await seedTool(toolId: 'chk', isEnabled: true);
      expect(
        await fixture.database.workspaceToolsDao.isWorkspaceToolEnabled(
          workspaceId,
          created.id,
        ),
        isTrue,
      );
      expect(
        await fixture.database.workspaceToolsDao.isWorkspaceToolEnabled(
          workspaceId,
          'missing',
        ),
        isFalse,
      );
    });

    test('getWorkspaceToolConfig returns config string', () async {
      final created = await seedTool(
        toolId: 'cfg',
        config: '{"k":"v"}',
      );
      final config = await fixture.database.workspaceToolsDao
          .getWorkspaceToolConfig(
            workspaceId,
            created.id,
          );
      expect(config, equals('{"k":"v"}'));
    });

    test('getWorkspaceToolConfigByToolId returns config', () async {
      final _ = await seedTool(toolId: 'cfg2', config: 'abc');
      final config = await fixture.database.workspaceToolsDao
          .getWorkspaceToolConfigByToolId(
            workspaceId,
            'cfg2',
          );
      expect(config, equals('abc'));
    });

    test('isWorkspaceToolEnabledByToolId returns correct state', () async {
      final _ = await seedTool(toolId: 'chk2', isEnabled: true);
      expect(
        await fixture.database.workspaceToolsDao.isWorkspaceToolEnabledByToolId(
          workspaceId,
          'chk2',
        ),
        isTrue,
      );
      expect(
        await fixture.database.workspaceToolsDao.isWorkspaceToolEnabledByToolId(
          workspaceId,
          'missing',
        ),
        isFalse,
      );
    });

    test('getWorkspaceToolsCount returns correct count', () async {
      expect(
        await fixture.database.workspaceToolsDao.getWorkspaceToolsCount(
          workspaceId,
        ),
        equals(0),
      );
      final _ = await seedTool(toolId: 'a');
      final _ = await seedTool(toolId: 'b');
      expect(
        await fixture.database.workspaceToolsDao.getWorkspaceToolsCount(
          workspaceId,
        ),
        equals(2),
      );
    });

    test('getEnabledWorkspaceToolsCount returns correct count', () async {
      final _ = await seedTool(toolId: 'a', isEnabled: true);
      final _ = await seedTool(toolId: 'b');
      expect(
        await fixture.database.workspaceToolsDao.getEnabledWorkspaceToolsCount(
          workspaceId,
        ),
        equals(1),
      );
    });

    test('setWorkspaceToolPermission updates permission', () async {
      final created = await seedTool(toolId: 'perm');
      final updated = await fixture.database.workspaceToolsDao
          .setWorkspaceToolPermission(
            created.id,
            permission: PermissionAccess.granted,
          );
      expect(updated.permissions, equals(PermissionAccess.granted));
    });

    test('deleteToolsByGroupId removes tools in group', () async {
      final group = await fixture.database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'G',
          permissions: PermissionAccess.ask,
        ),
      );
      await fixture.database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          workspaceToolsGroupId: Value(group.id),
          toolId: 'gt1',
        ),
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          workspaceToolsGroupId: Value(group.id),
          toolId: 'gt2',
        ),
      ]);
      final deleted = await fixture.database.workspaceToolsDao
          .deleteToolsByGroupId(
            group.id,
          );
      expect(deleted, equals(2));
    });

    test('getToolsByGroupId returns tools in group', () async {
      final group = await fixture.database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'G',
          permissions: PermissionAccess.ask,
        ),
      );
      await fixture.database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          workspaceToolsGroupId: Value(group.id),
          toolId: 'gt1',
        ),
      ]);
      final tools = await fixture.database.workspaceToolsDao.getToolsByGroupId(
        group.id,
      );
      expect(tools.length, equals(1));
    });
  });
}
