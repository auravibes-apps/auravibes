// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';

import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/utils/json_codec.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_tool_call_entity.freezed.dart';
part 'message_tool_call_entity.g.dart';

@immutable
@Freezed(toStringOverride: false)
abstract class const MessageToolCallEntity._() with _$MessageToolCallEntity {
  const factory({
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
    /// Null means the tool is awaiting approval. A non-null value means the
    /// tool is running or completed with this result status.
    @JsonKey(
      fromJson: _toolCallResultStatusFromJson,
      toJson: _toolCallResultStatusToJson,
    )
    ToolCallResultStatus? resultStatus,
  }) = _MessageToolCallEntity;
  factory fromJson(Map<String, dynamic> json) =>
      _$MessageToolCallEntityFromJson(json);

  /// Whether this tool call has been resolved (success or failure).
  bool get isResolved => resultStatus?.agentLifecycle.isResolved ?? false;

  /// Whether this tool call is still pending
  /// (waiting for permission or execution).
  bool get isPending => isAwaitingApproval || isRunning;

  String identity() => '$id:$name';

  @override
  String toString();

  /// Gets the response to send to the AI.
  ///
  /// Returns [responseRaw] if available, otherwise falls back to
  /// the result status's response string.
  String getResponseForAI() {
    return responseRaw ?? resultStatus?.toResponseString() ?? '';
  }
}

extension MessageToolCallEntityHelpers on MessageToolCallEntity {
  Map<String, dynamic> get arguments {
    return JsonCodec.decode(argumentsRaw) ?? {};
  }

  /// Whether this tool call is waiting for permission.
  bool get isAwaitingApproval => resultStatus == null;

  /// Whether this tool call is currently running.
  bool get isRunning => resultStatus?.agentLifecycle.isPending ?? false;

  bool hasArguments() => argumentsRaw.trim().isNotEmpty;

  bool hasResponse() => responseRaw != null;

  bool hasResultStatus() => resultStatus != null;
}

ToolCallResultStatus? _toolCallResultStatusFromJson(String? json) {
  return const ToolCallResultStatusConverter().fromJson(json);
}

String? _toolCallResultStatusToJson(ToolCallResultStatus? status) {
  return const ToolCallResultStatusConverter().toJson(status);
}

enum CompactionKind { manual, auto }

enum MessageAttachmentModality { image, audio, file }

@immutable
@freezed
abstract class MessageAttachmentEntity with _$MessageAttachmentEntity {
  const factory({
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

  @override
  int get hashCode;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

@immutable
@freezed
abstract class MessageAttachmentToCreate with _$MessageAttachmentToCreate {
  const factory({
    required String localPath,
    required String fileName,
    required String displayName,
    required String mimeType,
    required MessageAttachmentModality modality,
    required int sizeBytes,
  }) = _MessageAttachmentToCreate;

  @override
  int get hashCode;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

@immutable
@freezed
abstract class const MessageMetadataEntity._() with _$MessageMetadataEntity {
  const factory({
    @Default(<MessageToolCallEntity>[]) List<MessageToolCallEntity> toolCalls,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    String? thinking,
    @Default(<String, Object?>{}) Map<String, Object?> modelMetadata,
    @Default(<String>[]) List<String> a2uiMessages,
    @Default(<String, List<String>>{})
    Map<String, List<String>> a2uiIssuesBySurface,
    @Default(<String>[]) List<String> a2uiMessageIssues,
    @Default(1) int metadataVersion,
    @Default(false) bool isCompactionSummary,
    CompactionKind? compactionKind,
    String? compactedFromMessageId,
    String? compactedThroughMessageId,
    @Default(<String>[]) List<String> compactedMessageIds,
    DateTime? compactionCreatedAt,
  }) = _MessageMetadataEntity;
  factory fromJson(Map<String, dynamic> json) =>
      _$MessageMetadataEntityFromJson(json);

  @override
  int get hashCode;

  int get usedTokens {
    return totalTokens ?? ((promptTokens ?? 0) + (completionTokens ?? 0));
  }

  @override
  String toString();

  @override
  bool operator ==(Object other);

  static MessageMetadataEntity? fromJsonString(String? metadata) {
    if (metadata == null) return null;
    try {
      final json = jsonDecode(metadata) as Map<String, dynamic>;

      return _metadataFromDecodedJson(json);
    } on Exception catch (_) {
      return null;
    }
  }
}

MessageMetadataEntity _metadataFromDecodedJson(Map<String, dynamic> json) {
  final conversationId = json['conversationId'];
  if (conversationId is! String) return MessageMetadataEntity.fromJson(json);

  final action = A2uiChatContract.decodeActionMetadata(
    json,
    conversationId: conversationId,
  );
  if (action == null) return MessageMetadataEntity.fromJson(json);

  return MessageMetadataEntity(
    modelMetadata: {a2uiChatActionMetadataKey: action.toJson()},
  );
}

/// Entity representing a message in a conversation.
///
/// A message contains the actual content and metadata
/// for communication within a conversation.
@immutable
@freezed
abstract class const MessageEntity._() with _$MessageEntity {
  const factory({
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

  @override
  int get hashCode;

  /// Returns true if the message has valid content.
  bool get hasValidContent =>
      content.trim().isNotEmpty || attachments.isNotEmpty;

  /// Returns true if the message is in a valid state.
  bool get isValid {
    return hasValidContent && conversationId.isNotEmpty;
  }

  bool isForConversation(String conversationId) =>
      this.conversationId == conversationId;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

/// Entity for creating a new message.
@immutable
@freezed
abstract class const MessageToCreate._() with _$MessageToCreate {
  /// Creates a new MessageToCreate instance.
  const factory({
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

  @override
  int get hashCode;

  /// Returns true if the message has valid content.
  bool get hasValidContent {
    if (content.trim().isNotEmpty || attachments.isNotEmpty) return true;

    return _hasValidMetadata;
  }

  /// Returns true if the message is in a valid state.
  bool get isValid {
    return hasValidContent && conversationId.isNotEmpty;
  }

  bool get _hasValidMetadata {
    final metadata = this.metadata;

    if (status == MessageStatus.sent) {
      return false;
    }

    if (status == MessageStatus.unfinished && !isUser) {
      return metadata == null || _isValidMetadataJson(metadata);
    }

    return !isUser &&
        metadata != null &&
        _isValidMetadataJson(metadata, allowEmpty: false);
  }

  bool isForConversation(String conversationId) =>
      this.conversationId == conversationId;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

bool _isValidMetadataJson(String metadata, {bool allowEmpty = true}) {
  final normalizedMetadata = metadata.trim();
  if (allowEmpty && normalizedMetadata.isEmpty) return true;

  return normalizedMetadata.isNotEmpty && JsonCodec.decode(metadata) != null;
}

/// Entity for patching an existing message.
@immutable
@freezed
abstract class const MessagePatch._() with _$MessagePatch {
  /// Creates a new MessagePatch instance.
  const factory({
    /// Content of the message (JSON structure based on message type).
    String? content,

    /// Additional metadata for the message (JSON).
    MessageMetadataEntity? metadata,

    MessageStatus? status,
  }) = _MessagePatch;

  @override
  int get hashCode;

  /// Returns true if the message is in a valid state.
  bool get isValid {
    return content != null || metadata != null || status != null;
  }

  bool changesStatusTo(MessageStatus value) => status == value;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

@immutable
@Freezed(toStringOverride: false)
abstract class const ToolToCall._() with _$ToolToCall {
  const factory({
    required ResolvedTool tool,
    required String id,
    required String argumentsRaw,
  }) = _ToolToCall;

  @override
  int get hashCode;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}
