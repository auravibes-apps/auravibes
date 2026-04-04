import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/tools/usecases/get_agent_iteration_decision_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_latest_message_tool_calls_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'run_allowed_tools_usecase_test.mocks.dart';

@GenerateMocks([
  LoadLatestMessageToolCallsUsecase,
  MessageRepository,
  ConversationToolsRepository,
  ToolsGroupsRepository,
  WorkspaceToolsRepository,
  GetAgentIterationDecisionUsecase,
])
void main() {
  group('RunAllowedToolsUsecase', () {
    late MockLoadLatestMessageToolCallsUsecase
    loadLatestMessageToolCallsUsecase;
    late MockMessageRepository messageRepository;
    late MockConversationToolsRepository conversationToolsRepository;
    late MockToolsGroupsRepository toolsGroupsRepository;
    late MockWorkspaceToolsRepository workspaceToolsRepository;
    late MockGetAgentIterationDecisionUsecase getAgentIterationDecisionUsecase;
    late RunAllowedToolsUsecase usecase;
    late MessageEntity toolMessage;

    setUp(() {
      loadLatestMessageToolCallsUsecase =
          MockLoadLatestMessageToolCallsUsecase();
      messageRepository = MockMessageRepository();
      conversationToolsRepository = MockConversationToolsRepository();
      toolsGroupsRepository = MockToolsGroupsRepository();
      workspaceToolsRepository = MockWorkspaceToolsRepository();
      getAgentIterationDecisionUsecase = MockGetAgentIterationDecisionUsecase();

      toolMessage = MessageEntity(
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
              name: 'built_in_calc_calculator',
              argumentsRaw: '{"input": "1+1"}',
            ),
            MessageToolCallEntity(
              id: 'missing-tool',
              name: 'missing',
              argumentsRaw: '{}',
            ),
          ],
        ),
      );

      usecase = RunAllowedToolsUsecase(
        loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
        messageRepository: messageRepository,
        conversationToolsRepository: conversationToolsRepository,
        toolsGroupsRepository: toolsGroupsRepository,
        workspaceToolsRepository: workspaceToolsRepository,
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
      );
    });

    test('returns done when there are no tool calls to process', () async {
      when(
        loadLatestMessageToolCallsUsecase.call(
          conversationId: 'conversation-1',
        ),
      ).thenAnswer(
        (_) async => const LoadLatestMessageToolCallsResult(
          messageId: 'message-1',
          hasToolCalls: false,
          toolsToRun: [],
          notFoundToolCallIds: [],
        ),
      );

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.done);
      verifyNever(
        conversationToolsRepository.checkToolPermission(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
          toolId: anyNamed('toolId'),
        ),
      );
    });

    test(
      'returns waitForToolApproval when filtering leaves pending tools',
      () async {
        final tool = ToolToCall(
          id: 'tool-1',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [tool],
            notFoundToolCallIds: const [],
          ),
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.needsConfirmation);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        verifyNever(
          messageRepository.updateMessage(any, any),
        );
      },
    );

    test(
      'persists not-found tools, executes granted tools, '
      'and returns final decision',
      () async {
        final tool = ToolToCall(
          id: 'tool-1',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [tool],
            notFoundToolCallIds: const ['missing-tool'],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => toolMessage,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);
        when(
          messageRepository.updateMessage('message-1', any),
        ).thenAnswer((_) async => toolMessage);
        when(
          getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.continueIteration);
        final update =
            verify(
                  messageRepository.updateMessage('message-1', captureAny),
                ).captured.single
                as MessageToUpdate;
        final updatedToolCalls = update.metadata?.toolCalls;
        expect(updatedToolCalls, isNotNull);
        expect(
          updatedToolCalls
              ?.firstWhere((toolCall) => toolCall.id == 'tool-1')
              .resultStatus,
          ToolCallResultStatus.success,
        );
        expect(
          updatedToolCalls
              ?.firstWhere((toolCall) => toolCall.id == 'tool-1')
              .responseRaw,
          '2.0',
        );
        expect(
          updatedToolCalls
              ?.firstWhere((toolCall) => toolCall.id == 'missing-tool')
              .resultStatus,
          ToolCallResultStatus.toolNotFound,
        );
      },
    );
  });
}
