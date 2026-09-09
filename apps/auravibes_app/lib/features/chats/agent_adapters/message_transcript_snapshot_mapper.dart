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
    final role = switch (message.messageType) {
      _ when message.isUser => AgentTranscriptRole.user,
      .system => AgentTranscriptRole.system,
      _ => AgentTranscriptRole.model,
    };

    return AgentTranscriptMessageSnapshot(
      id: message.id,
      role: role,
      kind: switch (message.messageType) {
        .text => AgentTranscriptKind.text,
        .image => AgentTranscriptKind.image,
        .toolCall => AgentTranscriptKind.toolCall,
        .system => AgentTranscriptKind.system,
      },
      status: switch (message.status) {
        .sending => AgentTranscriptStatus.sending,
        .unfinished => AgentTranscriptStatus.unfinished,
        .sent => AgentTranscriptStatus.sent,
        .error => AgentTranscriptStatus.error,
      },
      textCharacterCount: message.content.length,
      toolCalls: [
        for (final toolCall in _toolCallsFor(metadata))
          AgentTranscriptToolCallSnapshot(
            id: toolCall.id,
            lifecycle: AgentToolStatusMapper.toLifecycle(toolCall.resultStatus),
            argumentCharacterCount: toolCall.argumentsRaw.length,
            resultCharacterCount: toolCall.responseRaw?.length ?? 0,
          ),
      ],
      latestCumulativeTokenCount: metadata?.usedTokens,
      isCompactionSummary: metadata?.isCompactionSummary ?? false,
      compactedThroughMessageId: metadata?.compactedThroughMessageId,
      excludedMessageIds: metadata?.compactedMessageIds ?? const [],
    );
  }

  static Iterable<MessageToolCallEntity> _toolCallsFor(
    MessageMetadataEntity? metadata,
  ) => metadata?.toolCalls ?? const <MessageToolCallEntity>[];
}
