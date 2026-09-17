import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_conversation_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  test('does not stop pending tools inherited by a fork', () async {
    final messageRepository = MockMessageRepository();
    final provider = AppAgentConversationDataProvider(
      conversationRepository: MockConversationRepository(),
      messageRepository: messageRepository,
      autoCompactConversationUsecase: MockMaybeAutoCompactConversationUsecase(),
    );
    final message = MessageEntity(
      id: 'source-assistant',
      conversationId: 'source',
      content: 'assistant',
      messageType: .text,
      isUser: false,
      status: .sent,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      metadata: const .new(
        toolCalls: [.new(id: 'tool-call', name: 'tool', argumentsRaw: '{}')],
      ),
      isForkReference: true,
    );
    when(() => messageRepository.getMessagesByConversation('fork'))
        .thenAnswer((_) async => [message]);

    await provider.stopLatestPendingTools('fork');

    final _ = verifyNever(
      () => messageRepository.patchMessage(
        any(),
        any(),
        conversationId: any(named: 'conversationId'),
      ),
    );
  });
}
