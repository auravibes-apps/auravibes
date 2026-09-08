import 'package:auravibes_app/domain/entities/tools_group_entity.dart';

/// Contract for tools group persistence.
abstract interface class ToolsGroupsRepositoryContract {
  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(String workspaceId);
  Future<ToolsGroupEntity?> getToolsGroupById(String id);
  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(String mcpServerId);
  Future<bool> setToolsGroupEnabled(String groupId, {required bool isEnabled});
  Future<bool> deleteToolsGroup(String id);
}
