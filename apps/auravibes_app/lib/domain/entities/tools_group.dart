import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tools_group.freezed.dart';

/// Entity representing a tools group for a specific workspace.
///
/// Tools groups organize related tools together, such as tools from
/// a single MCP server.
@freezed
abstract class ToolsGroupEntity with _$ToolsGroupEntity {
  /// Creates a new ToolsGroupEntity instance
  const factory ToolsGroupEntity({
    /// Unique ID of this tools group record in the database
    required String id,

    /// ID of the workspace this tools group belongs to
    required String workspaceId,

    /// Name of the tools group
    required String name,

    /// Whether the tools group is enabled for this workspace
    required bool isEnabled,

    /// Permission mode for tools in this group
    required PermissionAccess permissions,

    /// Timestamp when this group was created
    required DateTime createdAt,

    /// Timestamp when this group was last updated
    required DateTime updatedAt,

    /// Optional reference to the MCP server this group belongs to.
    /// If set, this group represents tools from an MCP server.
    String? mcpServerId,
  }) = _ToolsGroupEntity;
  const ToolsGroupEntity._();

  /// Returns true if this group is linked to an MCP server
  bool get isMcpGroup => mcpServerId != null && mcpServerId!.isNotEmpty;
}

/// Entity for creating/updating tools group settings
@freezed
abstract class ToolsGroupToCreate with _$ToolsGroupToCreate {
  /// Creates a new ToolsGroupToCreate instance
  const factory ToolsGroupToCreate({
    /// Name of the tools group
    required String name,

    /// Whether the tools group should be enabled (defaults to true)
    @Default(true) bool isEnabled,

    /// Permission mode for tools in this group (defaults to ask)
    @Default(PermissionAccess.ask) PermissionAccess permissions,

    /// Optional reference to the MCP server this group belongs to
    String? mcpServerId,
  }) = _ToolsGroupToCreate;
  const ToolsGroupToCreate._();

  /// Returns true if the name is valid
  bool get hasValidName => name.isNotEmpty;

  /// Returns true if the configuration is valid
  bool get isValid => hasValidName;
}
