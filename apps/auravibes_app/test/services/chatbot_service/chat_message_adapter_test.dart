import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildPromptChatMessages', () {
    const adapter = BuildPromptChatMessages();

    test('converts user message', () {
      final messages = [
        MessageEntity(
          id: 'u1',
          conversationId: 'c1',
          content: 'Hello',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ];

      final result = adapter(messages);

      expect(result, hasLength(1));
      expect(result.single.role.name, 'user');
    });

    test('converts assistant message without tool calls', () {
      final messages = [
        MessageEntity(
          id: 'a1',
          conversationId: 'c1',
          content: 'Hi there',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ];

      final result = adapter(messages);

      expect(result, hasLength(1));
      expect(result.single.role.name, 'model');
    });

    test('converts assistant message with resolved tool calls', () {
      final messages = [
        MessageEntity(
          id: 'a1',
          conversationId: 'c1',
          content: '',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc1',
                name: 'calculator',
                argumentsRaw: '{"expr":"2+2"}',
                responseRaw: '4',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        ),
      ];

      final result = adapter(messages);

      expect(result, hasLength(2));

      final modelMsg = result[0];
      expect(modelMsg.role.name, 'model');
      expect(modelMsg.toolCalls, hasLength(1));
      expect(modelMsg.toolCalls.single.callId, 'tc1');
      expect(modelMsg.toolCalls.single.toolName, 'calculator');

      final resultMsg = result[1];
      expect(resultMsg.role.name, 'model');
      expect(resultMsg.toolResults, hasLength(1));
      expect(resultMsg.toolResults.single.callId, 'tc1');
    });

    test('skips unresolved tool call results', () {
      final messages = [
        MessageEntity(
          id: 'a1',
          conversationId: 'c1',
          content: '',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc1',
                name: 'calculator',
                argumentsRaw: '{"expr":"2+2"}',
              ),
            ],
          ),
        ),
      ];

      final result = adapter(messages);

      expect(result, hasLength(1));
      expect(result.single.toolCalls, hasLength(1));
      expect(result.single.toolResults, isEmpty);
    });

    test('converts multiple messages in order', () {
      final messages = [
        MessageEntity(
          id: 'u1',
          conversationId: 'c1',
          content: 'Hi',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
        MessageEntity(
          id: 'a1',
          conversationId: 'c1',
          content: 'Hello!',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ];

      final result = adapter(messages);

      expect(result, hasLength(2));
      expect(result[0].role.name, 'user');
      expect(result[1].role.name, 'model');
    });
  });
}
