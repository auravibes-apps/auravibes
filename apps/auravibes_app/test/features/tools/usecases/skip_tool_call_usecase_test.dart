// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: missing-test-assertion
// Required: Tests verify usecase behavior through repository side effects.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/usecases/resume_conversation_if_ready_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/skip_tool_call_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'skip_tool_call_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository, ResumeConversationIfReadyUsecase])
void main() {
  group('SkipToolCallUsecase', () {
    late MockMessageRepository messageRepository;
    late MockResumeConversationIfReadyUsecase resumeConversationIfReadyUsecase;
    late SkipToolCallUsecase usecase;

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

      when(messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(messageRepository.patchMessage(messageId, any)).thenAnswer(
        (_) async => message,
      );
      when(
        resumeConversationIfReadyUsecase.call(
          messageId: anyNamed('messageId'),
        ),
      ).thenAnswer((_) async {});
    });

    test('marks tool call as skippedByUser and resumes conversation', () async {
      await usecase.call(toolCallId: toolCallId, messageId: messageId);

      final update =
          verify(
                messageRepository.patchMessage(messageId, captureAny),
              ).captured.single
              as MessagePatch;
      expect(
        update.metadata?.toolCalls.first.resultStatus,
        ToolCallResultStatus.skippedByUser,
      );

      verify(
        resumeConversationIfReadyUsecase.call(messageId: messageId),
      ).called(1);
    });

    test('does not resume when message not found', () async {
      when(messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => null,
      );

      await usecase.call(toolCallId: toolCallId, messageId: messageId);

      final _ = verifyNever(
        messageRepository.patchMessage(any, any),
      );
      final _ = verifyNever(
        resumeConversationIfReadyUsecase.call(messageId: anyNamed('messageId')),
      );
    });
  });
}
