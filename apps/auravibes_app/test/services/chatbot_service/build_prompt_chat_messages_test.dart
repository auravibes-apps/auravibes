import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';

void main() {
  group('BuildPromptChatMessages', () {
    const usecase = BuildPromptChatMessages();

    test('adds tool response messages after assistant tool calls', () {
      final messages = [
        MessageEntity(
          id: 'user-1',
          conversationId: 'conversation-1',
          content: 'What is 2 + 2?',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
        MessageEntity(
          id: 'assistant-1',
          conversationId: 'conversation-1',
          content: '',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-1',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input":"2+2"}',
                responseRaw: '4',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        ),
      ];

      final result = usecase.call(messages);

      expect(result, hasLength(3));
      expect(result[0], isA<HumanChatMessage>());

      final aiMessage = result[1] as AIChatMessage;
      expect(aiMessage.toolCalls, hasLength(1));
      expect(aiMessage.toolCalls.single.id, 'tool-1');
      expect(aiMessage.toolCalls.single.name, 'built_in_calc_calculator');

      final toolMessage = result[2] as ToolChatMessage;
      expect(toolMessage.toolCallId, 'tool-1');
      expect(toolMessage.content, '4');
    });

    test(
      'falls back to result status response when raw response is absent',
      () {
        final messages = [
          MessageEntity(
            id: 'assistant-1',
            conversationId: 'conversation-1',
            content: '',
            messageType: MessageType.text,
            isUser: false,
            status: MessageStatus.sent,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'tool-1',
                  name: 'missing_tool',
                  argumentsRaw: '{}',
                  resultStatus: ToolCallResultStatus.toolNotFound,
                ),
              ],
            ),
          ),
        ];

        final result = usecase.call(messages);

        expect(result, hasLength(2));
        final toolMessage = result[1] as ToolChatMessage;
        expect(
          toolMessage.content,
          ToolCallResultStatus.toolNotFound.toResponseString(),
        );
      },
    );
  });
}
