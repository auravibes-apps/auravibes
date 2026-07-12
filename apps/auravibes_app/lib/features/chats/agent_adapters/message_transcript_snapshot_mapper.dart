import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_status_mapper.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

AgentContextSnapshot toAgentContextSnapshot(List<MessageEntity> messages) {
  return AgentContextSnapshot(messages.map(_toMessageSnapshot).toList());
}

AgentTranscriptMessageSnapshot _toMessageSnapshot(MessageEntity message) {
  final metadata = message.metadata;
  final role = switch (message.messageType) {
    _ when message.isUser => AgentTranscriptRole.user,
    MessageType.system => AgentTranscriptRole.system,
    _ => AgentTranscriptRole.model,
  };

  return AgentTranscriptMessageSnapshot(
    id: message.id,
    role: role,
    kind: switch (message.messageType) {
      MessageType.text => AgentTranscriptKind.text,
      MessageType.image => AgentTranscriptKind.image,
      MessageType.toolCall => AgentTranscriptKind.toolCall,
      MessageType.system => AgentTranscriptKind.system,
    },
    status: switch (message.status) {
      MessageStatus.sending => AgentTranscriptStatus.sending,
      MessageStatus.unfinished => AgentTranscriptStatus.unfinished,
      MessageStatus.sent => AgentTranscriptStatus.sent,
      MessageStatus.error => AgentTranscriptStatus.error,
    },
    textCharacterCount: message.content.length,
    toolCalls: [
      for (final toolCall
          in metadata?.toolCalls ?? const <MessageToolCallEntity>[])
        AgentTranscriptToolCallSnapshot(
          id: toolCall.id,
          lifecycle: toAgentToolCallLifecycle(toolCall.resultStatus),
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
