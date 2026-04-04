import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/tools/usecases/get_agent_iteration_decision_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_agent_iteration_decision_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('GetAgentIterationDecisionUsecase', () {
    late MockMessageRepository messageRepository;
    late GetAgentIterationDecisionUsecase usecase;

    setUp(() {
      messageRepository = MockMessageRepository();
      usecase = GetAgentIterationDecisionUsecase(
        messageRepository: messageRepository,
      );
    });

    test('returns waitForToolApproval when any tool call is pending', () async {
      when(messageRepository.getMessageById('message-1')).thenAnswer(
        (_) async => _message(
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'pending-tool',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{}',
              ),
            ],
          ),
        ),
      );

      final result = await usecase.call(messageId: 'message-1');

      expect(result, AgentIterationDecision.waitForToolApproval);
    });

    test(
      'returns continueIteration when all tool calls are resolved',
      () async {
        when(messageRepository.getMessageById('message-2')).thenAnswer(
          (_) async => _message(
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'resolved-tool',
                  name: 'built_in_calc_calculator',
                  argumentsRaw: '{}',
                  resultStatus: ToolCallResultStatus.executionError,
                ),
              ],
            ),
          ),
        );

        final result = await usecase.call(messageId: 'message-2');

        expect(result, AgentIterationDecision.continueIteration);
      },
    );

    test('returns done when a tool status stops the agent loop', () async {
      when(messageRepository.getMessageById('message-3')).thenAnswer(
        (_) async => _message(
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'stopped-tool',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{}',
                resultStatus: ToolCallResultStatus.stoppedByUser,
              ),
            ],
          ),
        ),
      );

      final result = await usecase.call(messageId: 'message-3');

      expect(result, AgentIterationDecision.done);
    });
  });
}

MessageEntity _message({MessageMetadataEntity? metadata}) {
  final now = DateTime(2026);
  return MessageEntity(
    id: 'message-id',
    conversationId: 'conversation-id',
    content: 'content',
    messageType: MessageType.text,
    isUser: false,
    status: MessageStatus.sent,
    createdAt: now,
    updatedAt: now,
    metadata: metadata,
  );
}
