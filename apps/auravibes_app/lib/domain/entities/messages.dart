import 'dart:convert';

import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'messages.freezed.dart';
part 'messages.g.dart';

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

  /// Whether this tool call is still pending
  /// (waiting for permission or execution).
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

@freezed
abstract class ToolToCall with _$ToolToCall {
  const factory ToolToCall({
    required ResolvedTool tool,
    required String id,
    required String argumentsRaw,
  }) = _ToolToCall;
  const ToolToCall._();
}
