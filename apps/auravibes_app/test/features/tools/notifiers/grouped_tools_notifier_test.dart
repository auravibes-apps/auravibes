import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('GroupedToolsNotifier', () {
    late _FakeToolsGroupsRepository toolsGroupsRepository;
    late _FakeWorkspaceToolsRepository workspaceToolsRepository;
    late ProviderContainer container;

    final createdAt = DateTime(2026);

    final builtInTool = WorkspaceToolEntity(
      id: 'tool-1',
      workspaceId: 'workspace-1',
      toolId: 'calculator',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAllow,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final disabledTool = WorkspaceToolEntity(
      id: 'tool-2',
      workspaceId: 'workspace-1',
      toolId: 'search',
      isEnabled: false,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final mcpGroup = ToolsGroupEntity(
      id: 'group-1',
      workspaceId: 'workspace-1',
      name: 'MCP Server',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: createdAt,
      updatedAt: createdAt,
      mcpServerId: 'mcp-server-1',
    );

    setUp(() {
      toolsGroupsRepository = _FakeToolsGroupsRepository();
      workspaceToolsRepository = _FakeWorkspaceToolsRepository();
      container = ProviderContainer(
        overrides: [
          toolsGroupsRepositoryProvider.overrideWithValue(
            toolsGroupsRepository,
          ),
          workspaceToolsRepositoryProvider.overrideWithValue(
            workspaceToolsRepository,
          ),
          mcpManagerServiceProvider.overrideWithValue(McpManagerService()),
          mcpServersRepositoryProvider.overrideWithValue(
            _FakeMcpServersRepository(),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('build returns empty when no groups or tools', () async {
      final result = await container.read(
        groupedToolsProvider('workspace-1').future,
      );

      expect(result, isEmpty);
    });

    test('build returns groups with tools', () async {
      workspaceToolsRepository.workspaceTools = [builtInTool];
      toolsGroupsRepository.groups = [mcpGroup];

      final result = await container.read(
        groupedToolsProvider('workspace-1').future,
      );

      expect(result, isNotEmpty);
    });

    test('build returns built-in tools without group', () async {
      workspaceToolsRepository.workspaceTools = [builtInTool];

      final result = await container.read(
        groupedToolsProvider('workspace-1').future,
      );

      expect(result, isNotEmpty);
      final builtInGroup = result.where(
        (g) => g.defaultGroupType != null,
      );
      expect(builtInGroup, isNotEmpty);
    });

    test('enabledToolsCount sums enabled tools across groups', () async {
      workspaceToolsRepository.workspaceTools = [builtInTool, disabledTool];

      final count = await container.read(
        enabledToolsCountProvider('workspace-1').future,
      );

      expect(count, 1);
    });

    test('totalToolsCount sums all tools across groups', () async {
      workspaceToolsRepository.workspaceTools = [builtInTool, disabledTool];

      final count = await container.read(
        totalToolsCountProvider('workspace-1').future,
      );

      expect(count, 2);
    });

    test('setMcpGroupEnabled does nothing when group not found', () async {
      workspaceToolsRepository.workspaceTools = [];
      toolsGroupsRepository.groupById = null;

      final notifier = container.read(
        groupedToolsProvider('workspace-1').notifier,
      );
      await container.read(groupedToolsProvider('workspace-1').future);

      await notifier.setMcpGroupEnabled('unknown', isEnabled: false);

      expect(toolsGroupsRepository.setEnabledCalled, isFalse);
    });

    test(
      'setMcpGroupEnabled does nothing when group belongs to '
      'different workspace',
      () async {
        toolsGroupsRepository.groupById = ToolsGroupEntity(
          id: 'group-1',
          workspaceId: 'other-workspace',
          name: 'Other',
          isEnabled: true,
          permissions: PermissionAccess.ask,
          createdAt: createdAt,
          updatedAt: createdAt,
        );

        final notifier = container.read(
          groupedToolsProvider('workspace-1').notifier,
        );
        await container.read(groupedToolsProvider('workspace-1').future);

        await notifier.setMcpGroupEnabled('group-1', isEnabled: false);

        expect(toolsGroupsRepository.setEnabledCalled, isFalse);
      },
    );

    test('deleteMcpGroup does nothing for non-mcp group', () async {
      toolsGroupsRepository.groupById = ToolsGroupEntity(
        id: 'group-1',
        workspaceId: 'workspace-1',
        name: 'Non-MCP',
        isEnabled: true,
        permissions: PermissionAccess.ask,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final notifier = container.read(
        groupedToolsProvider('workspace-1').notifier,
      );
      await container.read(groupedToolsProvider('workspace-1').future);

      await notifier.deleteMcpGroup('group-1');
    });

    test('deleteMcpGroup does nothing when group not found', () async {
      toolsGroupsRepository.groupById = null;

      final notifier = container.read(
        groupedToolsProvider('workspace-1').notifier,
      );
      await container.read(groupedToolsProvider('workspace-1').future);

      await notifier.deleteMcpGroup('unknown');
    });
  });
}

class _FakeToolsGroupsRepository implements ToolsGroupsRepository {
  List<ToolsGroupEntity> groups = const [];
  ToolsGroupEntity? groupById;
  bool setEnabledCalled = false;

  @override
  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(
    String workspaceId,
  ) async {
    return groups.where((g) => g.workspaceId == workspaceId).toList();
  }

  @override
  Future<ToolsGroupEntity?> getToolsGroupById(String id) async {
    return groupById;
  }

  @override
  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(
    String mcpServerId,
  ) async {
    return null;
  }

  @override
  Future<bool> setToolsGroupEnabled(
    String groupId, {
    required bool isEnabled,
  }) async {
    setEnabledCalled = true;
    return true;
  }

  @override
  Future<bool> deleteToolsGroup(String id) async {
    return true;
  }
}

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
  Future<bool> deleteMcpServer(String serverId) async => true;

  @override
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  ) async => const [];

  @override
  Future<McpServerEntity?> getMcpServerById(String serverId) async => null;

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

class _FakeWorkspaceToolsRepository implements WorkspaceToolsRepository {
  List<WorkspaceToolEntity> workspaceTools = const [];

  @override
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(
    String workspaceId,
  ) async {
    return workspaceTools;
  }

  @override
  Future<void> copyWorkspaceToolsToConversation(
    String workspaceId,
    String conversationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getEnabledWorkspaceToolsCount(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolType,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getWorkspaceToolConfig(
    String workspaceId,
    String toolType,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getWorkspaceToolsCount(String workspaceId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isWorkspaceToolEnabled(String workspaceId, String toolType) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeWorkspaceTool(String workspaceId, String toolType) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeWorkspaceToolById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WorkspaceToolEntity>> patchWorkspaceToolConfig(
    String workspaceId,
    String toolType,
    String? config,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateWorkspaceToolSetting(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
    String? config,
  }) {
    throw UnimplementedError();
  }
}
