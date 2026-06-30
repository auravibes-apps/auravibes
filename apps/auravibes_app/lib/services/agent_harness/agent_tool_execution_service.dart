// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_agent/auravibes_agent_internal.dart'
    as agent_execution;
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart'
    hide ToolToCall;
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_call_loader.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_decision_service.dart';
import 'package:auravibes_app/services/agent_harness/resolved_tool_service.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _logger = Logger('agent_tool_execution_service');

class AgentToolExecutionService
    extends agent_execution.AgentToolExecutionService<ResolvedTool> {
  AgentToolExecutionService({
    required AgentToolCallLoader loadLatestMessageToolCallsUsecase,
    required MessageRepository messageRepository,
    required ResolveToolApprovalDecisionUsecase resolveToolApprovalDecision,
    required ResolvedToolService runResolvedToolUsecase,
    required AgentToolDecisionService getAgentIterationDecisionUsecase,
    required agent.AgentCancellationRuntime agentCancellationRuntime,
  }) : super(
         provider: AppAllowedToolsDataProvider(
           messageRepository: messageRepository,
           loadLatestMessageToolCallsService: loadLatestMessageToolCallsUsecase,
           resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
           resolvedToolService: runResolvedToolUsecase,
           toolDecisionService: getAgentIterationDecisionUsecase,
           agentCancellationRuntime: agentCancellationRuntime,
         ),
       );
}

class AppAllowedToolsDataProvider
    implements agent.AgentToolExecutionProvider<ResolvedTool> {
  const AppAllowedToolsDataProvider({
    required this.messageRepository,
    required this.loadLatestMessageToolCallsService,
    required this.resolveToolApprovalDecisionUsecase,
    required this.resolvedToolService,
    required this.toolDecisionService,
    required this.agentCancellationRuntime,
  });

  final MessageRepository messageRepository;
  final AgentToolCallLoader loadLatestMessageToolCallsService;
  final ResolveToolApprovalDecisionUsecase resolveToolApprovalDecisionUsecase;
  final ResolvedToolService resolvedToolService;
  final AgentToolDecisionService toolDecisionService;
  final agent.AgentCancellationRuntime agentCancellationRuntime;

  @override
  Future<agent.LoadLatestMessageToolCallsResult<ResolvedTool>>
  loadLatestToolCalls({required String conversationId}) {
    return loadLatestMessageToolCallsService.call(
      conversationId: conversationId,
    );
  }

  @override
  Future<agent.AgentToolApprovalDecision> resolveToolApprovalDecision({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
  }) async {
    final decision = await resolveToolApprovalDecisionUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolCallId: toolCallId,
      resolvedTool: resolvedTool,
    );

    return agent.AgentToolApprovalDecision(
      permissionResult: _toAgentPermissionResult(
        decision.permissionResult,
      ),
    );
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) {
    return resolvedToolService(
      conversationId: conversationId,
      tool: tool,
      arguments: arguments,
    );
  }

  @override
  Future<agent.AgentIterationDecision> getAgentIterationDecision({
    required String messageId,
  }) {
    return toolDecisionService.call(messageId: messageId);
  }

  @override
  bool isCancellationRequested(String conversationId) {
    return agentCancellationRuntime.isCancellationRequested(conversationId);
  }

  @override
  String toolIdentifier(ResolvedTool tool) {
    return tool.toolIdentifier;
  }

  @override
  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Object error,
    required StackTrace stackTrace,
  }) {
    _logToolExecutionError(
      conversationId: conversationId,
      toolCallId: toolCallId,
      tool: tool,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> stopPendingTools({required String messageId}) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    var didUpdate = false;
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (!toolCall.isPending) return toolCall;

      didUpdate = true;

      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
    }).toList();
    if (!didUpdate) return;

    final _ = await messageRepository.patchMessage(
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }

  @override
  Future<void> updateToolResults({
    required String messageId,
    required List<agent.AgentToolResultUpdate> updates,
  }) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      final update = updates
          .where((candidate) => candidate.toolCallId == toolCall.id)
          .firstOrNull;
      if (update == null) return toolCall;

      return toolCall.copyWith(
        resultStatus: _toAppResultStatus(update.resultStatus),
        responseRaw: update.responseRaw,
      );
    }).toList();

    final _ = await messageRepository.patchMessage(
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}

agent.AgentToolPermissionResult _toAgentPermissionResult(
  ToolPermissionResult result,
) {
  return switch (result) {
    ToolPermissionResult.granted => agent.AgentToolPermissionResult.granted,
    ToolPermissionResult.needsConfirmation =>
      agent.AgentToolPermissionResult.needsConfirmation,
    ToolPermissionResult.disabledInConversation =>
      agent.AgentToolPermissionResult.disabledInConversation,
    ToolPermissionResult.disabledInWorkspace =>
      agent.AgentToolPermissionResult.disabledInWorkspace,
    ToolPermissionResult.notConfigured =>
      agent.AgentToolPermissionResult.notConfigured,
  };
}

ToolCallResultStatus _toAppResultStatus(agent.AgentToolResultStatus status) {
  return switch (status) {
    agent.AgentToolResultStatus.success => ToolCallResultStatus.success,
    agent.AgentToolResultStatus.toolNotFound =>
      ToolCallResultStatus.toolNotFound,
    agent.AgentToolResultStatus.executionError =>
      ToolCallResultStatus.executionError,
    agent.AgentToolResultStatus.disabledInConversation =>
      ToolCallResultStatus.disabledInConversation,
    agent.AgentToolResultStatus.disabledInWorkspace =>
      ToolCallResultStatus.disabledInWorkspace,
    agent.AgentToolResultStatus.notConfigured =>
      ToolCallResultStatus.notConfigured,
    agent.AgentToolResultStatus.stoppedByUser =>
      ToolCallResultStatus.stoppedByUser,
  };
}

void _logToolExecutionError({
  required String conversationId,
  required String toolCallId,
  required ResolvedTool tool,
  required Object error,
  required StackTrace stackTrace,
}) {
  _logger.severe(
    'Tool execution failed '
    'conversationId=$conversationId '
    'toolCallId=$toolCallId '
    'toolType=${tool.type.name} '
    'toolIdentifier=${tool.toolIdentifier}',
    error,
    stackTrace,
  );
}

final agentToolExecutionServiceProvider = Provider<AgentToolExecutionService>((
  ref,
) {
  return AgentToolExecutionService(
    loadLatestMessageToolCallsUsecase: ref.watch(
      agentToolCallLoaderProvider,
    ),
    messageRepository: ref.watch(messageRepositoryProvider),
    resolveToolApprovalDecision: ref.watch(
      resolveToolApprovalDecisionUsecaseProvider,
    ),
    runResolvedToolUsecase: ref.watch(resolvedToolServiceProvider),
    getAgentIterationDecisionUsecase: ref.watch(
      agentToolDecisionServiceProvider,
    ),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
  );
});
