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

    return AgentTranscriptMessageSnapshot(
      id: message.id,
      role: _roleFor(message),
      kind: _kindFor(message),
      status: _statusFor(message),
      textCharacterCount: message.content.length,
      toolCalls: _toolCallSnapshots(metadata),
      latestCumulativeTokenCount: metadata?.usedTokens,
      isCompactionSummary: metadata?.isCompactionSummary ?? false,
      compactedThroughMessageId: metadata?.compactedThroughMessageId,
      excludedMessageIds: metadata?.compactedMessageIds ?? const [],
    );
  }

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
    for (final toolCall in _toolCallsFor(metadata))
      AgentTranscriptToolCallSnapshot(
        id: toolCall.id,
        lifecycle: AgentToolStatusMapper.toLifecycle(toolCall.resultStatus),
        argumentCharacterCount: toolCall.argumentsRaw.length,
        resultCharacterCount: toolCall.responseRaw?.length ?? 0,
      ),
  ];
}
