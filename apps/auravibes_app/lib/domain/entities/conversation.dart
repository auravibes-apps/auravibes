import 'dart:convert';

import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// Entity representing a conversation in the Aura application.
///
/// A conversation is a container for organizing and managing
/// chat messages within a specific workspace.
///
@freezed
abstract class ConversationEntity with _$ConversationEntity {
  const factory ConversationEntity({
    /// Unique identifier for the conversation
    required String id,

    /// Human-readable title of the conversation
    required String title,

    /// ID of the workspace this conversation belongs to
    required String workspaceId,

    /// Whether this conversation is pinned
    required bool isPinned,

    /// Timestamp when the conversation was created
    required DateTime createdAt,

    /// Timestamp when the conversation was last updated
    required DateTime updatedAt,

    /// ID of the AI model used for this conversation
    String? modelId,
  }) = _ConversationEntity;
  const ConversationEntity._();

  /// Returns true if the conversation has a valid title
  bool get hasValidTitle => title.isNotEmpty;

  /// Returns true if the conversation is in a valid state
  bool get isValid {
    return hasValidTitle && workspaceId.isNotEmpty;
  }
}

@freezed
abstract class ConversationToCreate with _$ConversationToCreate {
  const factory ConversationToCreate({
    /// Human-readable title of the conversation
    required String title,

    /// ID of the workspace this conversation belongs to
    required String workspaceId,

    /// ID of the AI model used for this conversation
    String? modelId,

    /// Whether this conversation is pinned
    bool? isPinned,
  }) = _ConversationToCreate;
  const ConversationToCreate._();

  /// Returns true if the conversation has a valid title
  bool get hasValidTitle => title.isNotEmpty;

  /// Returns true if the conversation is in a valid state
  bool get isValid {
    return hasValidTitle && workspaceId.isNotEmpty;
  }
}

@freezed
abstract class ConversationToUpdate with _$ConversationToUpdate {
  const factory ConversationToUpdate({
    /// Human-readable title of the conversation
    String? title,

    /// ID of the AI model used for this conversation
    String? modelId,

    /// Whether this conversation is pinned
    bool? isPinned,
  }) = _ConversationToUpdate;
  const ConversationToUpdate._();

  bool get isValid {
    if (title != null && title!.isEmpty) return false;
    if (modelId != null && modelId!.isEmpty) return false;
    return title != null || modelId != null || isPinned != null;
  }
}

@freezed
abstract class MessageToolCallEntity with _$MessageToolCallEntity {
  const factory MessageToolCallEntity({
    required String id,
    required String name,
    required String argumentsRaw,

    /// The raw response from tool execution, if successful.
    String? responseRaw,

    /// The result status of this tool call.
    ///
    /// - null: Tool is pending or currently running
    /// - non-null: Tool has completed with this result status
    // ignore: invalid_annotation_target
    @JsonKey(
      fromJson: _toolCallResultStatusFromJson,
      toJson: _toolCallResultStatusToJson,
    )
    ToolCallResultStatus? resultStatus,
  }) = _MessageToolCallEntity;
  const MessageToolCallEntity._();

  factory MessageToolCallEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageToolCallEntityFromJson(json);

  Map<String, dynamic> get arguments {
    return safeJsonDecode(argumentsRaw) ?? {};
  }

  /// Whether this tool call has been resolved (success or failure).
  bool get isResolved => resultStatus != null;

  /// Whether this tool call is still pending (waiting for permission or execution).
  bool get isPending => resultStatus == null;

  /// Gets the response to send to the AI.
  ///
  /// Returns [responseRaw] if available, otherwise falls back to
  /// the result status's response string.
  String getResponseForAI() {
    return responseRaw ?? resultStatus?.toResponseString() ?? '';
  }
}

ToolCallResultStatus? _toolCallResultStatusFromJson(String? json) {
  return const ToolCallResultStatusConverter().fromJson(json);
}

String? _toolCallResultStatusToJson(ToolCallResultStatus? status) {
  return const ToolCallResultStatusConverter().toJson(status);
}

@freezed
abstract class MessageMetadataEntity with _$MessageMetadataEntity {
  const factory MessageMetadataEntity({
    @Default(<MessageToolCallEntity>[]) List<MessageToolCallEntity> toolCalls,
  }) = _MessageMetadataEntity;

  factory MessageMetadataEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageMetadataEntityFromJson(json);

  static MessageMetadataEntity? fromJsonString(String? metadata) {
    if (metadata == null) return null;
    try {
      final json = jsonDecode(metadata) as Map<String, dynamic>;
      return MessageMetadataEntity.fromJson(json);
    } on Exception catch (_) {
      return null;
    }
  }
}

/// Entity representing a message in a conversation.
///
/// A message contains the actual content and metadata
/// for communication within a conversation.
@freezed
abstract class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    /// Unique identifier for the message
    required String id,

    /// ID of the conversation this message belongs to
    required String conversationId,

    /// Content of the message (JSON structure based on message type)
    required String content,

    /// Type of the message
    required MessageType messageType,

    /// Whether this message was sent by the user
    required bool isUser,

    /// Status of the message
    required MessageStatus status,

    /// Timestamp when the message was created
    required DateTime createdAt,

    /// Timestamp when the message was last updated
    required DateTime updatedAt,

    /// Additional metadata for the message (JSON)
    MessageMetadataEntity? metadata,
  }) = _MessageEntity;
  const MessageEntity._();

  /// Returns true if the message has valid content
  bool get hasValidContent => content.isNotEmpty;

  /// Returns true if the message is in a valid state
  bool get isValid {
    return hasValidContent && conversationId.isNotEmpty;
  }
}

/// Entity for creating a new message
@freezed
abstract class MessageToCreate with _$MessageToCreate {
  /// Creates a new MessageToCreate instance
  const factory MessageToCreate({
    /// ID of the conversation this message belongs to
    required String conversationId,

    /// Content of the message (JSON structure based on message type)
    required String content,

    /// Type of the message
    required MessageType messageType,

    /// Whether this message was sent by the user
    required bool isUser,

    required MessageStatus status,

    /// Additional metadata for the message (JSON)
    String? metadata,
  }) = _MessageToCreate;
  const MessageToCreate._();

  /// Returns true if the message has valid content
  bool get hasValidContent {
    return !(status == MessageStatus.sent && content.isNotEmpty);
  }

  /// Returns true if the message is in a valid state
  bool get isValid {
    return hasValidContent && conversationId.isNotEmpty;
  }
}

/// Entity for creating a new message
@freezed
abstract class MessageToUpdate with _$MessageToUpdate {
  /// Creates a new MessageToUpdate instance
  const factory MessageToUpdate({
    /// Content of the message (JSON structure based on message type)
    String? content,

    /// Additional metadata for the message (JSON)
    MessageMetadataEntity? metadata,

    MessageStatus? status,
  }) = _MessageToUpdate;
  const MessageToUpdate._();

  /// Returns true if the message is in a valid state
  bool get isValid {
    return content != null || metadata != null || status != null;
  }
}
