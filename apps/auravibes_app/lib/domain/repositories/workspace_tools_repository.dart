import 'package:auravibes_app/domain/entities/workspace_tool.dart';

/// Repository interface for workspace tool data operations.
///
/// This abstract class defines the contract for workspace tool settings access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic validation for workspace tool operations.
abstract class WorkspaceToolsRepository {
  /// Retrieves all workspace tool settings for a specific workspace.
  ///
  /// [workspaceId] The ID of the workspace to retrieve tools for.
  /// Returns a list of workspace tool settings ordered by tool type.
  /// Throws [WorkspaceToolsException] if there's an error retrieving tools.
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(String workspaceId);

  /// Retrieves enabled workspace tool settings for a specific workspace.
  ///
  /// [workspaceId] The ID of the workspace to retrieve enabled tools for.
  /// Returns a list of enabled workspace tool settings ordered by tool type.
  /// Throws [WorkspaceToolsException] if there's an error retrieving tools.
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  );

  /// Retrieves a specific workspace tool setting.
  ///
  /// [workspaceId] The ID of the workspace.
  /// [toolType] The type of tool to retrieve.
  /// Returns the workspace tool setting, or null if not found.
  /// Throws [WorkspaceToolsException] if there's an error retrieving the tool.
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolType,
  );

  /// Enables or disables a tool for a workspace.
  ///
  /// [workspaceId] The ID of the workspace.
  /// [toolType] The type of tool to toggle.
  /// [isEnabled] Whether the tool should be enabled.
  /// Returns true if the operation was successful, false if the tool
  /// was not found.
  /// Throws [WorkspaceToolsException] if there's an error updating the tool.
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
  });

  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  });

  /// Enables or disables a tool by its unique database ID.
  ///
  /// [id] The unique ID of the tool record in the database.
  /// [isEnabled] Whether the tool should be enabled.
  /// Returns the updated workspace tool entity.
  /// Throws [WorkspaceToolsException] if there's an error updating the tool.
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  });

  /// Updates the configuration for a workspace tool.
  ///
  /// [workspaceId] The ID of the workspace.
  /// [toolType] The type of tool to update.
  /// [config] The new configuration as JSON string.
  /// Returns true if the operation was successful, false if the tool
  /// was not found.
  /// Throws [WorkspaceToolsException] if there's an error updating the tool.
  Future<List<WorkspaceToolEntity>> updateWorkspaceToolConfig(
    String workspaceId,
    String toolType,
    String? config,
  );

  /// Checks if a specific tool is enabled for a workspace.
  ///
  /// [workspaceId] The ID of the workspace.
  /// [toolType] The type of tool to check.
  /// Returns true if the tool is enabled, false otherwise.
  /// Throws [WorkspaceToolsException] if there's an error checking
  /// the tool status.
  Future<bool> isWorkspaceToolEnabled(String workspaceId, String toolType);

  /// Gets the configuration for a workspace tool.
  ///
  /// [workspaceId] The ID of the workspace.
  /// [toolType] The type of tool to get configuration for.
  /// Returns the tool configuration as a JSON string, or null if
  ///  not found or no config exists.
  /// Throws [WorkspaceToolsException] if there's an error retrieving
  /// the configuration.
  Future<String?> getWorkspaceToolConfig(String workspaceId, String toolType);

  /// Removes a tool setting for a workspace.
  ///
  /// [workspaceId] The ID of the workspace.
  /// [toolType] The type of tool to remove.
  /// Returns true if the operation was successful, false if the
  /// tool was not found.
  /// Throws [WorkspaceToolsException] if there's an error removing the tool.
  Future<bool> removeWorkspaceTool(String workspaceId, String toolType);

  /// Removes a tool setting by its unique database ID.
  ///
  /// [id] The unique ID of the tool record in the database.
  /// Returns true if the operation was successful, false if the
  /// tool was not found.
  /// Throws [WorkspaceToolsException] if there's an error removing the tool.
  Future<bool> removeWorkspaceToolById(String id);

  /// Gets the total count of tools configured for a workspace.
  ///
  /// [workspaceId] The ID of the workspace.
  /// Returns the total number of tools configured for the workspace.
  /// Throws [WorkspaceToolsException] if there's an error counting tools.
  Future<int> getWorkspaceToolsCount(String workspaceId);

  /// Gets the count of enabled tools for a workspace.
  ///
  /// [workspaceId] The ID of the workspace.
  /// Returns the number of enabled tools for the workspace.
  /// Throws [WorkspaceToolsException] if there's an error counting tools.
  Future<int> getEnabledWorkspaceToolsCount(String workspaceId);

  /// Copies workspace tools to a conversation.
  ///
  /// [workspaceId] The ID of the source workspace.
  /// [conversationId] The ID of the target conversation.
  /// Copies all workspace tool settings to the conversation as
  ///  a starting point.
  /// Throws [WorkspaceToolsException] if there's an error copying tools.
  Future<void> copyWorkspaceToolsToConversation(
    String workspaceId,
    String conversationId,
  );

  /// Validates a workspace tool setting before creation or update.
  ///
  /// [workspaceId] The ID of the workspace (for validation).
  /// [toolType] The type of tool to validate.
  /// [isEnabled] Whether the tool should be enabled.
  /// [config] The tool configuration to validate.
  /// Returns true if the tool setting is valid.
  /// Throws [WorkspaceToolsValidationException] if the tool setting is invalid.
  Future<bool> validateWorkspaceToolSetting(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
    String? config,
  });

  /// Sets the permission mode for a workspace tool.
  ///
  /// [id] The unique ID of the tool record in the database.
  /// [permissionMode] The permission mode to set.
  /// Returns the updated workspace tool entity.
  /// Throws [WorkspaceToolsException] if there's an error updating the tool.
  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  });
}

/// Base exception for workspace tools-related operations.
class WorkspaceToolsException implements Exception {
  /// Creates a new WorkspaceToolsException
  const WorkspaceToolsException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'WorkspaceToolsException: $message$causedBy';
  }
}

/// Exception thrown when workspace tool validation fails.
class WorkspaceToolsValidationException extends WorkspaceToolsException {
  /// Creates a new WorkspaceToolsValidationException
  const WorkspaceToolsValidationException(super.message, [super.cause]);
}

/// Exception thrown when a workspace tool is not found.
class WorkspaceToolNotFoundException extends WorkspaceToolsException {
  /// Creates a new WorkspaceToolNotFoundException
  const WorkspaceToolNotFoundException(
    this.workspaceId,
    this.toolType, [
    Exception? cause,
  ]) : super(
         'Workspace tool "$toolType" not found in workspace "$workspaceId"',
         cause,
       );

  /// ID of the workspace
  final String workspaceId;

  /// Type of the tool that was not found
  final String toolType;
}
