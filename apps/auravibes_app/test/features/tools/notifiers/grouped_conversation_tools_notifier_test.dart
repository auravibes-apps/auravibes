import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/conversation_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('GroupedConversationToolsNotifier', () {
    late _FakeToolsGroupsRepository toolsGroupsRepository;
    late _FakeWorkspaceToolsRepository workspaceToolsRepository;
    late _FakeConversationToolsRepository conversationToolsRepository;
    late _FakeMcpConnectionNotifier mcpNotifier;
    late ProviderContainer container;

    final createdAt = DateTime(2026);

    final builtInTool = WorkspaceToolEntity(
      id: 'tool-1',
      workspaceId: 'workspace-1',
      toolId: 'web_search',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAllow,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final nativeTool = WorkspaceToolEntity(
      id: 'tool-2',
      workspaceId: 'workspace-1',
      toolId: 'url',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAllow,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final groupedTool = WorkspaceToolEntity(
      id: 'tool-3',
      workspaceId: 'workspace-1',
      toolId: 'mcp_server_1_fetch',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAllow,
      createdAt: createdAt,
      updatedAt: createdAt,
      workspaceToolsGroupId: 'group-1',
    );

    final mcpGroup = ToolsGroupEntity(
      id: 'group-1',
      workspaceId: 'workspace-1',
      name: 'MCP Tools',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: createdAt,
      updatedAt: createdAt,
      mcpServerId: 'server-1',
    );

    setUp(() {
      toolsGroupsRepository = _FakeToolsGroupsRepository();
      workspaceToolsRepository = _FakeWorkspaceToolsRepository();
      conversationToolsRepository = _FakeConversationToolsRepository();
      mcpNotifier = _FakeMcpConnectionNotifier();

      container = ProviderContainer(
        overrides: [
          toolsGroupsRepositoryProvider.overrideWithValue(
            toolsGroupsRepository,
          ),
          workspaceToolsRepositoryProvider.overrideWithValue(
            workspaceToolsRepository,
          ),
          conversationToolsRepositoryProvider.overrideWithValue(
            conversationToolsRepository,
          ),
          mcpConnectionProvider.overrideWith(() => mcpNotifier),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'groups tools into built-in and native default groups',
      () async {
        workspaceToolsRepository.workspaceTools = [
          builtInTool,
          nativeTool,
        ];
        toolsGroupsRepository.groups = [];

        final result = await container.read(
          groupedConversationToolsProvider(
            workspaceId: 'workspace-1',
          ).future,
        );

        expect(result, hasLength(2));
        expect(
          result.any(
            (g) =>
                g.isDefaultGroup &&
                g.defaultGroupType == DefaultToolGroupType.builtIn,
          ),
          isTrue,
        );
        expect(
          result.any(
            (g) =>
                g.isDefaultGroup &&
                g.defaultGroupType == DefaultToolGroupType.native,
          ),
          isTrue,
        );
      },
    );

    test(
      'groups MCP tools under their group with connection state',
      () async {
        workspaceToolsRepository.workspaceTools = [groupedTool];
        toolsGroupsRepository.groups = [mcpGroup];

        final result = await container.read(
          groupedConversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).future,
        );

        expect(result, hasLength(1));
        expect(result.firstOrNull?.group?.id, 'group-1');
        expect(result.firstOrNull?.tools, hasLength(1));
      },
    );

    test('skips empty groups', () async {
      workspaceToolsRepository.workspaceTools = [builtInTool];
      toolsGroupsRepository.groups = [mcpGroup];

      final result = await container.read(
        groupedConversationToolsProvider(
          workspaceId: 'workspace-1',
        ).future,
      );

      expect(result, hasLength(1));
      expect(result.firstOrNull?.isDefaultGroup, isTrue);
    });

    test(
      'reconnectMcp delegates to McpConnectionNotifier',
      () async {
        workspaceToolsRepository.workspaceTools = [builtInTool];
        toolsGroupsRepository.groups = [];

        final notifier = container.read(
          groupedConversationToolsProvider(
            workspaceId: 'workspace-1',
          ).notifier,
        );
        final _ = await container.read(
          groupedConversationToolsProvider(
            workspaceId: 'workspace-1',
          ).future,
        );

        await notifier.reconnectMcp('server-1');

        expect(mcpNotifier.reconnectedServerIds, ['server-1']);
      },
    );

    test(
      'toggleGroupTools with null groupId and defaultGroupType enables tools',
      () async {
        workspaceToolsRepository.workspaceTools = [builtInTool, nativeTool];
        toolsGroupsRepository.groups = [];
        conversationToolsRepository.setEnabledResult = true;

        final notifier = container.read(
          groupedConversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).notifier,
        );
        final _ = await container.read(
          groupedConversationToolsProvider(
            workspaceId: 'workspace-1',
            conversationId: 'conv-1',
          ).future,
        );

        await notifier.toggleGroupTools(
          null,
          enabled: true,
          defaultGroupType: DefaultToolGroupType.builtIn,
        );

        expect(
          conversationToolsRepository.enabledToolIds,
          contains('tool-1'),
        );
      },
    );
  });
}

class _FakeToolsGroupsRepository implements ToolsGroupsRepository {
  List<ToolsGroupEntity> groups = [];

  @override
  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(
    String workspaceId,
  ) async {
    return groups;
  }

  @override
  Future<ToolsGroupEntity?> getToolsGroupById(String id) async {
    return groups.where((g) => g.id == id).firstOrNull;
  }

  @override
  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(
    String mcpServerId,
  ) async {
    return groups.where((g) => g.mcpServerId == mcpServerId).firstOrNull;
  }

  @override
  Future<bool> setToolsGroupEnabled(
    String groupId, {
    required bool isEnabled,
  }) async {
    return true;
  }

  @override
  Future<bool> deleteToolsGroup(String id) async {
    return true;
  }
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
  Future<String?> getWorkspaceToolConfig(String workspaceId, String toolType) {
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

class _FakeConversationToolsRepository implements ConversationToolsRepository {
  bool setEnabledResult = true;
  final List<String> enabledToolIds = [];

  @override
  Future<bool> setConversationToolEnabled(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) async {
    if (isEnabled) {
      enabledToolIds.add(toolId);
    }
    return setEnabledResult;
  }

  @override
  Future<List<ConversationToolEntity>> getConversationTools(
    String conversationId,
  ) async {
    return [];
  }

  @override
  Future<ToolPermissionResult> checkToolPermission({
    required String conversationId,
    required String workspaceId,
    required String toolId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getAvailableToolsForConversation(
    String conversationId,
    String workspaceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationToolEntity?> getConversationTool(
    String conversationId,
    String toolId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getConversationToolsCount(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ConversationToolEntity>> getEnabledConversationTools(
    String conversationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getEnabledConversationToolsCount(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isConversationToolEnabled(
    String conversationId,
    String toolId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isToolAvailableForConversation(
    String conversationId,
    String workspaceId,
    String toolId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeConversationTool(String conversationId, String toolId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setConversationToolPermission(
    String conversationId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> setConversationToolsDisabled(
    String conversationId,
    List<String> toolIds,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> toggleConversationTool(String conversationId, String toolId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateConversationToolSetting(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) {
    throw UnimplementedError();
  }
}

class _FakeMcpConnectionNotifier extends McpConnectionNotifier {
  final List<String> reconnectedServerIds = [];

  @override
  List<McpConnectionState> build() => const [];

  @override
  Future<void> reconnectMcpServer(String serverId) async {
    reconnectedServerIds.add(serverId);
  }
}
