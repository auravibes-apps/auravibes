// ignore_for_file: prefer-async-await
// Required: Tests use Future chains to assert async side effects.
// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.

// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

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

void main() {
  group('WorkspaceToolsDao', () {
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
      return database.workspaceToolsDao
          .insertToolsBatch([companion])
          .then(
            (_) => database.workspaceToolsDao.getWorkspaceToolByToolId(
              workspaceId,
              toolId,
            ),
          )
          .then((t) => t!);
    }

    test('getWorkspaceTools returns empty when no tools', () async {
      final tools = await database.workspaceToolsDao.getWorkspaceTools(
        workspaceId,
      );
      expect(tools, isEmpty);
    });

    test('insertToolsBatch inserts tools', () async {
      await database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          toolId: 'tool1',
        ),
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          toolId: 'tool2',
        ),
      ]);
      final tools = await database.workspaceToolsDao.getWorkspaceTools(
        workspaceId,
      );
      expect(tools.length, equals(2));
    });

    test('getWorkspaceTool returns tool by workspace and id', () async {
      final created = await seedTool(toolId: 'my_tool');
      final found = await database.workspaceToolsDao.getWorkspaceTool(
        workspaceId,
        created.id,
      );
      expect(found, isNotNull);
      expect(found!.toolId, equals('my_tool'));
    });

    test('getWorkspaceTool returns null for wrong workspace', () async {
      final created = await seedTool();
      final found = await database.workspaceToolsDao.getWorkspaceTool(
        'other-ws',
        created.id,
      );
      expect(found, isNull);
    });

    test('getWorkspaceToolByToolId returns tool', () async {
      final _ = await seedTool();
      final found = await database.workspaceToolsDao.getWorkspaceToolByToolId(
        workspaceId,
        'web_search',
      );
      expect(found, isNotNull);
      expect(found!.toolId, equals('web_search'));
    });

    test('setWorkspaceToolEnabled inserts new when not exists', () async {
      final result = await database.workspaceToolsDao.setWorkspaceToolEnabled(
        workspaceId,
        'new_tool',
        isEnabled: true,
      );
      expect(result.toolId, equals('new_tool'));
      expect(result.isEnabled, isTrue);
    });

    test('setWorkspaceToolEnabled updates existing', () async {
      final _ = await seedTool(toolId: 'existing');
      final result = await database.workspaceToolsDao.setWorkspaceToolEnabled(
        workspaceId,
        'existing',
        isEnabled: true,
      );
      expect(result.isEnabled, isTrue);
    });

    test('setWorkspaceToolEnabledById updates by id', () async {
      final created = await seedTool(toolId: 't1');
      final updated = await database.workspaceToolsDao
          .setWorkspaceToolEnabledById(
            created.id,
            isEnabled: true,
          );
      expect(updated.isEnabled, isTrue);
    });

    test('patchWorkspaceToolConfig updates config', () async {
      final _ = await seedTool(toolId: 'cfg_tool');
      final results = await database.workspaceToolsDao.patchWorkspaceToolConfig(
        workspaceId,
        'cfg_tool',
        '{"key":"val"}',
      );
      expect(results.firstOrNull?.config, equals('{"key":"val"}'));
    });

    test('deleteWorkspaceToolByToolId deletes by toolId', () async {
      final _ = await seedTool(toolId: 'del_me');
      final deleted = await database.workspaceToolsDao
          .deleteWorkspaceToolByToolId(
            workspaceId,
            'del_me',
          );
      expect(deleted, isTrue);
    });

    test('deleteWorkspaceToolByToolId returns false when not found', () async {
      final deleted = await database.workspaceToolsDao
          .deleteWorkspaceToolByToolId(
            workspaceId,
            'missing',
          );
      expect(deleted, isFalse);
    });

    test('deleteWorkspaceTool deletes by id', () async {
      final created = await seedTool(toolId: 'del_id');
      final deleted = await database.workspaceToolsDao.deleteWorkspaceTool(
        workspaceId,
        created.id,
      );
      expect(deleted, isTrue);
    });

    test('deleteWorkspaceToolById deletes by id only', () async {
      final created = await seedTool(toolId: 'del_by_id');
      final deleted = await database.workspaceToolsDao.deleteWorkspaceToolById(
        created.id,
      );
      expect(deleted, isTrue);
    });

    test('getEnabledWorkspaceTools returns only enabled', () async {
      final _ = await seedTool(toolId: 'on', isEnabled: true);
      final _ = await seedTool(toolId: 'off');
      final enabled = await database.workspaceToolsDao.getEnabledWorkspaceTools(
        workspaceId,
      );
      expect(enabled.length, equals(1));
      expect(enabled.firstOrNull?.toolId, equals('on'));
    });

    test('getEnabledToolByToolName returns enabled tool in group', () async {
      final group = await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'G',
          permissions: PermissionAccess.ask,
        ),
      );
      await database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          workspaceToolsGroupId: Value(group.id),
          toolId: 'mcp_tool',
          isEnabled: const Value(true),
        ),
      ]);
      final found = await database.workspaceToolsDao.getEnabledToolByToolName(
        toolGroupId: group.id,
        toolName: 'mcp_tool',
      );
      expect(found, isNotNull);
      expect(found!.toolId, equals('mcp_tool'));
    });

    test('isWorkspaceToolEnabled returns correct state', () async {
      final created = await seedTool(toolId: 'chk', isEnabled: true);
      expect(
        await database.workspaceToolsDao.isWorkspaceToolEnabled(
          workspaceId,
          created.id,
        ),
        isTrue,
      );
      expect(
        await database.workspaceToolsDao.isWorkspaceToolEnabled(
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
      final config = await database.workspaceToolsDao.getWorkspaceToolConfig(
        workspaceId,
        created.id,
      );
      expect(config, equals('{"k":"v"}'));
    });

    test('getWorkspaceToolConfigByToolId returns config', () async {
      final _ = await seedTool(toolId: 'cfg2', config: 'abc');
      final config = await database.workspaceToolsDao
          .getWorkspaceToolConfigByToolId(
            workspaceId,
            'cfg2',
          );
      expect(config, equals('abc'));
    });

    test('isWorkspaceToolEnabledByToolId returns correct state', () async {
      final _ = await seedTool(toolId: 'chk2', isEnabled: true);
      expect(
        await database.workspaceToolsDao.isWorkspaceToolEnabledByToolId(
          workspaceId,
          'chk2',
        ),
        isTrue,
      );
      expect(
        await database.workspaceToolsDao.isWorkspaceToolEnabledByToolId(
          workspaceId,
          'missing',
        ),
        isFalse,
      );
    });

    test('getWorkspaceToolsCount returns correct count', () async {
      expect(
        await database.workspaceToolsDao.getWorkspaceToolsCount(workspaceId),
        equals(0),
      );
      final _ = await seedTool(toolId: 'a');
      final _ = await seedTool(toolId: 'b');
      expect(
        await database.workspaceToolsDao.getWorkspaceToolsCount(workspaceId),
        equals(2),
      );
    });

    test('getEnabledWorkspaceToolsCount returns correct count', () async {
      final _ = await seedTool(toolId: 'a', isEnabled: true);
      final _ = await seedTool(toolId: 'b');
      expect(
        await database.workspaceToolsDao.getEnabledWorkspaceToolsCount(
          workspaceId,
        ),
        equals(1),
      );
    });

    test('setWorkspaceToolPermission updates permission', () async {
      final created = await seedTool(toolId: 'perm');
      final updated = await database.workspaceToolsDao
          .setWorkspaceToolPermission(
            created.id,
            permission: PermissionAccess.granted,
          );
      expect(updated.permissions, equals(PermissionAccess.granted));
    });

    test('deleteToolsByGroupId removes tools in group', () async {
      final group = await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'G',
          permissions: PermissionAccess.ask,
        ),
      );
      await database.workspaceToolsDao.insertToolsBatch([
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
      final deleted = await database.workspaceToolsDao.deleteToolsByGroupId(
        group.id,
      );
      expect(deleted, equals(2));
    });

    test('getToolsByGroupId returns tools in group', () async {
      final group = await database.toolsGroupsDao.insertToolsGroup(
        ToolsGroupsCompanion.insert(
          workspaceId: workspaceId,
          name: 'G',
          permissions: PermissionAccess.ask,
        ),
      );
      await database.workspaceToolsDao.insertToolsBatch([
        ToolsCompanion.insert(
          workspaceId: workspaceId,
          workspaceToolsGroupId: Value(group.id),
          toolId: 'gt1',
        ),
      ]);
      final tools = await database.workspaceToolsDao.getToolsByGroupId(
        group.id,
      );
      expect(tools.length, equals(1));
    });
  });
}
