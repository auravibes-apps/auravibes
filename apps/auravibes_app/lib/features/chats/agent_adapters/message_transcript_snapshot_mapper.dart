import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class MessageTranscriptSnapshotMapper {
  static AgentContextSnapshot toAgentContextSnapshot(
    List<MessageEntity> messages,
  ) {
    return AgentContextSnapshot(messages.map(_toMessageSnapshot).toList());
  }

  static AgentTranscriptMessageSnapshot _toMessageSnapshot(
    MessageEntity message,
  ) {
    final metadata = message.metadata;

    return _snapshotFor(message, metadata);
  }

  static AgentTranscriptMessageSnapshot _snapshotFor(
    MessageEntity message,
    MessageMetadataEntity? metadata,
  ) {
    final data = _snapshotData(message, metadata);

    return AgentTranscriptMessageSnapshot(
      id: data.id,
      role: data.role,
      kind: data.kind,
      status: data.status,
      textCharacterCount: data.textCharacterCount,
      toolCalls: data.toolCalls,
      latestCumulativeTokenCount: data.latestCumulativeTokenCount,
      isCompactionSummary: data.isCompactionSummary,
      compactedThroughMessageId: data.compactedThroughMessageId,
      excludedMessageIds: data.excludedMessageIds,
    );
  }

  static _SnapshotData _snapshotData(
    MessageEntity message,
    MessageMetadataEntity? metadata,
  ) => _snapshotDataFromDetails(message, _snapshotDetails(metadata));

  static _SnapshotDetails _snapshotDetails(MessageMetadataEntity? metadata) => (
    toolCalls: _toolCallSnapshots(metadata),
    latestCumulativeTokenCount: metadata?.usedTokens,
    isCompactionSummary: metadata?.isCompactionSummary ?? false,
    compactedThroughMessageId: metadata?.compactedThroughMessageId,
    excludedMessageIds: metadata?.compactedMessageIds ?? const [],
  );

  static Iterable<MessageToolCallEntity> _toolCallsFor(
    MessageMetadataEntity? metadata,
  ) => metadata?.toolCalls ?? const <MessageToolCallEntity>[];

  static AgentTranscriptRole _roleFor(MessageEntity message) =>
      switch (message.messageType) {
        _ when message.isUser => AgentTranscriptRole.user,
        .system => AgentTranscriptRole.system,
        _ => AgentTranscriptRole.model,
      };

  static AgentTranscriptKind _kindFor(MessageEntity message) =>
      switch (message.messageType) {
        .text => AgentTranscriptKind.text,
        .image => AgentTranscriptKind.image,
        .toolCall => AgentTranscriptKind.toolCall,
        .system => AgentTranscriptKind.system,
      };

  static AgentTranscriptStatus _statusFor(MessageEntity message) =>
      switch (message.status) {
        .sending => AgentTranscriptStatus.sending,
        .unfinished => AgentTranscriptStatus.unfinished,
        .sent => AgentTranscriptStatus.sent,
        .error => AgentTranscriptStatus.error,
      };

  static List<AgentTranscriptToolCallSnapshot> _toolCallSnapshots(
    MessageMetadataEntity? metadata,
  ) => [
    for (final toolCall in _toolCallsFor(metadata)) _toolCallSnapshot(toolCall),
  ];
}

AgentTranscriptToolCallSnapshot _toolCallSnapshot(
  MessageToolCallEntity toolCall,
) {
  final response = toolCall.getResponseForAI();
  final outputBounds = _toolCallOutputBounds(toolCall, response);

  return AgentTranscriptToolCallSnapshot(
    id: toolCall.id,
    lifecycle: AgentToolStatusMapper.toLifecycle(toolCall.resultStatus),
    argumentCharacterCount: toolCall.argumentsRaw.length,
    resultCharacterCount: response.length,
    resultTruncated: outputBounds.truncated,
    originalResultBytes: outputBounds.originalBytes,
  );
}

({bool truncated, int? originalBytes}) _toolCallOutputBounds(
  MessageToolCallEntity toolCall,
  String response,
) {
  if (toolCall.fullOutputForContext) {
    return (
      truncated: toolCall.outputTruncated,
      originalBytes: toolCall.originalResponseBytes,
    );
  }

  final projection = projectToolOutput(response);

  return (
    truncated: toolCall.outputTruncated || projection.truncated,
    originalBytes:
        toolCall.originalResponseBytes ??
        (projection.truncated ? projection.originalBytes : null),
  );
}

typedef _SnapshotData = ({
  String id,
  AgentTranscriptRole role,
  AgentTranscriptKind kind,
  AgentTranscriptStatus status,
  int textCharacterCount,
  List<AgentTranscriptToolCallSnapshot> toolCalls,
  int? latestCumulativeTokenCount,
  bool isCompactionSummary,
  String? compactedThroughMessageId,
  List<String> excludedMessageIds,
});

typedef _SnapshotDetails = ({
  List<AgentTranscriptToolCallSnapshot> toolCalls,
  int? latestCumulativeTokenCount,
  bool isCompactionSummary,
  String? compactedThroughMessageId,
  List<String> excludedMessageIds,
});

_SnapshotData _snapshotDataFromDetails(
  MessageEntity message,
  _SnapshotDetails details,
) => (
  id: message.id,
  role: MessageTranscriptSnapshotMapper._roleFor(message),
  kind: MessageTranscriptSnapshotMapper._kindFor(message),
  status: MessageTranscriptSnapshotMapper._statusFor(message),
  textCharacterCount: message.content.length,
  toolCalls: details.toolCalls,
  latestCumulativeTokenCount: details.latestCumulativeTokenCount,
  isCompactionSummary: details.isCompactionSummary,
  compactedThroughMessageId: details.compactedThroughMessageId,
  excludedMessageIds: details.excludedMessageIds,
);
