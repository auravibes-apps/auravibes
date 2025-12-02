import 'package:auravibes_app/domain/entities/conversation_tool.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';

/// Repository interface for conversation tool data operations.
///
/// This abstract class defines the contract for conversation tool
/// settings access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic validation for conversation tool operations.
abstract class ConversationToolsRepository {
  /// Retrieves all conversation tool settings for a specific conversation.
  ///
  /// [conversationId] The ID of the conversation to retrieve tools for.
  /// Returns a list of conversation tool settings ordered by tool type.
  /// Throws [ConversationToolsException] if there's an error retrieving tools.
  Future<List<ConversationToolEntity>> getConversationTools(
    String conversationId,
  );

  /// Retrieves enabled conversation tool settings for a specific conversation.
  ///
  /// [conversationId] The ID of the conversation to retrieve enabled tools for.
  /// Returns a list of enabled conversation tool settings ordered by tool type.
  /// Throws [ConversationToolsException] if there's an error retrieving tools.
  Future<List<ConversationToolEntity>> getEnabledConversationTools(
    String conversationId,
  );

  /// Retrieves a specific conversation tool setting.
  ///
  /// [conversationId] The ID of the conversation.
  /// [toolType] The type of tool to retrieve.
  /// Returns the conversation tool setting, or null if not found.
  /// Throws [ConversationToolsException] if there's an error
  /// retrieving the tool.
  Future<ConversationToolEntity?> getConversationTool(
    String conversationId,
    String toolType,
  );

  /// Enables or disables a tool for a conversation.
  ///
  /// [conversationId] The ID of the conversation.
  /// [toolType] The type of tool to toggle.
  /// [isEnabled] Whether the tool should be enabled.
  /// Returns true if the operation was successful, false if the
  ///  tool was not found.
  /// Throws [ConversationToolsException] if there's an error updating the tool.
  Future<bool> setConversationToolEnabled(
    String conversationId,
    String toolType, {
    required bool isEnabled,
  });

  Future<void> setConversationToolsDisabled(
    String conversationId,
    List<String> toolTypes,
  );

  /// Sets the permission mode for a conversation tool.
  ///
  /// [conversationId] The ID of the conversation.
  /// [toolType] The type of tool to update.
  /// [permissionMode] The permission mode to set.
  /// Returns true if the operation was successful.
  /// Throws [ConversationToolsException] if there's an error updating the tool.
  Future<bool> setConversationToolPermission(
    String conversationId,
    String toolType, {
    required ToolPermissionMode permissionMode,
  });

  /// Toggles the enabled status of a conversation tool.
  ///
  /// [conversationId] The ID of the conversation.
  /// [toolType] The type of tool to toggle.
  /// Returns true if the operation was successful, false if the
  /// tool was not found.
  /// Throws [ConversationToolsException] if there's an error toggling the tool.
  Future<bool> toggleConversationTool(String conversationId, String toolType);

  /// Checks if a specific tool is enabled for a conversation.
  ///
  /// [conversationId] The ID of the conversation.
  /// [toolType] The type of tool to check.
  /// Returns true if the tool is enabled, false otherwise.
  /// Throws [ConversationToolsException] if there's an error
  /// checking the tool status.
  Future<bool> isConversationToolEnabled(
    String conversationId,
    String toolType,
  );

  /// Removes a tool setting for a conversation.
  ///
  /// [conversationId] The ID of the conversation.
  /// [toolType] The type of tool to remove.
  /// Returns true if the operation was successful, false
  /// if the tool was not found.
  /// Throws [ConversationToolsException] if there's an error removing the tool.
  Future<bool> removeConversationTool(String conversationId, String toolType);

  /// Gets the total count of tools configured for a conversation.
  ///
  /// [conversationId] The ID of the conversation.
  /// Returns the total number of tools configured for the conversation.
  /// Throws [ConversationToolsException] if there's an error counting tools.
  Future<int> getConversationToolsCount(String conversationId);

