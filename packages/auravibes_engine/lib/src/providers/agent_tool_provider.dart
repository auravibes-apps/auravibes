import 'package:auravibes_engine/src/agent_iteration_context.dart';
import 'package:auravibes_engine/src/agent_iteration_decision.dart';
import 'package:auravibes_engine/src/agent_service.dart';
import 'package:auravibes_engine/src/agent_tool_decision_service.dart';
import 'package:auravibes_engine/src/agent_tool_execution_service.dart';
import 'package:auravibes_engine/src/tool_call_actions.dart';
import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:auravibes_engine/src/tool_resume_service.dart';

abstract interface class AgentToolProvider<TTool extends Object>
    implements
        AgentToolExecutionProvider<TTool>,
        AgentToolCallProvider<TTool>,
        AgentToolDecisionProvider,
        AgentLoopToolProvider,
        ApproveToolCallProvider<TTool>,
        SkipToolCallProvider,
        StopPendingToolCallsProvider,
        AgentToolResumeProvider {}

class AgentToolProviders<TTool extends Object>
    implements AgentToolProvider<TTool> {
  const AgentToolProviders({
    required this.execution,
    required this.calls,
    required this.decisions,
    required this.approvals,
    required this.skips,
    required this.stopPending,
    required this.resume,
  });

  final AgentToolExecutionProvider<TTool> execution;
  final AgentToolCallProvider<TTool> calls;
  final AgentToolDecisionProvider decisions;
  final ApproveToolCallProvider<TTool> approvals;
  final SkipToolCallProvider skips;
  final StopPendingToolCallsProvider stopPending;
  final AgentToolResumeProvider resume;

  @override
  Future<List<AgentToolMessage>> loadMessages(String conversationId) {
    return calls.loadMessages(conversationId);
  }

  @override
  TTool? resolveTool(String toolName) {
    return calls.resolveTool(toolName);
  }

  @override
  Future<LoadLatestMessageToolCallsResult<TTool>> loadLatestToolCalls({
    required String conversationId,
  }) {
    return execution.loadLatestToolCalls(conversationId: conversationId);
  }

  @override
  Future<AgentToolApprovalDecision> resolveToolApprovalDecision({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required TTool resolvedTool,
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
    required TTool tool,
    required Map<String, dynamic> arguments,
  }) {
    return execution.runResolvedTool(
      conversationId: conversationId,
      tool: tool,
      arguments: arguments,
    );
  }

  @override
  Future<AgentIterationDecision> getAgentIterationDecision({
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
    required List<AgentToolResultUpdate> updates,
  }) {
    return execution.updateToolResults(messageId: messageId, updates: updates);
  }

  @override
  String toolIdentifier(TTool tool) {
    return execution.toolIdentifier(tool);
  }

  @override
  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required TTool tool,
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
  Future<List<AgentToolCallState>?> getToolCallStates(String messageId) {
    return decisions.getToolCallStates(messageId);
  }

  @override
  Future<AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
  }) {
    return approvals.loadToolCall(messageId: messageId, toolCallId: toolCallId);
  }

  @override
  Future<void> grantToolForConversation({
    required String conversationId,
    required TTool tool,
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
    required AgentToolResultStatus resultStatus,
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
  Future<void> markToolCallRunning({
    required String messageId,
    required String toolCallId,
  }) {
    return approvals.markToolCallRunning(
      messageId: messageId,
      toolCallId: toolCallId,
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
  Future<AgentToolResumeReference?> getResumeReference(String messageId) {
    return resume.getResumeReference(messageId);
  }

  @override
  Future<AgentIterationDecision> runAllowedTools({
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
    required AgentIterationContext context,
  }) {
    return resume.continueAgent(
      conversationId: conversationId,
      context: context,
    );
  }
}
