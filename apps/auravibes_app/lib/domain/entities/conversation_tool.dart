import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_tool.freezed.dart';

/// Entity representing a tool setting for a specific conversation.
///
/// This represents user preferences for tools at the conversation level,
/// allowing different conversations to override workspace tool settings.
@freezed
abstract class ConversationToolEntity with _$ConversationToolEntity {
  /// Creates a new ConversationTool instance
  const factory ConversationToolEntity({
    /// ID of the conversation this tool setting belongs to
    required String conversationId,

    /// tool identificator (e.g., 'web_search', 'calculator', etc.)
    required String toolId,

    /// Whether the tool is enabled for this conversation
    required bool isEnabled,

    /// Permission mode for this tool (always ask or always allow)
    required ToolPermissionMode permissionMode,

    /// Timestamp when this setting was created
    required DateTime createdAt,

    /// Timestamp when this setting was last updated
    required DateTime updatedAt,
  }) = _ConversationToolEntity;
  const ConversationToolEntity._();

  /// Returns true if the tool is currently enabled
  bool get isAvailable => isEnabled;
}

/// Entity for creating/updating conversation tool settings
@freezed
abstract class ConversationToolToCreate with _$ConversationToolToCreate {
  /// Creates a new ConversationToolToCreate instance
  const factory ConversationToolToCreate({
    /// tool identificator (e.g., 'web_search', 'calculator', etc.)
    required String toolId,

    /// Whether the tool should be enabled (defaults to true)
    bool? isEnabled,

    /// Permission mode for this tool (defaults to alwaysAsk)
    ToolPermissionMode? permissionMode,
  }) = _ConversationToolToCreate;
  const ConversationToolToCreate._();

  /// Returns true if the tool type is valid
  bool get hasValidToolId => toolId.isNotEmpty;

  /// Returns the default enabled status (true if not specified)
  bool get defaultEnabled => isEnabled ?? true;

  /// Returns the default permission mode (alwaysAsk if not specified)
  ToolPermissionMode get defaultPermissionMode =>
      permissionMode ?? ToolPermissionMode.alwaysAsk;
}
