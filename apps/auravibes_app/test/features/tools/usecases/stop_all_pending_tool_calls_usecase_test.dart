import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/tools/usecases/stop_all_pending_tool_calls_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'stop_all_pending_tool_calls_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('StopAllPendingToolCallsUsecase', () {
    test('updates only pending tool calls to stoppedByUser', () async {
      final messageRepository = MockMessageRepository();
      final message = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: 'assistant',
        messageType: MessageType.text,
        isUser: false,
        status: MessageStatus.sent,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        metadata: const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'calculator',
              argumentsRaw: '{}',
            ),
            MessageToolCallEntity(
              id: 'tool-2',
              name: 'search',
              argumentsRaw: '{}',
              resultStatus: ToolCallResultStatus.success,
            ),
            MessageToolCallEntity(
              id: 'tool-3',
              name: 'browser',
              argumentsRaw: '{}',
            ),
          ],
        ),
      );

      when(messageRepository.getMessageById('message-1')).thenAnswer(
        (_) async => message,
      );
      when(messageRepository.patchMessage('message-1', any)).thenAnswer(
        (_) async => message,
      );

      final usecase = StopAllPendingToolCallsUsecase(
        messageRepository: messageRepository,
      );

      await usecase.call(messageId: 'message-1');

      final updated =
          verify(
                messageRepository.patchMessage('message-1', captureAny),
              ).captured.single
              as MessagePatch;
      final toolCalls = updated.metadata?.toolCalls;

      expect(toolCalls, isNotNull);
      expect(toolCalls?[0].resultStatus, ToolCallResultStatus.stoppedByUser);
      expect(toolCalls?[1].resultStatus, ToolCallResultStatus.success);
      expect(toolCalls?[2].resultStatus, ToolCallResultStatus.stoppedByUser);
    });
  });
}
