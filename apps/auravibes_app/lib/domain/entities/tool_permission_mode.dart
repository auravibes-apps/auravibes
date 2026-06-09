// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_permission_mode.freezed.dart';

/// Permission mode for tool execution.
enum ToolPermissionMode {
  /// Always ask user for permission before executing.
  alwaysAsk,

  /// Always allow tool execution without asking.
  alwaysAllow,
}

/// Entity representing a tool setting for a specific workspace.
///
/// This represents user preferences for tools at the workspace level,
/// allowing different workspaces to have different tool configurations.
@freezed
abstract class WorkspaceToolEntity with _$WorkspaceToolEntity {
  /// Creates a new WorkspaceTool instance.
  const factory WorkspaceToolEntity({
    /// Unique ID of this tool record in the database.
    required String id,

    /// ID of the workspace this tool setting belongs to.
    required String workspaceId,

    /// Tool identifier (for example, 'web_search', 'calculator', etc).
    required String toolId,

    /// Whether the tool is enabled for this workspace.
    required bool isEnabled,

    /// Permission mode for this tool (always ask or always allow).
    required ToolPermissionMode permissionMode,

    /// Timestamp when this setting was created.
    required DateTime createdAt,

    /// Timestamp when this setting was last updated.
    required DateTime updatedAt,

    /// Tool configuration as JSON (optional).
    String? config,

    /// Optional description of the tool (from MCP or user-defined).
    String? description,

    /// JSON schema for input parameters (for MCP tools).
    String? inputSchema,

    /// Optional reference to the tools group this tool belongs to.
    String? workspaceToolsGroupId,
  }) = _WorkspaceToolEntity;
  const WorkspaceToolEntity._();

  /// Returns true if the tool has custom configuration.
  bool get hasConfig => config?.isNotEmpty ?? false;

  /// Returns true if the tool is currently enabled.
  bool get isAvailable => isEnabled;

  /// Returns true if this tool belongs to a group.
  bool get belongsToGroup => workspaceToolsGroupId?.isNotEmpty ?? false;

  /// Returns true if this tool has a description.
  bool get hasDescription => description?.isNotEmpty ?? false;

  /// Returns true if this tool has an input schema (MCP tool).
  bool get hasInputSchema => inputSchema?.isNotEmpty ?? false;

  UserToolType? get buildInType {
    return UserToolType.fromValue(toolId);
  }

  NativeToolType? get nativeType {
    return NativeToolType.fromValue(toolId);
  }

  bool get isNative => nativeType != null;
}

/// Entity for creating/updating workspace tool settings.
@freezed
abstract class WorkspaceToolToCreate with _$WorkspaceToolToCreate {
  /// Creates a new WorkspaceToolToCreate instance.
  const factory WorkspaceToolToCreate({
    /// Tool identifier (for example, 'web_search', 'calculator', etc).
    required String toolId,

    /// Tool configuration as JSON (optional).
    String? config,

    /// Whether the tool should be enabled (defaults to true).
    bool? isEnabled,

    /// Optional description of the tool.
    String? description,

    /// JSON schema for input parameters (for MCP tools).
    String? inputSchema,

    /// Optional reference to the tools group this tool belongs to.
    String? workspaceToolsGroupId,
  }) = _WorkspaceToolToCreate;
  const WorkspaceToolToCreate._();

  /// Returns true if the tool type is valid.
  bool get hasValidToolId => toolId.isNotEmpty;

  /// Returns the default enabled status (true if not specified).
  bool get defaultEnabled => isEnabled ?? true;

  /// Returns true if the tool configuration is valid.
  bool get hasValidConfig => hasValidToolId;
}
