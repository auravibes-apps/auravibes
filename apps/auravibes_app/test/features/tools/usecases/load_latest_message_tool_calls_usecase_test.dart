import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/tools/usecases/load_latest_message_tool_calls_usecase.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'load_latest_message_tool_calls_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('LoadLatestMessageToolCallsUsecase', () {
    late MockMessageRepository messageRepository;
    late LoadLatestMessageToolCallsUsecase usecase;

    setUp(() {
      messageRepository = MockMessageRepository();
      usecase = LoadLatestMessageToolCallsUsecase(
        messageRepository: messageRepository,
        toolResolverService: ToolResolverService(),
      );
    });

    test(
      'returns pending resolved tools and not-found ids '
      'from latest assistant message',
      () async {
        when(
          messageRepository.getMessagesByConversation('conversation-1'),
        ).thenAnswer(
          (_) async => [
            _message(
              id: 'user-1',
              isUser: true,
            ),
            _message(
              id: 'assistant-1',
              metadata: const MessageMetadataEntity(
                toolCalls: [
                  MessageToolCallEntity(
                    id: 'resolved-tool',
                    name: 'built_in_calc_calculator',
                    argumentsRaw: '{}',
                  ),
                  MessageToolCallEntity(
                    id: 'missing-tool',
                    name: 'unknown_tool',
                    argumentsRaw: '{}',
                  ),
                  MessageToolCallEntity(
                    id: 'already-resolved',
                    name: 'built_in_calc_calculator',
                    argumentsRaw: '{}',
                    resultStatus: ToolCallResultStatus.success,
                  ),
                ],
              ),
            ),
          ],
        );

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result.messageId, 'assistant-1');
        expect(result.toolsToRun.map((tool) => tool.id), ['resolved-tool']);
        expect(result.notFoundToolCallIds, ['missing-tool']);
      },
    );

    test(
      'returns empty result when latest assistant message has no tool calls',
      () async {
        when(
          messageRepository.getMessagesByConversation('conversation-2'),
        ).thenAnswer(
          (_) async => [
            _message(id: 'assistant-2'),
          ],
        );

        final result = await usecase.call(conversationId: 'conversation-2');

        expect(result.messageId, 'assistant-2');
        expect(result.toolsToRun, isEmpty);
        expect(result.notFoundToolCallIds, isEmpty);
        expect(result.hasToolCalls, isFalse);
      },
    );
  });
}

MessageEntity _message({
  required String id,
  bool isUser = false,
  MessageMetadataEntity? metadata,
}) {
  final now = DateTime(2026);
  return MessageEntity(
    id: id,
    conversationId: 'conversation-1',
    content: 'content',
    messageType: MessageType.text,
    isUser: isUser,
    status: MessageStatus.sent,
    createdAt: now,
    updatedAt: now,
    metadata: metadata,
  );
}
