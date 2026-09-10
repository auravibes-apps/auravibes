// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'grouped_conversation_tools_notifier.g.dart';

/// Provider that groups conversation tools by their workspaceToolsGroupId.
///
/// This provider fetches conversation tool states and tool groups for the
/// workspace, groups them by workspaceToolsGroupId, creates a Built-in Tools
/// group for ungrouped tools, enriches MCP groups with connection state,
/// filters empty groups, and sorts default, error, and newest groups first.
@riverpod
class GroupedConversationToolsNotifier
    extends _$GroupedConversationToolsNotifier {
  @override
  Future<List<ConversationToolsGroupWithTools>> build({
    required String workspaceId,
    String? conversationId,
  }) async {
    await _syncConversationSkillPermissions(ref, workspaceId, conversationId);
    final conversationTools = await _loadConversationTools(
      ref,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    final groups = await _loadWorkspaceGroups(ref, workspaceId);

    return _buildGroups(
      conversationTools: conversationTools,
      groups: groups,
      mcpConnections: ref.watch(mcpConnectionProvider),
    );
  }

  /// Toggle all tools in a group at once.
  ///
  /// When [enabled] is true, enables all tools in the group.
  /// When [enabled] is false, disables all tools in the group.
  /// Preserves the permission mode of each tool.
  Future<void> toggleGroupTools(
    String? groupId, {
    required bool enabled,
    DefaultToolGroupType? defaultGroupType,
  }) async {
    final conversationNotifier = ref.read(
      conversationToolsProvider(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ).notifier,
    );

    final group = _findConversationGroup(
      state.value ?? [],
      groupId,
      defaultGroupType,
    );
    if (group == null) return;

    await _toggleGroupTools(
      group,
      conversationNotifier.setToolEnabled,
      enabled: enabled,
    );

    // The state will be automatically refreshed via the watch on.
    // ConversationToolsProvider.
  }

  /// Reconnect to an MCP server.
  Future<void> reconnectMcp(String mcpServerId) async {
    await ref
        .read(mcpConnectionProvider.notifier)
        .reconnectMcpServer(mcpServerId);
  }

  List<ConversationToolsGroupWithTools> _buildGroups({
    required List<ConversationToolState> conversationTools,
    required List<ToolsGroupEntity> groups,
    required List<McpConnectionState> mcpConnections,
  }) {
    final toolsByGroupId = _groupToolsById(conversationTools);

    return _buildDefaultGroups(toolsByGroupId[null] ?? [])
      ..addAll(
        _buildCustomGroups(
          groups: groups,
          toolsByGroupId: toolsByGroupId,
          mcpConnections: mcpConnections,
        ),
      )
      ..sort(_compareGroups);
  }

  Map<String?, List<ConversationToolState>> _groupToolsById(
    List<ConversationToolState> conversationTools,
  ) {
    final toolsByGroupId = <String?, List<ConversationToolState>>{};
    for (final toolState in conversationTools) {
      final groupId = toolState.tool.workspaceToolsGroupId;
      toolsByGroupId.putIfAbsent(groupId, () => []).add(toolState);
    }

    return toolsByGroupId;
  }

  List<ConversationToolsGroupWithTools> _buildDefaultGroups(
    List<ConversationToolState> defaultTools,
  ) {
    return [
      _conversationDefaultGroup(
        defaultTools,
        isNative: false,
        groupType: .builtIn,
      ),
      _conversationDefaultGroup(
        defaultTools,
        isNative: true,
        groupType: .native,
      ),
    ].whereType<ConversationToolsGroupWithTools>().toList();
  }

  List<ConversationToolsGroupWithTools> _buildCustomGroups({
    required List<ToolsGroupEntity> groups,
    required Map<String?, List<ConversationToolState>> toolsByGroupId,
    required List<McpConnectionState> mcpConnections,
  }) {
    final result = <ConversationToolsGroupWithTools>[];
    for (final group in groups) {
      final tools = toolsByGroupId[group.id] ?? [];
      if (tools.isEmpty) continue;

      result.add(
        ConversationToolsGroupWithTools(
          group: group,
          tools: tools,
          mcpConnectionState: _findMcpConnection(group, mcpConnections),
        ),
      );
    }

    return result;
  }

  McpConnectionState? _findMcpConnection(
    ToolsGroupEntity group,
    List<McpConnectionState> mcpConnections,
  ) {
    if (!group.isMcpGroup || group.mcpServerId == null) return null;

    return mcpConnections
        .where((connection) => connection.server.id == group.mcpServerId)
        .firstOrNull;
  }

  int _compareGroups(
    ConversationToolsGroupWithTools a,
    ConversationToolsGroupWithTools b,
  ) {
    final priorityCompare = a.sortPriority.compareTo(b.sortPriority);
    if (priorityCompare != 0) return priorityCompare;

    // Same priority. Sort by createdAt descending, with newest first.
    // The default group has no createdAt, so use a far-future date to keep it
    // first.
    final aDate = a.group?.createdAt ?? DateTime(2099);
    final bDate = b.group?.createdAt ?? DateTime(2099);

    return bDate.compareTo(aDate);
  }
}

ConversationToolsGroupWithTools? _conversationDefaultGroup(
  List<ConversationToolState> tools, {
  required bool isNative,
  required DefaultToolGroupType groupType,
}) {
  final matchingTools = tools
      .where((toolState) => toolState.tool.isNative == isNative)
      .toList();
  if (matchingTools.isEmpty) return null;

  return ConversationToolsGroupWithTools(
    group: null,
    tools: matchingTools,
    defaultGroupType: groupType,
  );
}

Future<void> _syncConversationSkillPermissions(
  Ref ref,
  String workspaceId,
  String? conversationId,
) async {
  if (conversationId == null || conversationId.isEmpty) return;
  await ref
      .read(syncSkillToolPermissionsUsecaseProvider)
      .call(conversationId: conversationId, workspaceId: workspaceId);
}

Future<List<ConversationToolState>> _loadConversationTools(
  Ref ref, {
  required String workspaceId,
  required String? conversationId,
}) => ref.watch(
  conversationToolsProvider(
    workspaceId: workspaceId,
    conversationId: conversationId,
  ).future,
);

Future<List<ToolsGroupEntity>> _loadWorkspaceGroups(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final repository = ref.watch(toolsGroupsRepositoryProvider(session));
  return repository.getToolsGroupsForWorkspace(workspaceId);
}

ConversationToolsGroupWithTools? _findConversationGroup(
  List<ConversationToolsGroupWithTools> groups,
  String? groupId,
  DefaultToolGroupType? defaultGroupType,
) => groups.firstWhereOrNull(
  (group) =>
      group.group?.id == groupId ||
      (groupId == null &&
          group.isDefaultGroup &&
          group.defaultGroupType == defaultGroupType),
);

Future<void> _toggleGroupTools(
  ConversationToolsGroupWithTools group,
  Future<void> Function(String, {required bool isEnabled}) setToolEnabled, {
  required bool enabled,
}) async {
  for (final toolState in group.tools) {
    await setToolEnabled(toolState.tool.id, isEnabled: enabled);
  }
}
