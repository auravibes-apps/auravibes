import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/agent_harness/skip_tool_call_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('AppToolCallActionsDataProvider', () {
    var messageRepository = MockMessageRepository();
    var agentToolResumeService = MockAgentToolResumeService();
    var provider = AppToolCallActionsDataProvider(
      messageRepository: messageRepository,
      agentToolResumeService: agentToolResumeService,
    );

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
            id: 'tool-1',
            name: 'calculator',
            argumentsRaw: '{}',
          ),
          MessageToolCallEntity(
            id: 'tool-2',
            name: 'url',
            argumentsRaw: '{}',
            resultStatus: ToolCallResultStatus.success,
          ),
        ],
      ),
    );

    setUp(() {
      messageRepository = MockMessageRepository();
      agentToolResumeService = MockAgentToolResumeService();
      provider = AppToolCallActionsDataProvider(
        messageRepository: messageRepository,
        agentToolResumeService: agentToolResumeService,
      );
    });

    test('marks a single tool call skipped', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(() => messageRepository.patchMessage(messageId, any())).thenAnswer(
        (_) async => message,
      );

      final result = await provider.skipToolCall(
        messageId: messageId,
        toolCallId: 'tool-1',
      );

      expect(result, isTrue);
      final patch =
          verify(
                () => messageRepository.patchMessage(messageId, captureAny()),
              ).captured.single
              as MessagePatch;
      expect(
        patch.metadata?.toolCalls.first.resultStatus,
        ToolCallResultStatus.skippedByUser,
      );
      expect(
        patch.metadata?.toolCalls.last.resultStatus,
        ToolCallResultStatus.success,
      );
    });

    test('returns false when skipping a missing message', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => null,
      );

      final result = await provider.skipToolCall(
        messageId: messageId,
        toolCallId: 'tool-1',
      );

      expect(result, isFalse);
      verifyNever(() => messageRepository.patchMessage(any(), any())).called(0);
    });

    test('marks only pending tool calls stopped', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(() => messageRepository.patchMessage(messageId, any())).thenAnswer(
        (_) async => message,
      );

      await provider.stopPendingToolCalls(messageId: messageId);

      final patch =
          verify(
                () => messageRepository.patchMessage(messageId, captureAny()),
              ).captured.single
              as MessagePatch;
      expect(
        patch.metadata?.toolCalls.first.resultStatus,
        ToolCallResultStatus.stoppedByUser,
      );
      expect(
        patch.metadata?.toolCalls.last.resultStatus,
        ToolCallResultStatus.success,
      );
    });

    test('does not patch when no pending tool calls exist', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message.copyWith(
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-1',
                name: 'calculator',
                argumentsRaw: '{}',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        ),
      );

      await expectLater(
        provider.stopPendingToolCalls(messageId: messageId),
        completes,
      );

      verifyNever(() => messageRepository.patchMessage(any(), any())).called(0);
    });

    test('resumes conversation through resume service', () async {
      when(
        () => agentToolResumeService.call(messageId: messageId),
      ).thenAnswer((_) => Future<void>.value());

      await expectLater(
        provider.resumeConversationIfReady(messageId: messageId),
        completes,
      );

      verify(() => agentToolResumeService.call(messageId: messageId)).called(1);
    });
  });
}
