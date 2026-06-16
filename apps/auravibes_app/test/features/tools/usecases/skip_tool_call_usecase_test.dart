import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/tools/usecases/skip_tool_call_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('SkipToolCallUsecase', () {
    var messageRepository = MockMessageRepository();
    var resumeConversationIfReadyUsecase =
        MockResumeConversationIfReadyUsecase();
    var usecase = SkipToolCallUsecase(
      messageRepository: messageRepository,
      resumeConversationIfReadyUsecase: resumeConversationIfReadyUsecase,
    );

    const toolCallId = 'tool-1';
    const messageId = 'message-1';
    final message = MessageEntity(
      id: messageId,
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
            id: toolCallId,
            name: 'calculator',
            argumentsRaw: '{}',
          ),
        ],
      ),
    );

    setUp(() {
      messageRepository = MockMessageRepository();
      resumeConversationIfReadyUsecase = MockResumeConversationIfReadyUsecase();

      usecase = SkipToolCallUsecase(
        messageRepository: messageRepository,
        resumeConversationIfReadyUsecase: resumeConversationIfReadyUsecase,
      );

      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(() => messageRepository.patchMessage(messageId, any())).thenAnswer(
        (_) async => message,
      );
      when(
        () => resumeConversationIfReadyUsecase.call(
          messageId: any(named: 'messageId'),
        ),
      ).thenAnswer((_) {
        return Future<void>.value();
      });
    });

    test('marks tool call as skippedByUser and resumes conversation', () async {
      await usecase.call(toolCallId: toolCallId, messageId: messageId);

      final update =
          verify(
                () => messageRepository.patchMessage(messageId, captureAny()),
              ).captured.single
              as MessagePatch;
      expect(
        update.metadata?.toolCalls.first.resultStatus,
        ToolCallResultStatus.skippedByUser,
      );

      verify(
        () => resumeConversationIfReadyUsecase.call(messageId: messageId),
      ).called(1);
    });

    test('does not resume when message not found', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => null,
      );

      await usecase.call(toolCallId: toolCallId, messageId: messageId);

      expect(
        () => verifyNever(
          () => messageRepository.patchMessage(any(), any()),
        ),
        returnsNormally,
      );
      expect(
        () => verifyNever(
          () => resumeConversationIfReadyUsecase.call(
            messageId: any(named: 'messageId'),
          ),
        ),
        returnsNormally,
      );
    });
  });
}
