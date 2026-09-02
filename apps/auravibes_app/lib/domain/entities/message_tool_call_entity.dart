// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';

import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_tool_call_entity.freezed.dart';
part 'message_tool_call_entity.g.dart';

@Freezed(toStringOverride: false)
abstract class MessageToolCallEntity with _$MessageToolCallEntity {
  const factory MessageToolCallEntity({
    required String id,
    required String name,
    required String argumentsRaw,
    @JsonKey(includeIfNull: false) String? argumentsDigest,
    @JsonKey(includeIfNull: false) String? turnId,
    @JsonKey(includeIfNull: false) int? turnRevision,

    /// The raw response from tool execution, if successful.
    String? responseRaw,

    /// The result status of this tool call.
    ///
    /// - null: Tool is awaiting approval
    /// - non-null: Tool is running or completed with this result status
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
  bool get isResolved => resultStatus?.agentLifecycle.isResolved ?? false;

  /// Whether this tool call is waiting for permission.
  bool get isAwaitingApproval => resultStatus == null;

  /// Whether this tool call is currently running.
  bool get isRunning => resultStatus?.agentLifecycle.isPending ?? false;

  /// Whether this tool call is still pending
  /// (waiting for permission or execution).
  bool get isPending => isAwaitingApproval || isRunning;

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

enum CompactionKind { manual, auto }

enum MessageAttachmentModality { image, audio, file }

@freezed
abstract class MessageAttachmentEntity with _$MessageAttachmentEntity {
  const factory MessageAttachmentEntity({
    required String id,
    required String messageId,
    required String localPath,
    required String fileName,
    required String displayName,
    required String mimeType,
    required MessageAttachmentModality modality,
    required int sizeBytes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MessageAttachmentEntity;
}

@freezed
abstract class MessageAttachmentToCreate with _$MessageAttachmentToCreate {
  const factory MessageAttachmentToCreate({
    required String localPath,
    required String fileName,
    required String displayName,
    required String mimeType,
    required MessageAttachmentModality modality,
    required int sizeBytes,
  }) = _MessageAttachmentToCreate;
}

@freezed
abstract class MessageMetadataEntity with _$MessageMetadataEntity {
  const factory MessageMetadataEntity({
    @Default(<MessageToolCallEntity>[]) List<MessageToolCallEntity> toolCalls,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    String? thinking,
    @Default(<String, Object?>{}) Map<String, Object?> modelMetadata,
    @Default(1) int metadataVersion,
    @Default(false) bool isCompactionSummary,
    CompactionKind? compactionKind,
    String? compactedFromMessageId,
    String? compactedThroughMessageId,
    @Default(<String>[]) List<String> compactedMessageIds,
    DateTime? compactionCreatedAt,
  }) = _MessageMetadataEntity;
  const MessageMetadataEntity._();

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

  int get usedTokens {
    return totalTokens ?? ((promptTokens ?? 0) + (completionTokens ?? 0));
  }
}

/// Entity representing a message in a conversation.
///
/// A message contains the actual content and metadata
/// for communication within a conversation.
@freezed
abstract class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    /// Unique identifier for the message.
    required String id,

    /// ID of the conversation this message belongs to.
    required String conversationId,

    /// Content of the message (JSON structure based on message type).
    required String content,

    /// Type of the message.
    required MessageType messageType,

    /// Whether this message was sent by the user.
    required bool isUser,

    /// Status of the message.
    required MessageStatus status,

    /// Timestamp when the message was created.
    required DateTime createdAt,

    /// Timestamp when the message was last updated.
    required DateTime updatedAt,

    /// Additional metadata for the message (JSON).
    MessageMetadataEntity? metadata,

    @Default(<MessageAttachmentEntity>[])
    List<MessageAttachmentEntity> attachments,
  }) = _MessageEntity;
  const MessageEntity._();

  /// Returns true if the message has valid content.
  bool get hasValidContent =>
      content.trim().isNotEmpty || attachments.isNotEmpty;

  /// Returns true if the message is in a valid state.
  bool get isValid {
    return hasValidContent && conversationId.isNotEmpty;
  }
}

/// Entity for creating a new message.
@freezed
abstract class MessageToCreate with _$MessageToCreate {
  /// Creates a new MessageToCreate instance.
  const factory MessageToCreate({
    /// ID of the conversation this message belongs to.
    required String conversationId,

    /// Content of the message (JSON structure based on message type).
    required String content,

    /// Type of the message.
    required MessageType messageType,

    /// Whether this message was sent by the user.
    required bool isUser,

    required MessageStatus status,

    /// Additional metadata for the message (JSON).
    String? metadata,

    @Default(<MessageAttachmentToCreate>[])
    List<MessageAttachmentToCreate> attachments,
  }) = _MessageToCreate;
  const MessageToCreate._();

  /// Returns true if the message has valid content.
  bool get hasValidContent {
    if (content.trim().isNotEmpty) {
      return true;
    }

    if (attachments.isNotEmpty) {
      return true;
    }

    final metadata = this.metadata;

    if (status == MessageStatus.unfinished && !isUser) {
      return metadata == null ||
          metadata.trim().isEmpty ||
          safeJsonDecode(metadata) != null;
    }

    if (status == MessageStatus.sent) {
      return false;
    }

    return !isUser &&
        metadata != null &&
        metadata.trim().isNotEmpty &&
        safeJsonDecode(metadata) != null;
  }

  /// Returns true if the message is in a valid state.
  bool get isValid {
    return hasValidContent && conversationId.isNotEmpty;
  }
}

/// Entity for patching an existing message.
@freezed
abstract class MessagePatch with _$MessagePatch {
  /// Creates a new MessagePatch instance.
  const factory MessagePatch({
    /// Content of the message (JSON structure based on message type).
    String? content,

    /// Additional metadata for the message (JSON).
    MessageMetadataEntity? metadata,

    MessageStatus? status,
  }) = _MessagePatch;
  const MessagePatch._();

  /// Returns true if the message is in a valid state.
  bool get isValid {
    return content != null || metadata != null || status != null;
  }
}

@Freezed(toStringOverride: false)
abstract class ToolToCall with _$ToolToCall {
  const factory ToolToCall({
    required ResolvedTool tool,
    required String id,
    required String argumentsRaw,
  }) = _ToolToCall;
  const ToolToCall._();
}