  /// Gets the count of enabled tools for a conversation.
  ///
  /// [conversationId] The ID of the conversation.
  /// Returns the number of enabled tools for the conversation.
  /// Throws [ConversationToolsException] if there's an error counting tools.
  Future<int> getEnabledConversationToolsCount(String conversationId);

  /// Copies all tools from one conversation to another.
  ///
  /// [sourceConversationId] The ID of the source conversation.
  /// [targetConversationId] The ID of the target conversation.
  /// Copies all tool settings from source to target conversation.
  /// Throws [ConversationToolsException] if there's an error copying tools.
  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  );

  /// Validates a conversation tool setting before creation or update.
  ///
  /// [conversationId] The ID of the conversation (for validation).
  /// [toolType] The type of tool to validate.
  /// [isEnabled] Whether the tool should be enabled.
  /// Returns true if the tool setting is valid.
  /// Throws [ConversationToolsValidationException] if
  /// the tool setting is invalid.
  Future<bool> validateConversationToolSetting(
    String conversationId,
    String toolType, {
    required bool isEnabled,
  });

  /// Gets the effective tool availability for a conversation.
  ///
  /// This method checks if a tool is available for a conversation
  /// by considering
  /// both conversation-level overrides and workspace-level settings.
  /// [conversationId] The ID of the conversation.
  /// [workspaceId] The ID of the workspace the conversation belongs to.
  /// [toolType] The type of tool to check.
  /// Returns true if the tool is available for the conversation.
  /// Throws [ConversationToolsException] if there's an
  /// error checking tool availability.
  Future<bool> isToolAvailableForConversation(
    String conversationId,
    String workspaceId,
    String toolType,
  );

  /// Gets all available tools for a conversation.
  ///
  /// This method returns the effective list of available tools
  /// for a conversation
  /// by considering conversation overrides, workspace settings,
  /// and app defaults.
  /// [conversationId] The ID of the conversation.
  /// [workspaceId] The ID of the workspace the conversation belongs to.
  /// Returns a list of tool types that are available for the conversation.
  /// Throws [ConversationToolsException] if there's an error
  /// getting available tools.
  Future<List<String>> getAvailableToolsForConversation(
    String conversationId,
    String workspaceId,
  );

  /// Checks the permission for a specific tool in a conversation context.
  ///
  /// This method implements the permission logic:
  /// 1. Tool must exist and be enabled in workspace (isEnabled = true)
  /// 2. Conversation rules take priority over workspace rules
  /// 3. Conversation can restrict (disable/ask) but cannot enable a disabled
  ///    workspace tool
  ///
  /// [conversationId] The ID of the conversation.
  /// [workspaceId] The ID of the workspace the conversation belongs to.
  /// [toolId] The identifier of the tool to check.
  /// Returns [ToolPermissionResult] indicating whether the tool can be
  /// executed, needs confirmation, or should be skipped.
  /// Throws [ConversationToolsException] if there's an error checking
  /// permissions.
  Future<ToolPermissionResult> checkToolPermission({
    required String conversationId,
    required String workspaceId,
    required String toolId,
  });
}

/// Base exception for conversation tools-related operations.
class ConversationToolsException implements Exception {
  /// Creates a new ConversationToolsException
  const ConversationToolsException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'ConversationToolsException: $message$causedBy';
  }
}

/// Exception thrown when conversation tool validation fails.
class ConversationToolsValidationException extends ConversationToolsException {
  /// Creates a new ConversationToolsValidationException
  const ConversationToolsValidationException(super.message, [super.cause]);
}

/// Exception thrown when a conversation tool is not found.
class ConversationToolNotFoundException extends ConversationToolsException {
  /// Creates a new ConversationToolNotFoundException
  const ConversationToolNotFoundException(
    this.conversationId,
    this.toolType, [
    Exception? cause,
  ]) : super(
         '''
Conversation tool "$toolType" not found in conversation "$conversationId"
''',
         cause,
       );

  /// ID of the conversation
  final String conversationId;

  /// Type of the tool that was not found
  final String toolType;
}
