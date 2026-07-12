import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/message_transcript_snapshot_mapper.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps persisted transcript semantics without exposing contents', () {
    final message = MessageEntity(
      id: 'summary-1',
      conversationId: 'conversation-1',
      content: 'summary',
      messageType: MessageType.system,
      isUser: false,
      status: MessageStatus.sent,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      metadata: const MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: 'tool-1',
            name: 'native__url',
            argumentsRaw: '{"x":1}',
            responseRaw: 'done',
            resultStatus: ToolCallResultStatus.running,
          ),
        ],
        promptTokens: 8,
        completionTokens: 5,
        isCompactionSummary: true,
        compactedThroughMessageId: 'message-2',
        compactedMessageIds: ['message-1', 'message-2'],
      ),
    );

    final snapshot = toAgentContextSnapshot([message]).messages.single;

    expect(snapshot.id, 'summary-1');
    expect(snapshot.role, AgentTranscriptRole.system);
    expect(snapshot.kind, AgentTranscriptKind.system);
    expect(snapshot.status, AgentTranscriptStatus.sent);
    expect(snapshot.textCharacterCount, 7);
    expect(snapshot.latestCumulativeTokenCount, 13);
    expect(snapshot.isCompactionSummary, isTrue);
    expect(snapshot.compactedThroughMessageId, 'message-2');
    expect(snapshot.excludedMessageIds, ['message-1', 'message-2']);
    expect(snapshot.toolCalls.single.id, 'tool-1');
    expect(snapshot.toolCalls.single.lifecycle, AgentToolCallLifecycle.pending);
    expect(snapshot.toolCalls.single.argumentCharacterCount, 7);
    expect(snapshot.toolCalls.single.resultCharacterCount, 4);
  });
}
