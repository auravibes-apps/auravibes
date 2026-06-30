import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/agent_harness/agent_service.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_call_loader.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_decision_service.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_execution_service.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_resume_service.dart';
import 'package:auravibes_app/services/agent_harness/approve_tool_call_service.dart';
import 'package:auravibes_app/services/agent_harness/resolved_tool_service.dart';
import 'package:auravibes_app/services/agent_harness/skip_tool_call_service.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:riverpod/riverpod.dart';

final auraAgentServiceProvider = Provider<agent.AuraAgentService<ResolvedTool>>(
  (ref) {
    final agentService = ref.watch(agentServiceProvider);
    final agentToolResumeService = ref.watch(agentToolResumeServiceProvider);
    final toolCallActions = AppToolCallActionsDataProvider(
      messageRepository: ref.watch(messageRepositoryProvider),
      agentToolResumeService: agentToolResumeService,
    );

    return agent.AuraAgentService<ResolvedTool>(
      data: agentService.provider as agent.AgentDataProvider,
      tools: _AppAgentToolProvider(
        execution: ref.watch(agentToolExecutionServiceProvider).provider,
        calls: ref.watch(agentToolCallLoaderProvider).provider,
        decisions: ref.watch(agentToolDecisionServiceProvider).provider,
        approvals: AppApproveToolCallDataProvider(
          messageRepository: ref.watch(messageRepositoryProvider),
          conversationRepository: ref.watch(conversationRepositoryProvider),
          conversationToolsRepository: ref.watch(
            conversationToolsRepositoryProvider,
          ),
          resolveToolApprovalDecisionUsecase: ref.watch(
            resolveToolApprovalDecisionUsecaseProvider,
          ),
          toolResolverService: const ToolResolverService(),
          agentToolResumeService: agentToolResumeService,
          runResolvedToolUsecase: ref.watch(resolvedToolServiceProvider),
          agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
        ),
        skips: toolCallActions,
        stopPending: toolCallActions,
        resume: agentToolResumeService.provider,
      ),
      runtime: _AppAgentRuntimeProvider(
        sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
        cancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
        retryRuntime: ref.watch(conversationRateLimitRetryRuntimeProvider),
      ),
    );
  },
);

class _AppAgentRuntimeProvider implements agent.AgentRuntimeProvider {
  const _AppAgentRuntimeProvider({
    required this.sendQueueRuntime,
    required this.cancellationRuntime,
    required this._retryRuntime,
  });

  @override
  final ConversationSendQueueRuntime sendQueueRuntime;

  @override
  final agent.AgentCancellationRuntime cancellationRuntime;

  final ConversationRateLimitRetryRuntime _retryRuntime;

  @override
  agent.AgentRateLimitRetryRuntime get rateLimitRetryRuntime {
    return agent.AgentRateLimitRetryRuntime(
      start: _retryRuntime.start,
      clear: _retryRuntime.clear,
    );
  }
}

class _AppAgentToolProvider implements agent.AgentToolProvider<ResolvedTool> {
  const _AppAgentToolProvider({
    required this.execution,
    required this.calls,
    required this.decisions,
    required this.approvals,
    required this.skips,
    required this.stopPending,
    required this.resume,
  });

  final agent.AgentToolExecutionProvider<ResolvedTool> execution;
  final agent.AgentToolCallProvider<ResolvedTool> calls;
  final agent.AgentToolDecisionProvider decisions;
  final agent.ApproveToolCallProvider<ResolvedTool> approvals;
  final agent.SkipToolCallProvider skips;
  final agent.StopPendingToolCallsProvider stopPending;
  final agent.AgentToolResumeProvider resume;

  @override
  Future<List<agent.AgentToolMessage>> loadMessages(String conversationId) {
    return calls.loadMessages(conversationId);
  }

  @override
  ResolvedTool? resolveTool(String toolName) {
    return calls.resolveTool(toolName);
  }

  @override
  Future<agent.LoadLatestMessageToolCallsResult<ResolvedTool>>
  loadLatestToolCalls({required String conversationId}) {
    return execution.loadLatestToolCalls(conversationId: conversationId);
  }

  @override
  Future<agent.AgentToolApprovalDecision> resolveToolApprovalDecision({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
  }) {
    return execution.resolveToolApprovalDecision(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolCallId: toolCallId,
      resolvedTool: resolvedTool,
    );
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) {
    return execution.runResolvedTool(
      conversationId: conversationId,
      tool: tool,
      arguments: arguments,
    );
  }

  @override
  Future<agent.AgentIterationDecision> getAgentIterationDecision({
    required String messageId,
  }) {
    return execution.getAgentIterationDecision(messageId: messageId);
  }

  @override
  bool isCancellationRequested(String conversationId) {
    return execution.isCancellationRequested(conversationId);
  }

  @override
  Future<void> stopPendingTools({required String messageId}) {
    return execution.stopPendingTools(messageId: messageId);
  }

  @override
  Future<void> updateToolResults({
    required String messageId,
    required List<agent.AgentToolResultUpdate> updates,
  }) {
    return execution.updateToolResults(messageId: messageId, updates: updates);
  }

  @override
  String toolIdentifier(ResolvedTool tool) {
    return execution.toolIdentifier(tool);
  }

  @override
  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Object error,
    required StackTrace stackTrace,
  }) {
    execution.logToolExecutionError(
      conversationId: conversationId,
      toolCallId: toolCallId,
      tool: tool,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<List<agent.AgentToolCallState>?> getToolCallStates(
    String messageId,
  ) {
    return decisions.getToolCallStates(messageId);
  }

  @override
  Future<agent.AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
  }) {
    return approvals.loadToolCall(messageId: messageId, toolCallId: toolCallId);
  }

  @override
  Future<void> grantToolForConversation({
    required String conversationId,
    required ResolvedTool tool,
  }) {
    return approvals.grantToolForConversation(
      conversationId: conversationId,
      tool: tool,
    );
  }

  @override
  Future<void> updateToolCallResult({
    required String messageId,
    required String toolCallId,
    required agent.AgentToolResultStatus resultStatus,
    String? responseRaw,
  }) {
    return approvals.updateToolCallResult(
      messageId: messageId,
      toolCallId: toolCallId,
      resultStatus: resultStatus,
      responseRaw: responseRaw,
    );
  }

  @override
  Future<void> resumeConversationIfReady({required String messageId}) {
    return approvals.resumeConversationIfReady(messageId: messageId);
  }

  @override
  Future<bool> skipToolCall({
    required String messageId,
    required String toolCallId,
  }) {
    return skips.skipToolCall(messageId: messageId, toolCallId: toolCallId);
  }

  @override
  Future<void> stopPendingToolCalls({required String messageId}) {
    return stopPending.stopPendingToolCalls(messageId: messageId);
  }

  @override
  Future<agent.AgentToolResumeReference?> getResumeReference(
    String messageId,
  ) {
    return resume.getResumeReference(messageId);
  }

  @override
  Future<agent.AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) {
    return resume.runAllowedTools(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  @override
  Future<void> continueAgent({
    required String conversationId,
    required agent.AgentIterationContext context,
  }) {
    return resume.continueAgent(
      conversationId: conversationId,
      context: context,
    );
  }
}
