import 'package:auravibes_app/domain/entities/tools_group.dart';

/// Repository interface for managing tools groups.
///
/// Tools groups organize related tools together, such as tools from
/// a single MCP server or custom tool collections.
abstract class ToolsGroupsRepository {
  /// Get all tools groups for a workspace.
  ///
  /// Returns groups ordered by creation date (newest first).
  Future<List<ToolsGroupEntity>> getToolsGroupsForWorkspace(String workspaceId);

  /// Get a tools group by its ID.
  ///
  /// Returns null if no group with the given ID exists.
  Future<ToolsGroupEntity?> getToolsGroupById(String id);

  /// Get a tools group by its linked MCP server ID.
  ///
  /// Returns null if no group with the given MCP server ID exists.
  Future<ToolsGroupEntity?> getToolsGroupByMcpServerId(String mcpServerId);

  /// Set the enabled status of a tools group.
  ///
  /// When a group is disabled, all its tools are hidden from AI.
  /// Returns true if the update was successful.
  Future<bool> setToolsGroupEnabled(String groupId, {required bool isEnabled});

  /// Delete a tools group by ID.
  ///
  /// This will cascade delete all tools belonging to this group.
  /// Returns true if a group was deleted.
  Future<bool> deleteToolsGroup(String id);
}
