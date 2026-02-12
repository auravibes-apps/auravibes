import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/update_message_metadata_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'update_message_metadata_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('UpdateMessageMetadataUseCase', () {
    test('should update tool results in message metadata', () async {
      final mockRepo = MockMessageRepository();
      final message = MessageEntity(
        id: 'msg-123',
        conversationId: 'conv-123',
        content: 'test content',
        messageType: MessageType.text,
        isUser: false,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'test_tool',
              argumentsRaw: '{}',
            ),
          ],
        ),
      );

      when(mockRepo.getMessageById('msg-123')).thenAnswer((_) async => message);
      when(
        mockRepo.updateMessage(
          'msg-123',
          any,
        ),
      ).thenAnswer((_) async => message);

      final useCase = UpdateMessageMetadataUseCase(mockRepo);

      final updates = [
        const ToolResultUpdate(
          toolCallId: 'tool-1',
          resultStatus: ToolCallResultStatus.success,
          responseRaw: 'result data',
        ),
      ];

      // Should not throw
      await useCase.call(messageId: 'msg-123', updates: updates);

      verify(mockRepo.getMessageById('msg-123')).called(1);
      verify(mockRepo.updateMessage('msg-123', any)).called(1);
    });

    test('should return early when message not found', () async {
      final mockRepo = MockMessageRepository();

      when(mockRepo.getMessageById('msg-123')).thenAnswer((_) async => null);

      final useCase = UpdateMessageMetadataUseCase(mockRepo);

      final updates = [
        const ToolResultUpdate(
          toolCallId: 'tool-1',
          resultStatus: ToolCallResultStatus.success,
          responseRaw: 'result data',
        ),
      ];

      // Should not throw
      await useCase.call(messageId: 'msg-123', updates: updates);

      verify(mockRepo.getMessageById('msg-123')).called(1);
      verifyNever(mockRepo.updateMessage(any, any));
    });
  });
}
