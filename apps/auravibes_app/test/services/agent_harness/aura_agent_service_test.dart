import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/services/agent_harness/aura_agent_service.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';

class _MockToolProviders extends Mock
    implements
        agent.AgentToolExecutionProvider<ResolvedTool>,
        agent.AgentToolCallProvider<ResolvedTool>,
        agent.AgentToolDecisionProvider,
        agent.ApproveToolCallProvider<ResolvedTool>,
        agent.SkipToolCallProvider,
        agent.StopPendingToolCallsProvider,
        agent.AgentToolResumeProvider {}

void main() {
  setUpAll(registerTestFallbackValues);

  test('AppAgentToolProvider forwards all tool calls', () async {
    final delegates = _MockToolProviders();
    final tool = ResolvedTool.builtIn(
      tableId: 'calculator',
      toolIdentifier: 'calculator',
      tooltype: UserToolType.calculator,
    );
    final provider = AppAgentToolProvider(
      execution: delegates,
      calls: delegates,
      decisions: delegates,
      approvals: delegates,
      skips: delegates,
      stopPending: delegates,
      resume: delegates,
    );

    when(
      () => delegates.loadMessages('conversation-1'),
    ).thenAnswer((_) async => const []);
    when(() => delegates.resolveTool('calculator')).thenReturn(tool);
    when(
      () => delegates.loadLatestToolCalls(conversationId: 'conversation-1'),
    ).thenAnswer(
      (_) async => const agent.LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: false,
        toolsToRun: [],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
      ),
    );
    when(
      () => delegates.resolveToolApprovalDecision(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolCallId: 'tool-1',
        resolvedTool: tool,
      ),
    ).thenAnswer(
      (_) async => const agent.AgentToolApprovalDecision(
        permissionResult: agent.AgentToolPermissionResult.granted,
      ),
    );
    when(
      () => delegates.runResolvedTool(
        conversationId: 'conversation-1',
        tool: tool,
        arguments: const {},
      ),
    ).thenAnswer((_) async => 'result');
    when(
      () => delegates.getAgentIterationDecision(messageId: 'message-1'),
    ).thenAnswer((_) async => agent.AgentIterationDecision.done);
    when(
      () => delegates.isCancellationRequested('conversation-1'),
    ).thenReturn(true);
    when(
      () => delegates.stopPendingTools(messageId: 'message-1'),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => delegates.updateToolResults(
        messageId: 'message-1',
        updates: const [],
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(() => delegates.toolIdentifier(tool)).thenReturn('calculator');
    when(
      () => delegates.getToolCallStates('message-1'),
    ).thenAnswer((_) async => const [agent.AgentToolCallState.pending]);
    when(
      () => delegates.loadToolCall(
        messageId: 'message-1',
        toolCallId: 'tool-1',
      ),
    ).thenAnswer(
      (_) async => const agent.AgentApprovableToolCall(
        conversationId: 'conversation-1',
        name: 'calculator',
        argumentsRaw: '{}',
      ),
    );
    when(
      () => delegates.grantToolForConversation(
        conversationId: 'conversation-1',
        tool: tool,
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => delegates.updateToolCallResult(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        resultStatus: agent.AgentToolResultStatus.success,
        responseRaw: 'ok',
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => delegates.resumeConversationIfReady(messageId: 'message-1'),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => delegates.skipToolCall(
        messageId: 'message-1',
        toolCallId: 'tool-1',
      ),
    ).thenAnswer((_) async => true);
    when(
      () => delegates.stopPendingToolCalls(messageId: 'message-1'),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => delegates.getResumeReference('message-1'),
    ).thenAnswer(
      (_) async => const agent.AgentToolResumeReference(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      ),
    );
    when(
      () => delegates.runAllowedTools(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      ),
    ).thenAnswer((_) async => agent.AgentIterationDecision.done);
    when(
      () => delegates.continueAgent(
        conversationId: 'conversation-1',
        context: const agent.AgentIterationContext(
          origin: agent.AgentIterationOrigin.toolResume,
        ),
      ),
    ).thenAnswer((_) => Future<void>.value());

    expect(await provider.loadMessages('conversation-1'), isEmpty);
    expect(provider.resolveTool('calculator'), tool);
    expect(
      await provider.loadLatestToolCalls(conversationId: 'conversation-1'),
      isA<agent.LoadLatestMessageToolCallsResult<ResolvedTool>>(),
    );
    expect(
      await provider.resolveToolApprovalDecision(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        toolCallId: 'tool-1',
        resolvedTool: tool,
      ),
      isA<agent.AgentToolApprovalDecision>(),
    );
    expect(
      await provider.runResolvedTool(
        conversationId: 'conversation-1',
        tool: tool,
        arguments: const {},
      ),
      'result',
    );
    expect(
      await provider.getAgentIterationDecision(messageId: 'message-1'),
      agent.AgentIterationDecision.done,
    );
    expect(provider.isCancellationRequested('conversation-1'), isTrue);
    await provider.stopPendingTools(messageId: 'message-1');
    await provider.updateToolResults(
      messageId: 'message-1',
      updates: const [],
    );
    expect(provider.toolIdentifier(tool), 'calculator');
    provider.logToolExecutionError(
      conversationId: 'conversation-1',
      toolCallId: 'tool-1',
      tool: tool,
      error: StateError('bad'),
      stackTrace: StackTrace.current,
    );
    expect(
      await provider.getToolCallStates('message-1'),
      const [agent.AgentToolCallState.pending],
    );
    expect(
      await provider.loadToolCall(
        messageId: 'message-1',
        toolCallId: 'tool-1',
      ),
      isA<agent.AgentApprovableToolCall>(),
    );
    await provider.grantToolForConversation(
      conversationId: 'conversation-1',
      tool: tool,
    );
    await provider.updateToolCallResult(
      messageId: 'message-1',
      toolCallId: 'tool-1',
      resultStatus: agent.AgentToolResultStatus.success,
      responseRaw: 'ok',
    );
    await provider.resumeConversationIfReady(messageId: 'message-1');
    expect(
      await provider.skipToolCall(
        messageId: 'message-1',
        toolCallId: 'tool-1',
      ),
      isTrue,
    );
    await provider.stopPendingToolCalls(messageId: 'message-1');
    expect(
      await provider.getResumeReference('message-1'),
      isA<agent.AgentToolResumeReference>(),
    );
    expect(
      await provider.runAllowedTools(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      ),
      agent.AgentIterationDecision.done,
    );
    await provider.continueAgent(
      conversationId: 'conversation-1',
      context: const agent.AgentIterationContext(
        origin: agent.AgentIterationOrigin.toolResume,
      ),
    );

    verify(
      () => delegates.logToolExecutionError(
        conversationId: 'conversation-1',
        toolCallId: 'tool-1',
        tool: tool,
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).called(1);
  });
}
