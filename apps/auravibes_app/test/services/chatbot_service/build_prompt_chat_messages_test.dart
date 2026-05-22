import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(result[0].role.name, 'user');

      final modelMessage = result[1];
      expect(modelMessage.role.name, 'model');
      expect(modelMessage.toolCalls, hasLength(1));
      expect(modelMessage.toolCalls.single.callId, 'tool-1');
      expect(
        modelMessage.toolCalls.single.toolName,
        'built_in_calc_calculator',
      );

      final resultMessage = result[2];
      expect(resultMessage.role.name, 'user');
      expect(resultMessage.toolResults, hasLength(1));
      expect(resultMessage.toolResults.single.callId, 'tool-1');
    });

    test('groups resolved tool responses in one user message', () {
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
                name: 'first_tool',
                argumentsRaw: '{}',
                responseRaw: 'first result',
                resultStatus: ToolCallResultStatus.success,
              ),
              MessageToolCallEntity(
                id: 'tool-2',
                name: 'second_tool',
                argumentsRaw: '{}',
                responseRaw: 'second result',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        ),
      ];

      final result = usecase.call(messages);

      expect(result, hasLength(2));
      expect(result.first.role.name, 'model');
      expect(result.first.toolCalls, hasLength(2));

      final resultMessage = result.last;
      expect(resultMessage.role.name, 'user');
      expect(resultMessage.toolResults, hasLength(2));
      expect(resultMessage.toolResults.map((part) => part.callId), [
        'tool-1',
        'tool-2',
      ]);
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
        final resultMessage = result[1];
        expect(resultMessage.toolResults, hasLength(1));
        expect(resultMessage.role.name, 'user');
        expect(
          resultMessage.toolResults.single.result,
          ToolCallResultStatus.toolNotFound.toResponseString(),
        );
      },
    );

    test('maps compaction summary to system role', () {
      final messages = [
        MessageEntity(
          id: 'summary-1',
          conversationId: 'conversation-1',
          content: '<compaction summary content>',
          messageType: MessageType.system,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: const MessageMetadataEntity(isCompactionSummary: true),
        ),
      ];

      final result = usecase.call(messages);

      expect(result, hasLength(1));
      expect(result.single.role.name, 'system');
      expect(result.single.text, '<compaction summary content>');
    });

    test('maps assistant thinking metadata to thinking part', () {
      final messages = [
        MessageEntity(
          id: 'assistant-1',
          conversationId: 'conversation-1',
          content: 'Final answer',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: const MessageMetadataEntity(
            thinking: 'Reasoning summary',
          ),
        ),
      ];

      final result = usecase.call(messages);

      expect(result, hasLength(1));
      expect(result.single.text, 'Final answer');
      expect(
        result.single.parts.whereType<ThinkingPart>().single.text,
        'Reasoning summary',
      );
    });

    test('maps assistant model metadata to model message metadata', () {
      final messages = [
        MessageEntity(
          id: 'assistant-1',
          conversationId: 'conversation-1',
          content: 'Final answer',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: const MessageMetadataEntity(
            thinking: 'Reasoning summary',
            modelMetadata: {'_anthropic_thinking_signature': 'signature'},
          ),
        ),
      ];

      final result = usecase.call(messages);

      expect(result.single.metadata, {
        '_anthropic_thinking_signature': 'signature',
      });
    });
  });
}
