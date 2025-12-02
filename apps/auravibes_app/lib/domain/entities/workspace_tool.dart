import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_tool.freezed.dart';

/// Entity representing a tool setting for a specific workspace.
///
/// This represents user preferences for tools at the workspace level,
/// allowing different workspaces to have different tool configurations.
@freezed
abstract class WorkspaceToolEntity with _$WorkspaceToolEntity {
  /// Creates a new WorkspaceTool instance
  const factory WorkspaceToolEntity({
    /// Unique ID of this tool record in the database
    required String id,

    /// ID of the workspace this tool setting belongs to
    required String workspaceId,

    /// Tool identifier (e.g., 'web_search', 'calculator', etc.)
    required String toolId,

    /// Whether the tool is enabled for this workspace
    required bool isEnabled,

    /// Timestamp when this setting was created
    required DateTime createdAt,

    /// Timestamp when this setting was last updated
    required DateTime updatedAt,

    /// Tool configuration as JSON (optional)
    String? config,
  }) = _WorkspaceToolEntity;
  const WorkspaceToolEntity._();

  /// Returns true if the tool has custom configuration
  bool get hasConfig => config != null && config!.isNotEmpty;

  /// Returns true if the tool is currently enabled
  bool get isAvailable => isEnabled;
}

/// Entity for creating/updating workspace tool settings
@freezed
abstract class WorkspaceToolToCreate with _$WorkspaceToolToCreate {
  /// Creates a new WorkspaceToolToCreate instance
  const factory WorkspaceToolToCreate({
    /// Tool identifier (e.g., 'web_search', 'calculator', etc.)
    required String toolId,

    /// Tool configuration as JSON (optional)
    String? config,

    /// Whether the tool should be enabled (defaults to true)
    bool? isEnabled,
  }) = _WorkspaceToolToCreate;
  const WorkspaceToolToCreate._();

  /// Returns true if the tool type is valid
  bool get hasValidToolId => toolId.isNotEmpty;

  /// Returns the default enabled status (true if not specified)
  bool get defaultEnabled => isEnabled ?? true;

  /// Returns true if the tool configuration is valid
  bool get hasValidConfig => hasValidToolId;
}
