import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/message_transcript_snapshot_mapper.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps persisted transcript semantics without exposing contents', () {
    final message = MessageEntity(
      id: 'summary-1',
      conversationId: 'conversation-1',
      content: 'summary',
      messageType: .system,
      isUser: false,
      status: .sent,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      metadata: const MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: 'tool-1',
            name: 'native__url',
            argumentsRaw: '{"x":1}',
            responseRaw: 'done',
            resultStatus: .running,
          ),
        ],
        promptTokens: 8,
        completionTokens: 5,
        isCompactionSummary: true,
        compactedThroughMessageId: 'message-2',
        compactedMessageIds: ['message-1', 'message-2'],
      ),
    );

    final snapshot = MessageTranscriptSnapshotMapper.toAgentContextSnapshot([
      message,
    ]).messages.single;

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

  test(
    'uses bounded output for context while keeping full result persisted',
    () {
      final source = 'result ' * 4000;
      final projection = projectToolOutput(source);
      final toolCall = MessageToolCallEntity(
        id: 'tool-1',
        name: 'search',
        argumentsRaw: '{}',
        responseRaw: source,
        responseContextRaw: projection.text,
        outputTruncated: projection.truncated,
        originalResponseBytes: projection.originalBytes,
        resultStatus: .success,
      );
      final message = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: '',
        messageType: .text,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        metadata: .new(toolCalls: [toolCall]),
      );

      final snapshot = MessageTranscriptSnapshotMapper.toAgentContextSnapshot([
        message,
      ]).messages.single.toolCalls.single;

      expect(toolCall.responseRaw, source);
      expect(toolCall.getResponseForAI(), projection.text);
      expect(snapshot.resultCharacterCount, projection.text.length);
      expect(snapshot.resultTruncated, isTrue);
      expect(snapshot.originalResultBytes, source.length);
    },
  );

  test('derives bounds metadata for older raw results', () {
    final source = 'older result ' * 2500;
    final toolCall = MessageToolCallEntity(
      id: 'tool-1',
      name: 'search',
      argumentsRaw: '{}',
      responseRaw: source,
      resultStatus: .success,
    );
    final message = MessageEntity(
      id: 'message-1',
      conversationId: 'conversation-1',
      content: '',
      messageType: .text,
      isUser: false,
      status: .sent,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      metadata: .new(toolCalls: [toolCall]),
    );

    final snapshot = MessageTranscriptSnapshotMapper.toAgentContextSnapshot([
      message,
    ]).messages.single.toolCalls.single;

    expect(snapshot.resultCharacterCount, lessThan(source.length));
    expect(snapshot.resultTruncated, isTrue);
    expect(snapshot.originalResultBytes, source.length);
  });
}
