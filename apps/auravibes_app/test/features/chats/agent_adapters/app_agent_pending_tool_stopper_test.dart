import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_pending_tool_stopper.dart';
import 'package:flutter_test/flutter_test.dart';

class _MessageRepository(final List<MessageEntity> messages)
    extends Fake
    implements MessageRepository {
  final patches = <({String id, MessagePatch patch, String? conversationId})>[];

  @override
  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) => Future<List<MessageEntity>>.value(messages);

  @override
  Future<MessageEntity> patchMessage(
    String id,
    MessagePatch patch, {
    String? conversationId,
  }) async {
    patches.add((id: id, patch: patch, conversationId: conversationId));

    return messages.singleWhere((message) => message.id == id);
  }
}

void main() {
  test('stops only source-owned pending tool calls', () async {
    final now = DateTime(2026);
    const pending = MessageToolCallEntity(
      id: 'pending',
      name: 'calculator',
      argumentsRaw: '{}',
    );
    const running = MessageToolCallEntity(
      id: 'running',
      name: 'search',
      argumentsRaw: '{}',
      resultStatus: .running,
    );
    const completed = MessageToolCallEntity(
      id: 'completed',
      name: 'weather',
      argumentsRaw: '{}',
      resultStatus: .success,
    );
    final sourceMessage = MessageEntity(
      id: 'source-message',
      conversationId: 'conversation',
      content: 'tool calls',
      messageType: .text,
      isUser: false,
      status: .unfinished,
      createdAt: now,
      updatedAt: now,
      metadata: const MessageMetadataEntity(
        toolCalls: [pending, running, completed],
      ),
    );
    final inheritedMessage = sourceMessage.copyWith(
      id: 'inherited-message',
      isForkReference: true,
    );
    final userMessage = sourceMessage.copyWith(
      id: 'user-message',
      isUser: true,
    );
    final repository = _MessageRepository([
      sourceMessage,
      inheritedMessage,
      userMessage,
    ]);

    await AppAgentPendingToolStopper(repository).call('conversation');

    expect(repository.patches, hasLength(1));
    final patch = repository.patches.single;
    expect(patch.id, 'source-message');
    expect(patch.conversationId, 'conversation');
    expect(patch.patch.status, MessageStatus.sent);
    expect(
      patch.patch.metadata?.toolCalls.map((toolCall) => toolCall.resultStatus),
      <ToolCallResultStatus?>[.stoppedByUser, .stoppedByUser, .success],
    );
  });
}
