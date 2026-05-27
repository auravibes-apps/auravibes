// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/tools/usecases/get_agent_iteration_decision_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_latest_message_tool_calls_result.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_resolved_tool_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'run_allowed_tools_usecase_test.mocks.dart';

@GenerateMocks([
  LoadLatestMessageToolCallsUsecase,
  MessageRepository,
  ResolveToolApprovalDecisionUsecase,
  GetAgentIterationDecisionUsecase,
])
void main() {
  group('RunAllowedToolsUsecase', () {
    late MockLoadLatestMessageToolCallsUsecase
    loadLatestMessageToolCallsUsecase;
    late MockMessageRepository messageRepository;
    late MockResolveToolApprovalDecisionUsecase resolveToolApprovalDecision;
    late MockGetAgentIterationDecisionUsecase getAgentIterationDecisionUsecase;
    late AgentCancellationRuntime agentCancellationRuntime;
    late RunAllowedToolsUsecase usecase;
    late MessageEntity toolMessage;
    String? calledMcpServerId;
    String? calledMcpToolIdentifier;
    Map<String, dynamic>? calledMcpArguments;

    setUp(() {
      loadLatestMessageToolCallsUsecase =
          MockLoadLatestMessageToolCallsUsecase();
      messageRepository = MockMessageRepository();
      resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
      getAgentIterationDecisionUsecase = MockGetAgentIterationDecisionUsecase();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');
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
        resolveToolApprovalDecision: resolveToolApprovalDecision,
        runResolvedToolUsecase: RunResolvedToolUsecase(
          agentCancellationRuntime: agentCancellationRuntime,
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
        ),
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
        agentCancellationRuntime: agentCancellationRuntime,
      );
    });

    test('passes raw argument maps to MCP tools', () async {
      final tool = ToolToCall(
        tool: ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcpServerId: 'server-1',
        ),
        id: 'tool-1',
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
          previouslyFailedToolCallIds: const [],
        ),
      );
      when(messageRepository.getMessageById('message-1')).thenAnswer(
        (_) async => mcpMessage,
      );
      when(
        resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-1',
          resolvedTool: tool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-1',
          permissionResult: ToolPermissionResult.granted,
          permissionTableId: 'workspace-tool-1',
        ),
      );
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
          previouslyFailedToolCallIds: [],
        ),
      );

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.done);
      final _ = verifyNever(
        resolveToolApprovalDecision(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
          toolCallId: anyNamed('toolCallId'),
          resolvedTool: anyNamed('resolvedTool'),
        ),
      );
    });

    test(
      'returns waitForToolApproval when filtering leaves pending tools',
      () async {
        final tool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-1',
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: ToolPermissionResult.needsConfirmation,
            permissionTableId: 'calculator',
          ),
        );

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        final _ = verifyNever(
          messageRepository.patchMessage(any, any),
        );
      },
    );

    test(
      'persists not-found tools, executes granted tools, '
      'and returns final decision',
      () async {
        final tool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-1',
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => toolMessage,
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'calculator',
          ),
        );
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
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-1',
          argumentsRaw: '{"input": "1+1"}',
        );
        final tool2 = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-2',
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => multiToolMessage,
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool1.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'calculator',
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-2',
            resolvedTool: tool2.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-2',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'calculator',
          ),
        );
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
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-good',
          argumentsRaw: '{"input": "1+1"}',
        );
        final badTool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-bad',
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => mixedMessage,
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-good',
            resolvedTool: goodTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-good',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'calculator',
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-bad',
            resolvedTool: badTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-bad',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'calculator',
          ),
        );
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
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-granted',
          argumentsRaw: '{"input": "1+1"}',
        );
        final pendingTool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'other',
            toolIdentifier: 'other_tool',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-pending',
          argumentsRaw: '{"input": "test"}',
        );
        final disabledTool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'disabled',
            toolIdentifier: 'disabled_tool',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-disabled',
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => mixedPermMessage,
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-granted',
            resolvedTool: grantedTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-granted',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'calculator',
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-pending',
            resolvedTool: pendingTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-pending',
            permissionResult: ToolPermissionResult.needsConfirmation,
            permissionTableId: 'other_tool',
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-disabled',
            resolvedTool: disabledTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-disabled',
            permissionResult: ToolPermissionResult.disabledInWorkspace,
            permissionTableId: 'disabled_tool',
          ),
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
          tool: ResolvedTool.builtIn(
            tableId: 'tool-a',
            toolIdentifier: 'tool_a',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-1',
          argumentsRaw: '{"input": "1+1"}',
        );
        final tool2 = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'tool-b',
            toolIdentifier: 'tool_b',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-2',
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool1.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: ToolPermissionResult.needsConfirmation,
            permissionTableId: 'tool_a',
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-2',
            resolvedTool: tool2.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-2',
            permissionResult: ToolPermissionResult.needsConfirmation,
            permissionTableId: 'tool_b',
          ),
        );

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        final _ = verifyNever(
          messageRepository.patchMessage(any, any),
        );
      },
    );
  });

  group('RunAllowedToolsUsecase native tools', () {
    late MockLoadLatestMessageToolCallsUsecase
    loadLatestMessageToolCallsUsecase;
    late MockMessageRepository messageRepository;
    late MockResolveToolApprovalDecisionUsecase resolveToolApprovalDecision;
    late MockGetAgentIterationDecisionUsecase getAgentIterationDecisionUsecase;
    late AgentCancellationRuntime agentCancellationRuntime;
    late RunAllowedToolsUsecase usecase;

    setUp(() {
      loadLatestMessageToolCallsUsecase =
          MockLoadLatestMessageToolCallsUsecase();
      messageRepository = MockMessageRepository();
      resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
      getAgentIterationDecisionUsecase = MockGetAgentIterationDecisionUsecase();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');

      usecase = RunAllowedToolsUsecase(
        loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
        messageRepository: messageRepository,
        resolveToolApprovalDecision: resolveToolApprovalDecision,
        runResolvedToolUsecase: RunResolvedToolUsecase(
          agentCancellationRuntime: agentCancellationRuntime,
          mcpToolCaller:
              ({
                required mcpServerId,
                required toolIdentifier,
                required arguments,
              }) async {
                return 'mcp result';
              },
        ),
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
        agentCancellationRuntime: agentCancellationRuntime,
      );
    });

    test(
      'T003: native tool with alwaysAsk permission returns '
      'needsConfirmation (not notConfigured)',
      () async {
        final nativeTool = ToolToCall(
          tool: ResolvedTool.native(
            tableId: 'ws-tool-url-id',
            nativeToolType: NativeToolType.url,
          ),
          id: 'native-tool-1',
          argumentsRaw: '{"input": "https://example.com"}',
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [nativeTool],
            notFoundToolCallIds: const [],
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'native-tool-1',
            permissionResult: ToolPermissionResult.needsConfirmation,
            permissionTableId: 'url',
          ),
        );

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        verify(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).called(1);
        final _ = verifyNever(
          messageRepository.patchMessage(any, any),
        );
      },
    );

    test(
      'T004: native tool with alwaysAllow permission returns '
      'granted and executes',
      () async {
        final nativeTool = ToolToCall(
          tool: ResolvedTool.native(
            tableId: 'ws-tool-url-id',
            nativeToolType: NativeToolType.url,
          ),
          id: 'native-tool-1',
          argumentsRaw: '{"input": "https://example.com"}',
        );

        final nativeMessage = MessageEntity(
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
                id: 'native-tool-1',
                name: 'native_ws-tool-url-id_url',
                argumentsRaw: '{"input": "https://example.com"}',
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
            toolsToRun: [nativeTool],
            notFoundToolCallIds: const [],
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'native-tool-1',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'url',
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => nativeMessage,
        );
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => nativeMessage);
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
              ?.firstWhere((tc) => tc.id == 'native-tool-1')
              .resultStatus,
          ToolCallResultStatus.success,
        );
      },
    );

    test(
      'T010: native tool with notConfigured permission persists '
      'status to message metadata',
      () async {
        final nativeTool = ToolToCall(
          tool: ResolvedTool.native(
            tableId: 'ws-tool-url-id',
            nativeToolType: NativeToolType.url,
          ),
          id: 'native-tool-1',
          argumentsRaw: '{"input": "https://example.com"}',
        );

        final nativeMessage = MessageEntity(
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
                id: 'native-tool-1',
                name: 'native_ws-tool-url-id_url',
                argumentsRaw: '{"input": "https://example.com"}',
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
            toolsToRun: [nativeTool],
            notFoundToolCallIds: const [],
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'native-tool-1',
            permissionResult: ToolPermissionResult.notConfigured,
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => nativeMessage,
        );
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => nativeMessage);
        when(
          getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.done);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.done);
        final update =
            verify(
                  messageRepository.patchMessage('message-1', captureAny),
                ).captured.single
                as MessagePatch;
        final updatedToolCalls = update.metadata?.toolCalls;
        expect(updatedToolCalls, isNotNull);
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'native-tool-1')
              .resultStatus,
          ToolCallResultStatus.notConfigured,
        );
      },
    );

    test(
      'T014: notConfigured error includes tool name and '
      'descriptive message in responseRaw',
      () async {
        final nativeTool = ToolToCall(
          tool: ResolvedTool.native(
            tableId: 'ws-tool-url-id',
            nativeToolType: NativeToolType.url,
          ),
          id: 'native-tool-1',
          argumentsRaw: '{"input": "https://example.com"}',
        );

        final nativeMessage = MessageEntity(
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
                id: 'native-tool-1',
                name: 'native_ws-tool-url-id_url',
                argumentsRaw: '{"input": "https://example.com"}',
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
            toolsToRun: [nativeTool],
            notFoundToolCallIds: const [],
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'native-tool-1',
            permissionResult: ToolPermissionResult.notConfigured,
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => nativeMessage,
        );
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => nativeMessage);
        when(
          getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.done);

        final _ = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        final update =
            verify(
                  messageRepository.patchMessage('message-1', captureAny),
                ).captured.single
                as MessagePatch;
        final tc = update.metadata?.toolCalls.firstWhere(
          (t) => t.id == 'native-tool-1',
        );
        expect(tc?.responseRaw, contains('url'));
        expect(tc?.responseRaw, isNot(contains('null')));
      },
    );

    test(
      'T015: disabledInWorkspace error includes tool name in responseRaw',
      () async {
        final nativeTool = ToolToCall(
          tool: ResolvedTool.native(
            tableId: 'ws-tool-url-id',
            nativeToolType: NativeToolType.url,
          ),
          id: 'native-tool-1',
          argumentsRaw: '{"input": "https://example.com"}',
        );

        final nativeMessage = MessageEntity(
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
                id: 'native-tool-1',
                name: 'native_ws-tool-url-id_url',
                argumentsRaw: '{"input": "https://example.com"}',
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
            toolsToRun: [nativeTool],
            notFoundToolCallIds: const [],
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'native-tool-1',
            permissionResult: ToolPermissionResult.disabledInWorkspace,
            permissionTableId: 'url',
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => nativeMessage,
        );
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => nativeMessage);
        when(
          getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.done);

        final _ = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        final update =
            verify(
                  messageRepository.patchMessage('message-1', captureAny),
                ).captured.single
                as MessagePatch;
        final tc = update.metadata?.toolCalls.firstWhere(
          (t) => t.id == 'native-tool-1',
        );
        expect(tc?.responseRaw, contains('url'));
      },
    );
  });

  group('RunAllowedToolsUsecase cancellation and error paths', () {
    late MockLoadLatestMessageToolCallsUsecase
    loadLatestMessageToolCallsUsecase;
    late MockMessageRepository messageRepository;
    late MockResolveToolApprovalDecisionUsecase resolveToolApprovalDecision;
    late MockGetAgentIterationDecisionUsecase getAgentIterationDecisionUsecase;
    late AgentCancellationRuntime agentCancellationRuntime;
    late RunAllowedToolsUsecase usecase;

    setUp(() {
      loadLatestMessageToolCallsUsecase =
          MockLoadLatestMessageToolCallsUsecase();
      messageRepository = MockMessageRepository();
      resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
      getAgentIterationDecisionUsecase = MockGetAgentIterationDecisionUsecase();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');

      usecase = RunAllowedToolsUsecase(
        loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
        messageRepository: messageRepository,
        resolveToolApprovalDecision: resolveToolApprovalDecision,
        runResolvedToolUsecase: RunResolvedToolUsecase(
          agentCancellationRuntime: agentCancellationRuntime,
          mcpToolCaller:
              ({
                required mcpServerId,
                required toolIdentifier,
                required arguments,
              }) async {
                return 'mcp result';
              },
        ),
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
        agentCancellationRuntime: agentCancellationRuntime,
      );
    });

    test(
      'marks previously failed tool calls with executionError',
      () async {
        final tool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-1',
          argumentsRaw: '{"input": "1+1"}',
        );

        final failedMessage = MessageEntity(
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
                id: 'failed-tool',
                name: 'failed',
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
            toolsToRun: [tool],
            notFoundToolCallIds: const [],
            previouslyFailedToolCallIds: const ['failed-tool'],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => failedMessage,
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'calculator',
          ),
        );
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => failedMessage);
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
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'failed-tool')
              .resultStatus,
          ToolCallResultStatus.executionError,
        );
        expect(
          updatedToolCalls?.firstWhere((tc) => tc.id == 'tool-1').resultStatus,
          ToolCallResultStatus.success,
        );
      },
    );

    test(
      'returns done when cancellation is requested before processing',
      () async {
        final tool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-1',
          argumentsRaw: '{"input": "1+1"}',
        );

        final cancelMessage = MessageEntity(
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => cancelMessage,
        );
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => cancelMessage);

        agentCancellationRuntime.requestStop('conversation-1');

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.done);
      },
    );

    test(
      'handles disabledInConversation permission result',
      () async {
        final tool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-1',
          argumentsRaw: '{"input": "1+1"}',
        );

        final disabledMessage = MessageEntity(
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => disabledMessage,
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: ToolPermissionResult.disabledInConversation,
            permissionTableId: 'calculator',
          ),
        );
        when(
          messageRepository.patchMessage('message-1', any),
        ).thenAnswer((_) async => disabledMessage);
        when(
          getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.done);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.done);
        final update =
            verify(
                  messageRepository.patchMessage('message-1', captureAny),
                ).captured.single
                as MessagePatch;
        final tc = update.metadata?.toolCalls.first;
        expect(tc?.resultStatus, ToolCallResultStatus.disabledInConversation);
        expect(tc?.responseRaw, contains('calculator'));
      },
    );

    test(
      'skips tool when message not found for update',
      () async {
        final tool = ToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          id: 'tool-1',
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
            previouslyFailedToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => null,
        );
        when(
          resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: ToolPermissionResult.granted,
            permissionTableId: 'calculator',
          ),
        );
        when(
          getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.continueIteration);
        final _ = verifyNever(
          messageRepository.patchMessage(any, any),
        );
      },
    );
  });
}
