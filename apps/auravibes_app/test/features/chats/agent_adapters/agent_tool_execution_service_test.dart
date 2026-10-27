// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_execution_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        AgentIterationDecision,
        AgentToolPermissionResult,
        AgentToolResultUpdate,
        AgentToolToCall,
        LoadLatestMessageToolCallsResult,
        activateSkillToolName;
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('AgentToolExecutionService', () {
    var loadLatestMessageToolCallsUsecase = MockAgentToolCallLoader();
    var messageRepository = MockMessageRepository();
    var resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
    var getAgentIterationDecisionUsecase = MockAgentToolDecisionService();
    var agentCancellationRuntime = AgentCancellationRuntime()
      ..start('conversation-1');
    var toolMessage = _runAllowedToolsToolMessage();
    String? calledMcpServerId;
    String? calledMcpToolIdentifier;
    Map<String, dynamic>? calledMcpArguments;
    var usecase = AgentToolExecutionService(
      loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
      messageRepository: messageRepository,
      runResolvedToolUsecase: .new(
        agentCancellationRuntime: agentCancellationRuntime,
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
              onElicitation,
            }) async {
              calledMcpServerId = mcpServerId;
              calledMcpToolIdentifier = toolIdentifier;
              calledMcpArguments = arguments;

              return 'mcp result';
            },
      ),
      getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
      agentCancellationRuntime: agentCancellationRuntime,
      resolveToolApprovalDecision: resolveToolApprovalDecision,
    );

    setUp(() {
      loadLatestMessageToolCallsUsecase = MockAgentToolCallLoader();
      messageRepository = MockMessageRepository();
      resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
      getAgentIterationDecisionUsecase = MockAgentToolDecisionService();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');
      calledMcpServerId = null;
      calledMcpToolIdentifier = null;
      calledMcpArguments = null;

      toolMessage = _runAllowedToolsToolMessage();
      when(() => messageRepository.getMessageById(any()))
          .thenAnswer((_) async => toolMessage);
      when(
        () => messageRepository.patchMessage(
          any(),
          any(),
          conversationId: any(named: 'conversationId'),
        ),
      ).thenAnswer((_) async => toolMessage);

      usecase = AgentToolExecutionService(
        loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
        messageRepository: messageRepository,
        runResolvedToolUsecase: .new(
          agentCancellationRuntime: agentCancellationRuntime,
          mcpToolCaller:
              ({
                required mcpServerId,
                required toolIdentifier,
                required arguments,
                onElicitation,
              }) async {
                calledMcpServerId = mcpServerId;
                calledMcpToolIdentifier = toolIdentifier;
                calledMcpArguments = arguments;

                return 'mcp result';
              },
        ),
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
        agentCancellationRuntime: agentCancellationRuntime,
        resolveToolApprovalDecision: resolveToolApprovalDecision,
      );
    });

    test(
      'workspace read result is redacted before message persistence',
      () async {
        const call = MessageToolCallEntity(
          id: 'read-file',
          name: 'workspace_item',
          argumentsRaw: '{"action":"read","id":"file"}',
        );
        toolMessage = toolMessage.copyWith(metadata: .new(toolCalls: [call]));
        final provider = AppAllowedToolsDataProvider(
          messageRepository: messageRepository,
          loadLatestMessageToolCallsService: loadLatestMessageToolCallsUsecase,
          resolvedToolService: .new(
            agentCancellationRuntime: agentCancellationRuntime,
            mcpToolCaller: ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
              onElicitation,
            }) async => 'unused',
          ),
          toolDecisionService: getAgentIterationDecisionUsecase,
          agentCancellationRuntime: agentCancellationRuntime,
          resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
        );
        await provider.updateToolResults(
          conversationId: 'conversation-1',
          messageId: toolMessage.id,
          updates: [
            const AgentToolResultUpdate(
              toolCallId: 'read-file',
              resultStatus: .success,
              responseRaw: '{"kind":"file","content":"private bytes"}',
              responseContextRaw: '{"kind":"file","content":"private bytes"}',
            ),
          ],
        );
        final patch =
            verify(
                  () => messageRepository.patchMessage(
                    any(),
                    captureAny(),
                    conversationId: 'conversation-1',
                  ),
                ).captured.single
                as MessagePatch;
        final saved = patch.metadata?.toolCalls.single;
        expect(saved?.responseRaw, '{"redacted":true}');
        expect(saved?.responseContextRaw, '{"redacted":true}');
        expect(
          jsonEncode(patch.metadata?.toJson()),
          isNot(contains('private bytes')),
        );
      },
    );

    test('uses a workspace resolver without a legacy fallback', () async {
      final workspaceResolver = MockResolveToolApprovalDecisionUsecase();
      final provider = AppAllowedToolsDataProvider(
        messageRepository: messageRepository,
        loadLatestMessageToolCallsService: loadLatestMessageToolCallsUsecase,
        resolvedToolService: .new(
          agentCancellationRuntime: agentCancellationRuntime,
          mcpToolCaller: ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
            onElicitation,
          }) async => 'unused',
        ),
        toolDecisionService: getAgentIterationDecisionUsecase,
        agentCancellationRuntime: agentCancellationRuntime,
        resolveToolApprovalDecisionUsecaseForWorkspace: (_) =>
            workspaceResolver,
      );
      final tool = ResolvedTool.mcp(
        tableId: 'tool-1',
        toolIdentifier: 'sum',
        mcp: (
          mcpServerId: 'server-1',
          mcpSlug: 'server-1',
          outputSchemaJson: null,
        ),
      );
      when(
        () => workspaceResolver(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-call-1',
          resolvedTool: tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-call-1',
          permissionResult: .granted,
        ),
      );

      final decision = await provider.resolveToolApprovalDecision((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolCallId: 'tool-call-1',
        resolvedTool: tool,
        argumentsRaw: '{}',
      ));

      expect(decision.permissionResult.name, 'granted');
    });

    test(
      'logs execution phase and redacted unsupported error details',
      () async {
        final provider = AppAllowedToolsDataProvider(
          messageRepository: messageRepository,
          loadLatestMessageToolCallsService: loadLatestMessageToolCallsUsecase,
          resolvedToolService: .new(
            agentCancellationRuntime: agentCancellationRuntime,
            mcpToolCaller: ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
              onElicitation,
            }) async => 'unused',
          ),
          toolDecisionService: getAgentIterationDecisionUsecase,
          agentCancellationRuntime: agentCancellationRuntime,
        );
        final messages = <String>[];
        final subscription = Logger.root.onRecord.listen((record) {
          if (record.loggerName == 'agent_tool_execution_service') {
            messages.add(record.message);
          }
        });

        provider
          ..logToolExecutionError((
            conversationId: 'conversation-1',
            toolCallId: 'call-1',
            tool: ResolvedTool.skillControl(
              toolIdentifier: activateSkillToolName,
            ),
            error: UnsupportedError(
              'App skill tool has no executor: browser_read_page '
              'apiKey=secret',
            ),
            stackTrace: StackTrace.current,
            failurePhase: 'activateSkill',
          ))
          ..logToolExecutionError((
            conversationId: 'conversation-1',
            toolCallId: 'call-2',
            tool: ResolvedTool.skillControl(
              toolIdentifier: activateSkillToolName,
            ),
            error: TimeoutException(
              'Waiting for WebView.',
              const Duration(seconds: 8),
            ),
            stackTrace: StackTrace.current,
            failurePhase: 'activateSkill',
          ));
        await Future<void>.delayed(.zero);
        await subscription.cancel();

        expect(messages, hasLength(2));
        final unsupportedMessage = messages.singleWhere(
          (message) => message.contains('errorType=UnsupportedError'),
        );
        final timeoutMessage = messages.singleWhere(
          (message) => message.contains('errorType=TimeoutException'),
        );
        expect(unsupportedMessage, contains('failurePhase=activateSkill'));
        expect(
          unsupportedMessage,
          contains('App skill tool has no executor: browser_read_page'),
        );
        expect(unsupportedMessage, isNot(contains('apiKey=secret')));
        expect(timeoutMessage, contains('duration=8s'));
      },
    );

    group('approval targets', () {
      test('passes native Skill tool to approval unchanged', () async {
        final directTool = ResolvedTool.skillNative(
          tableId: 'list_agents',
          skillSlug: 'agents',
          toolIdentifier: 'list_agents',
        );
        final provider = AppAllowedToolsDataProvider(
          messageRepository: messageRepository,
          loadLatestMessageToolCallsService: loadLatestMessageToolCallsUsecase,
          resolvedToolService: .new(
            agentCancellationRuntime: agentCancellationRuntime,
            mcpToolCaller: ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
              onElicitation,
            }) async => 'unused',
          ),
          toolDecisionService: getAgentIterationDecisionUsecase,
          agentCancellationRuntime: agentCancellationRuntime,
          resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
        );
        when(
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-call-1',
            resolvedTool: directTool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-call-1',
            permissionResult: .granted,
          ),
        );

        final decision = await provider.resolveToolApprovalDecision((
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-call-1',
          resolvedTool: directTool,
          argumentsRaw: '{}',
        ));

        verify(
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-call-1',
            resolvedTool: directTool,
          ),
        ).called(1);
        expect(decision.permissionResult, AgentToolPermissionResult.granted);
      });
    });

    test('passes raw argument maps to MCP tools', () async {
      final tool = AgentToolToCall(
        tool: ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcp: (
            mcpServerId: 'server-1',
            mcpSlug: 'server-1',
            outputSchemaJson: null,
          ),
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
        () => loadLatestMessageToolCallsUsecase.call(
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
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => mcpMessage);
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-1',
          resolvedTool: tool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-1',
          permissionResult: .granted,
          permissionTableId: 'workspace-tool-1',
        ),
      );
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => mcpMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.continueIteration);

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
        () => loadLatestMessageToolCallsUsecase.call(
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
        () => resolveToolApprovalDecision(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          toolCallId: any(named: 'toolCallId'),
          resolvedTool: any(named: 'resolvedTool'),
        ),
      );
    });

    test(
      'returns waitForToolApproval when filtering leaves pending tools',
      () async {
        final tool = AgentToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: .calculator,
          ),
          id: 'tool-1',
          argumentsRaw: '{"input": "1+1"}',
        );

        when(
          () => loadLatestMessageToolCallsUsecase.call(
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
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: .needsConfirmation,
            permissionTableId: 'calculator',
          ),
        );

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        final patches = verify(
          () => messageRepository.patchMessage(
            any(),
            captureAny(),
            conversationId: 'conversation-1',
          ),
        ).captured.cast<MessagePatch>();
        expect(patches, isNotEmpty);
        final restored =
            MessageMetadataEntity.fromJsonString(
              jsonEncode(
                (patches.last.metadata ?? fail('Expected metadata')).toJson(),
              ),
            ) ??
            fail('Expected restored metadata');
        expect(restored.toolCalls.first.approvalRequested, isTrue);
        when(
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: .granted,
          ),
        );
        when(
          () => loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => const LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [],
            notFoundToolCallIds: [],
            previouslyFailedToolCallIds: [],
            pendingApprovalToolCallIds: ['tool-1'],
          ),
        );
        clearInteractions(resolveToolApprovalDecision);
        expect(
          await usecase.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
          AgentIterationDecision.waitForToolApproval,
        );
        verifyZeroInteractions(resolveToolApprovalDecision);
      },
    );

    test('persists, executes, and returns final decision', () async {
      final tool = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
        ),
        id: 'tool-1',
        argumentsRaw: '{"input": "1+1"}',
      );

      when(
        () => loadLatestMessageToolCallsUsecase.call(
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
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => toolMessage);
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-1',
          resolvedTool: tool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-1',
          permissionResult: .granted,
          permissionTableId: 'calculator',
        ),
      );
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => toolMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.continueIteration);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.continueIteration);
      final updatedToolCalls = _capturedToolCalls(messageRepository);
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
    });

    test('persists MCP App data separately from model output', () async {
      const appData = <String, Object?>{
        'content': [
          {'type': 'text', 'text': 'tool result'},
        ],
        '_meta': {
          'ui': {'resourceUri': 'ui://tool/view'},
        },
      };
      final tool = AgentToolToCall(
        tool: ResolvedTool.mcp(
          tableId: 'tool-1',
          toolIdentifier: 'remote-tool',
          mcp: (
            mcpServerId: 'server-1',
            mcpSlug: 'server-1',
            outputSchemaJson: null,
          ),
        ),
        id: 'tool-1',
        argumentsRaw: '{}',
      );
      final service = AgentToolExecutionService(
        loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
        messageRepository: messageRepository,
        runResolvedToolUsecase: .new(
          agentCancellationRuntime: agentCancellationRuntime,
          mcpToolCaller:
              ({
                required mcpServerId,
                required toolIdentifier,
                required arguments,
                onElicitation,
              }) async => const McpToolCallerResult(
                modelText: 'model result',
                appData: appData,
              ),
        ),
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
        agentCancellationRuntime: agentCancellationRuntime,
        resolveToolApprovalDecision: resolveToolApprovalDecision,
      );

      when(
        () => loadLatestMessageToolCallsUsecase.call(
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
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => toolMessage);
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-1',
          resolvedTool: tool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-1',
          permissionResult: .granted,
        ),
      );
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => toolMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.continueIteration);

      final _ = await service.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      final updatedToolCalls = _capturedToolCalls(messageRepository);
      if (updatedToolCalls == null) fail('Expected persisted tool calls.');
      final updatedToolCall = updatedToolCalls.singleWhere(
        (value) => value.id == 'tool-1',
      );
      expect(updatedToolCall.responseRaw, 'model result');
      expect(updatedToolCall.appData, appData);
    });

    test('executes multiple granted tools and collects all results', () async {
      final tool1 = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
        ),
        id: 'tool-1',
        argumentsRaw: '{"input": "1+1"}',
      );
      final tool2 = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
        ),
        id: 'tool-2',
        argumentsRaw: '{"input": "2+2"}',
      );

      final multiToolMessage = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: 'assistant',
        messageType: .text,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
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
        () => loadLatestMessageToolCallsUsecase.call(
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
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => multiToolMessage);
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-1',
          resolvedTool: tool1.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-1',
          permissionResult: .granted,
          permissionTableId: 'calculator',
        ),
      );
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-2',
          resolvedTool: tool2.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-2',
          permissionResult: .granted,
          permissionTableId: 'calculator',
        ),
      );
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => multiToolMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.continueIteration);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.continueIteration);
      final updatedToolCalls = _capturedToolCalls(messageRepository);
      expect(updatedToolCalls, isNotNull);
      expect(
        updatedToolCalls?.firstWhere((tc) => tc.id == 'tool-1').resultStatus,
        ToolCallResultStatus.success,
      );
      expect(
        updatedToolCalls?.firstWhere((tc) => tc.id == 'tool-2').resultStatus,
        ToolCallResultStatus.success,
      );
    });

    test(
      'one tool failure does not block other tools from completing',
      () async {
        final goodTool = AgentToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: .calculator,
          ),
          id: 'tool-good',
          argumentsRaw: '{"input": "1+1"}',
        );
        final badTool = AgentToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: .calculator,
          ),
          id: 'tool-bad',
          argumentsRaw: '{}',
        );

        final mixedMessage = MessageEntity(
          id: 'message-1',
          conversationId: 'conversation-1',
          content: 'assistant',
          messageType: .text,
          isUser: false,
          status: .sent,
          createdAt: .new(2026),
          updatedAt: .new(2026),
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
          () => loadLatestMessageToolCallsUsecase.call(
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
        when(() => messageRepository.getMessageById('message-1'))
            .thenAnswer((_) async => mixedMessage);
        when(
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-good',
            resolvedTool: goodTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-good',
            permissionResult: .granted,
            permissionTableId: 'calculator',
          ),
        );
        when(
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-bad',
            resolvedTool: badTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-bad',
            permissionResult: .granted,
            permissionTableId: 'calculator',
          ),
        );
        when(
          () => messageRepository.patchMessage(
            'message-1',
            any(),
            conversationId: 'conversation-1',
          ),
        ).thenAnswer((_) async => mixedMessage);
        when(
          () => getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.continueIteration);
        final updatedToolCalls = _capturedToolCalls(messageRepository);
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

    test('correctly partitions tools with mixed permissions', () async {
      final grantedTool = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
        ),
        id: 'tool-granted',
        argumentsRaw: '{"input": "1+1"}',
      );
      final pendingTool = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'other',
          toolIdentifier: 'other_tool',
          tooltype: .calculator,
        ),
        id: 'tool-pending',
        argumentsRaw: '{"input": "test"}',
      );
      final disabledTool = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'disabled',
          toolIdentifier: 'disabled_tool',
          tooltype: .calculator,
        ),
        id: 'tool-disabled',
        argumentsRaw: '{"input": "test"}',
      );

      final mixedPermMessage = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: 'assistant',
        messageType: .text,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
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
        () => loadLatestMessageToolCallsUsecase.call(
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
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => mixedPermMessage);
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-granted',
          resolvedTool: grantedTool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-granted',
          permissionResult: .granted,
          permissionTableId: 'calculator',
        ),
      );
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-pending',
          resolvedTool: pendingTool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-pending',
          permissionResult: .needsConfirmation,
          permissionTableId: 'other_tool',
        ),
      );
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-disabled',
          resolvedTool: disabledTool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-disabled',
          permissionResult: .disabledByAgent,
          permissionTableId: 'disabled_tool',
        ),
      );
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => mixedPermMessage);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.waitForToolApproval);
      final updatedToolCalls = _capturedToolCalls(messageRepository);
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
        ToolCallResultStatus.disabledByAgent,
      );
    });

    test(
      'returns waitForToolApproval when all tools need confirmation',
      () async {
        final tool1 = AgentToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'tool-a',
            toolIdentifier: 'tool_a',
            tooltype: .calculator,
          ),
          id: 'tool-1',
          argumentsRaw: '{"input": "1+1"}',
        );
        final tool2 = AgentToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'tool-b',
            toolIdentifier: 'tool_b',
            tooltype: .calculator,
          ),
          id: 'tool-2',
          argumentsRaw: '{"input": "2+2"}',
        );

        when(
          () => loadLatestMessageToolCallsUsecase.call(
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
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-1',
            resolvedTool: tool1.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-1',
            permissionResult: .needsConfirmation,
            permissionTableId: 'tool_a',
          ),
        );
        when(
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'tool-2',
            resolvedTool: tool2.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'tool-2',
            permissionResult: .needsConfirmation,
            permissionTableId: 'tool_b',
          ),
        );

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        final patches = verify(
          () => messageRepository.patchMessage(
            any(),
            captureAny(),
            conversationId: 'conversation-1',
          ),
        ).captured.cast<MessagePatch>();
        expect(patches, isNotEmpty);
      },
    );
  });

  group('AgentToolExecutionService native tools', () {
    var loadLatestMessageToolCallsUsecase = MockAgentToolCallLoader();
    var messageRepository = MockMessageRepository();
    var resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
    var getAgentIterationDecisionUsecase = MockAgentToolDecisionService();
    var agentCancellationRuntime = AgentCancellationRuntime()
      ..start('conversation-1');
    var usecase = AgentToolExecutionService(
      loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
      messageRepository: messageRepository,
      runResolvedToolUsecase: .new(
        agentCancellationRuntime: agentCancellationRuntime,
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
              onElicitation,
            }) async {
              return 'mcp result';
            },
      ),
      getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
      agentCancellationRuntime: agentCancellationRuntime,
      resolveToolApprovalDecision: resolveToolApprovalDecision,
    );

    setUp(() {
      loadLatestMessageToolCallsUsecase = MockAgentToolCallLoader();
      messageRepository = MockMessageRepository();
      resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
      getAgentIterationDecisionUsecase = MockAgentToolDecisionService();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');

      usecase = AgentToolExecutionService(
        loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
        messageRepository: messageRepository,
        runResolvedToolUsecase: .new(
          agentCancellationRuntime: agentCancellationRuntime,
          mcpToolCaller:
              ({
                required mcpServerId,
                required toolIdentifier,
                required arguments,
                onElicitation,
              }) async {
                return 'mcp result';
              },
        ),
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
        agentCancellationRuntime: agentCancellationRuntime,
        resolveToolApprovalDecision: resolveToolApprovalDecision,
      );
    });

    test(
      'T003: native tool with alwaysAsk permission returns needsConfirmation '
      '(not notConfigured)',
      () async {
        final nativeTool = AgentToolToCall(
          tool: ResolvedTool.native(
            tableId: 'ws-tool-url-id',
            nativeToolType: .url,
          ),
          id: 'native-tool-1',
          argumentsRaw: '{"input": "https://example.com"}',
        );

        when(
          () => loadLatestMessageToolCallsUsecase.call(
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
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'native-tool-1',
            permissionResult: .needsConfirmation,
            permissionTableId: 'url',
          ),
        );

        final message = _runAllowedToolsToolMessage().copyWith(
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'native-tool-1',
                name: 'url',
                argumentsRaw: '{}',
                approvalRequested: false,
              ),
            ],
          ),
        );
        when(() => messageRepository.getMessageById('message-1'))
            .thenAnswer((_) async => message);
        when(
          () => messageRepository.patchMessage(
            'message-1',
            any(),
            conversationId: 'conversation-1',
          ),
        ).thenAnswer((_) async => message);
        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        verify(
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).called(1);
        final patches = verify(
          () => messageRepository.patchMessage(
            any(),
            captureAny(),
            conversationId: 'conversation-1',
          ),
        ).captured.cast<MessagePatch>();
        expect(patches, isNotEmpty);
      },
    );

    test('T004: alwaysAllow native tool executes', () async {
      final nativeTool = AgentToolToCall(
        tool: ResolvedTool.native(
          tableId: 'ws-tool-url-id',
          nativeToolType: .url,
        ),
        id: 'native-tool-1',
        argumentsRaw: '{"input": "https://example.com"}',
      );

      final nativeMessage = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: 'assistant',
        messageType: .text,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
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
        () => loadLatestMessageToolCallsUsecase.call(
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
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'native-tool-1',
          resolvedTool: nativeTool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'native-tool-1',
          permissionResult: .granted,
          permissionTableId: 'url',
        ),
      );
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => nativeMessage);
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => nativeMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.continueIteration);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.continueIteration);
      final updatedToolCalls = _capturedToolCalls(messageRepository);
      expect(updatedToolCalls, isNotNull);
      expect(
        updatedToolCalls
            ?.firstWhere((tc) => tc.id == 'native-tool-1')
            .resultStatus,
        ToolCallResultStatus.success,
      );
    });

    test('T010: persists notConfigured status', () async {
      final nativeTool = AgentToolToCall(
        tool: ResolvedTool.native(
          tableId: 'ws-tool-url-id',
          nativeToolType: .url,
        ),
        id: 'native-tool-1',
        argumentsRaw: '{"input": "https://example.com"}',
      );

      final nativeMessage = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: 'assistant',
        messageType: .text,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
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
        () => loadLatestMessageToolCallsUsecase.call(
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
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'native-tool-1',
          resolvedTool: nativeTool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'native-tool-1',
          permissionResult: .notConfigured,
        ),
      );
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => nativeMessage);
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => nativeMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.done);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.done);
      final updatedToolCalls = _capturedToolCalls(messageRepository);
      expect(updatedToolCalls, isNotNull);
      expect(
        updatedToolCalls
            ?.firstWhere((tc) => tc.id == 'native-tool-1')
            .resultStatus,
        ToolCallResultStatus.notConfigured,
      );
    });

    test('T014: notConfigured response includes tool details', () async {
      final nativeTool = AgentToolToCall(
        tool: ResolvedTool.native(
          tableId: 'ws-tool-url-id',
          nativeToolType: .url,
        ),
        id: 'native-tool-1',
        argumentsRaw: '{"input": "https://example.com"}',
      );

      final nativeMessage = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: 'assistant',
        messageType: .text,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
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
        () => loadLatestMessageToolCallsUsecase.call(
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
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'native-tool-1',
          resolvedTool: nativeTool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'native-tool-1',
          permissionResult: .notConfigured,
        ),
      );
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => nativeMessage);
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => nativeMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.done);

      final _ = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      final update =
          verify(
                () => messageRepository.patchMessage(
                  'message-1',
                  captureAny(),
                  conversationId: 'conversation-1',
                ),
              ).captured.single
              as MessagePatch;
      final tc = update.metadata?.toolCalls.firstWhere(
        (t) => t.id == 'native-tool-1',
      );
      expect(tc?.responseRaw, contains('url'));
      expect(tc?.responseRaw, isNot(contains('null')));
    });

    test(
      'T015: disabledInWorkspace error includes tool name in responseRaw',
      () async {
        final nativeTool = AgentToolToCall(
          tool: ResolvedTool.native(
            tableId: 'ws-tool-url-id',
            nativeToolType: .url,
          ),
          id: 'native-tool-1',
          argumentsRaw: '{"input": "https://example.com"}',
        );

        final nativeMessage = MessageEntity(
          id: 'message-1',
          conversationId: 'conversation-1',
          content: 'assistant',
          messageType: .text,
          isUser: false,
          status: .sent,
          createdAt: .new(2026),
          updatedAt: .new(2026),
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
          () => loadLatestMessageToolCallsUsecase.call(
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
          () => resolveToolApprovalDecision(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolCallId: 'native-tool-1',
            resolvedTool: nativeTool.tool,
          ),
        ).thenAnswer(
          (_) async => const ToolApprovalDecision(
            toolCallId: 'native-tool-1',
            permissionResult: .disabledInWorkspace,
            permissionTableId: 'url',
          ),
        );
        when(() => messageRepository.getMessageById('message-1'))
            .thenAnswer((_) async => nativeMessage);
        when(
          () => messageRepository.patchMessage(
            'message-1',
            any(),
            conversationId: 'conversation-1',
          ),
        ).thenAnswer((_) async => nativeMessage);
        when(
          () => getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.done);

        final _ = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        final update =
            verify(
                  () => messageRepository.patchMessage(
                    'message-1',
                    captureAny(),
                    conversationId: 'conversation-1',
                  ),
                ).captured.single
                as MessagePatch;
        final tc = update.metadata?.toolCalls.firstWhere(
          (t) => t.id == 'native-tool-1',
        );
        expect(tc?.responseRaw, contains('url'));
      },
    );
  });

  group('AgentToolExecutionService cancellation and error paths', () {
    var loadLatestMessageToolCallsUsecase = MockAgentToolCallLoader();
    var messageRepository = MockMessageRepository();
    var resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
    var getAgentIterationDecisionUsecase = MockAgentToolDecisionService();
    var agentCancellationRuntime = AgentCancellationRuntime()
      ..start('conversation-1');
    var usecase = AgentToolExecutionService(
      loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
      messageRepository: messageRepository,
      runResolvedToolUsecase: .new(
        agentCancellationRuntime: agentCancellationRuntime,
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
              onElicitation,
            }) async {
              return 'mcp result';
            },
      ),
      getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
      agentCancellationRuntime: agentCancellationRuntime,
      resolveToolApprovalDecision: resolveToolApprovalDecision,
    );

    setUp(() {
      loadLatestMessageToolCallsUsecase = MockAgentToolCallLoader();
      messageRepository = MockMessageRepository();
      resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
      getAgentIterationDecisionUsecase = MockAgentToolDecisionService();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');

      usecase = AgentToolExecutionService(
        loadLatestMessageToolCallsUsecase: loadLatestMessageToolCallsUsecase,
        messageRepository: messageRepository,
        runResolvedToolUsecase: .new(
          agentCancellationRuntime: agentCancellationRuntime,
          mcpToolCaller:
              ({
                required mcpServerId,
                required toolIdentifier,
                required arguments,
                onElicitation,
              }) async {
                return 'mcp result';
              },
        ),
        getAgentIterationDecisionUsecase: getAgentIterationDecisionUsecase,
        agentCancellationRuntime: agentCancellationRuntime,
        resolveToolApprovalDecision: resolveToolApprovalDecision,
      );
    });

    test('marks previously failed tool calls with executionError', () async {
      final tool = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
        ),
        id: 'tool-1',
        argumentsRaw: '{"input": "1+1"}',
      );

      final failedMessage = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: 'assistant',
        messageType: .text,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
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
        () => loadLatestMessageToolCallsUsecase.call(
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
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => failedMessage);
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-1',
          resolvedTool: tool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-1',
          permissionResult: .granted,
          permissionTableId: 'calculator',
        ),
      );
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => failedMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.continueIteration);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.continueIteration);
      final updatedToolCalls = _capturedToolCalls(messageRepository);
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
    });

    test(
      'returns done when cancellation is requested before processing',
      () async {
        final tool = AgentToolToCall(
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: .calculator,
          ),
          id: 'tool-1',
          argumentsRaw: '{"input": "1+1"}',
        );

        final cancelMessage = MessageEntity(
          id: 'message-1',
          conversationId: 'conversation-1',
          content: 'assistant',
          messageType: .text,
          isUser: false,
          status: .sent,
          createdAt: .new(2026),
          updatedAt: .new(2026),
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
          () => loadLatestMessageToolCallsUsecase.call(
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
        when(() => messageRepository.getMessageById('message-1'))
            .thenAnswer((_) async => cancelMessage);
        when(
          () => messageRepository.patchMessage(
            'message-1',
            any(),
            conversationId: 'conversation-1',
          ),
        ).thenAnswer((_) async => cancelMessage);

        agentCancellationRuntime.requestStop('conversation-1');

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.done);
      },
    );

    test('handles disabledInConversation permission result', () async {
      final tool = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
        ),
        id: 'tool-1',
        argumentsRaw: '{"input": "1+1"}',
      );

      final disabledMessage = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        content: 'assistant',
        messageType: .text,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
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
        () => loadLatestMessageToolCallsUsecase.call(
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
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => disabledMessage);
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-1',
          resolvedTool: tool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-1',
          permissionResult: .disabledInConversation,
          permissionTableId: 'calculator',
        ),
      );
      when(
        () => messageRepository.patchMessage(
          'message-1',
          any(),
          conversationId: 'conversation-1',
        ),
      ).thenAnswer((_) async => disabledMessage);
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.done);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.done);
      final update =
          verify(
                () => messageRepository.patchMessage(
                  'message-1',
                  captureAny(),
                  conversationId: 'conversation-1',
                ),
              ).captured.single
              as MessagePatch;
      final tc = update.metadata?.toolCalls.first;
      expect(tc?.resultStatus, ToolCallResultStatus.disabledInConversation);
      expect(tc?.responseRaw, contains('calculator'));
    });

    test('skips tool when message not found for update', () async {
      final tool = AgentToolToCall(
        tool: ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
        ),
        id: 'tool-1',
        argumentsRaw: '{"input": "1+1"}',
      );

      when(
        () => loadLatestMessageToolCallsUsecase.call(
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
      when(() => messageRepository.getMessageById('message-1'))
          .thenAnswer((_) async => null);
      when(
        () => resolveToolApprovalDecision(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          toolCallId: 'tool-1',
          resolvedTool: tool.tool,
        ),
      ).thenAnswer(
        (_) async => const ToolApprovalDecision(
          toolCallId: 'tool-1',
          permissionResult: .granted,
          permissionTableId: 'calculator',
        ),
      );
      when(() => getAgentIterationDecisionUsecase.call(messageId: 'message-1'))
          .thenAnswer((_) async => AgentIterationDecision.continueIteration);

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.continueIteration);
      final _ = verifyNever(() => messageRepository.patchMessage(any(), any()));
    });
  });
}

List<MessageToolCallEntity>? _capturedToolCalls(
  MockMessageRepository messageRepository,
) {
  final patches = verify(
    () => messageRepository.patchMessage(
      'message-1',
      captureAny(),
      conversationId: 'conversation-1',
    ),
  ).captured.cast<MessagePatch>();
  final byId = <String, MessageToolCallEntity>{};
  for (final patch in patches) {
    for (final toolCall
        in patch.metadata?.toolCalls ?? const <MessageToolCallEntity>[]) {
      final existing = byId[toolCall.id];
      byId[toolCall.id] = toolCall.copyWith(
        resultStatus: toolCall.resultStatus ?? existing?.resultStatus,
        responseRaw: toolCall.responseRaw ?? existing?.responseRaw,
      );
    }
  }

  return byId.values.toList();
}

MessageEntity _runAllowedToolsToolMessage() {
  return MessageEntity(
    id: 'message-1',
    conversationId: 'conversation-1',
    content: 'assistant',
    messageType: .text,
    isUser: false,
    status: .sent,
    createdAt: .new(2026),
    updatedAt: .new(2026),
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
}
