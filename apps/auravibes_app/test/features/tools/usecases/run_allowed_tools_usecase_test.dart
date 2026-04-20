import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
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
    String? calledMcpServerId;
    String? calledMcpToolIdentifier;
    Map<String, dynamic>? calledMcpArguments;

    setUp(() {
      loadLatestMessageToolCallsUsecase =
          MockLoadLatestMessageToolCallsUsecase();
      messageRepository = MockMessageRepository();
      conversationToolsRepository = MockConversationToolsRepository();
      toolsGroupsRepository = MockToolsGroupsRepository();
      workspaceToolsRepository = MockWorkspaceToolsRepository();
      getAgentIterationDecisionUsecase = MockGetAgentIterationDecisionUsecase();
      calledMcpServerId = null;
      calledMcpToolIdentifier = null;
      calledMcpArguments = null;

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
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
            }) async {
              calledMcpServerId = mcpServerId;
              calledMcpToolIdentifier = toolIdentifier;
              calledMcpArguments = arguments;
              return 'mcp result';
            },
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
      );
    });

    test('passes raw argument maps to MCP tools', () async {
      final tool = ToolToCall(
        id: 'tool-1',
        tool: ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcpServerId: 'server-1',
        ),
        argumentsRaw: '{"a": 1, "b": 2}',
      );

      final mcpMessage = toolMessage.copyWith(
        metadata: const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'mcp_server-1_calc_sum',
              argumentsRaw: '{"a": 1, "b": 2}',
            ),
          ],
        ),
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
      when(messageRepository.getMessageById('message-1')).thenAnswer(
        (_) async => mcpMessage,
      );
      when(
        toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
      ).thenAnswer(
        (_) async => ToolsGroupEntity(
          id: 'group-1',
          workspaceId: 'workspace-1',
          name: 'Group',
          isEnabled: true,
          permissions: PermissionAccess.ask,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          mcpServerId: 'server-1',
        ),
      );
      when(
        workspaceToolsRepository.getWorkspaceToolByToolName(
          toolGroupId: 'group-1',
          toolName: 'sum',
        ),
      ).thenAnswer(
        (_) async => WorkspaceToolEntity(
          id: 'workspace-tool-1',
          workspaceId: 'workspace-1',
          toolId: 'sum',
          isEnabled: true,
          permissionMode: ToolPermissionMode.alwaysAllow,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceToolsGroupId: 'group-1',
        ),
      );
      when(
        conversationToolsRepository.checkToolPermission(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolId: 'workspace-tool-1',
        ),
      ).thenAnswer((_) async => ToolPermissionResult.granted);
      when(
        messageRepository.patchMessage('message-1', any),
      ).thenAnswer((_) async => mcpMessage);
      when(
        getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
      ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.continueIteration);
      expect(calledMcpServerId, 'server-1');
      expect(calledMcpToolIdentifier, 'sum');
      expect(calledMcpArguments, {'a': 1, 'b': 2});
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
          messageRepository.patchMessage(any, any),
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
          messageRepository.patchMessage('message-1', any),
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
                  messageRepository.patchMessage('message-1', captureAny),
                ).captured.single
                as MessagePatch;
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

    test(
      'executes multiple granted tools and collects all results',
      () async {
        final tool1 = ToolToCall(
          id: 'tool-1',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );
        final tool2 = ToolToCall(
          id: 'tool-2',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "2+2"}',
        );

        final multiToolMessage = MessageEntity(
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
                id: 'tool-2',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input": "2+2"}',
              ),
            ],
          ),
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [tool1, tool2],
            notFoundToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => multiToolMessage,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => multiToolMessage);
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
                  messageRepository.patchMessage('message-1', captureAny),
                ).captured.single
                as MessagePatch;
        final updatedToolCalls = update.metadata?.toolCalls;
        expect(updatedToolCalls, isNotNull);
        expect(
          updatedToolCalls?.firstWhere((tc) => tc.id == 'tool-1').resultStatus,
          ToolCallResultStatus.success,
        );
        expect(
          updatedToolCalls?.firstWhere((tc) => tc.id == 'tool-2').resultStatus,
          ToolCallResultStatus.success,
        );
      },
    );

    test(
      'one tool failure does not block other tools from completing',
      () async {
        final goodTool = ToolToCall(
          id: 'tool-good',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );
        final badTool = ToolToCall(
          id: 'tool-bad',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{}',
        );

        final mixedMessage = MessageEntity(
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
                id: 'tool-good',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input": "1+1"}',
              ),
              MessageToolCallEntity(
                id: 'tool-bad',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{}',
              ),
            ],
          ),
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [goodTool, badTool],
            notFoundToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => mixedMessage,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => mixedMessage);
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
                  messageRepository.patchMessage('message-1', captureAny),
                ).captured.single
                as MessagePatch;
        final updatedToolCalls = update.metadata?.toolCalls;
        expect(updatedToolCalls, isNotNull);
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-good')
              .resultStatus,
          ToolCallResultStatus.success,
        );
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-bad')
              .resultStatus,
          ToolCallResultStatus.executionError,
        );
      },
    );

    test(
      'correctly partitions tools with mixed permissions',
      () async {
        final grantedTool = ToolToCall(
          id: 'tool-granted',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );
        final pendingTool = ToolToCall(
          id: 'tool-pending',
          tool: ResolvedTool.builtIn(
            tableId: 'other',
            toolIdentifier: 'other_tool',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "test"}',
        );
        final disabledTool = ToolToCall(
          id: 'tool-disabled',
          tool: ResolvedTool.builtIn(
            tableId: 'disabled',
            toolIdentifier: 'disabled_tool',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "test"}',
        );

        final mixedPermMessage = MessageEntity(
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
                id: 'tool-granted',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input": "1+1"}',
              ),
              MessageToolCallEntity(
                id: 'tool-pending',
                name: 'other_tool',
                argumentsRaw: '{"input": "test"}',
              ),
              MessageToolCallEntity(
                id: 'tool-disabled',
                name: 'disabled_tool',
                argumentsRaw: '{"input": "test"}',
              ),
            ],
          ),
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [grantedTool, pendingTool, disabledTool],
            notFoundToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => mixedPermMessage,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'other',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.needsConfirmation,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'disabled',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.disabledInWorkspace,
        );
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => mixedPermMessage);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        final update =
            verify(
                  messageRepository.patchMessage('message-1', captureAny),
                ).captured.single
                as MessagePatch;
        final updatedToolCalls = update.metadata?.toolCalls;
        expect(updatedToolCalls, isNotNull);
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-granted')
              .resultStatus,
          ToolCallResultStatus.success,
        );
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-pending')
              .resultStatus,
          isNull,
        );
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-disabled')
              .resultStatus,
          ToolCallResultStatus.disabledInWorkspace,
        );
      },
    );

    test(
      'returns waitForToolApproval when all tools need confirmation',
      () async {
        final tool1 = ToolToCall(
          id: 'tool-1',
          tool: ResolvedTool.builtIn(
            tableId: 'tool-a',
            toolIdentifier: 'tool_a',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );
        final tool2 = ToolToCall(
          id: 'tool-2',
          tool: ResolvedTool.builtIn(
            tableId: 'tool-b',
            toolIdentifier: 'tool_b',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "2+2"}',
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [tool1, tool2],
            notFoundToolCallIds: const [],
          ),
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'tool-a',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.needsConfirmation,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'tool-b',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.needsConfirmation,
        );

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        verifyNever(
          messageRepository.patchMessage(any, any),
        );
      },
    );
  });
}
