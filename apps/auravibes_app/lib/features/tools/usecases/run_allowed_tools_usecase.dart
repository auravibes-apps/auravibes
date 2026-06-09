// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/tools/usecases/get_agent_iteration_decision_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_latest_message_tool_calls_result.dart';
import 'package:auravibes_app/features/tools/usecases/run_resolved_tool_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/utils/encode.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _logger = Logger('run_allowed_tools_usecase');

class RunAllowedToolsUsecase {
  const RunAllowedToolsUsecase({
    required this.loadLatestMessageToolCallsUsecase,
    required this.messageRepository,
    required this.resolveToolApprovalDecision,
    required this.runResolvedToolUsecase,
    required this.getAgentIterationDecisionUsecase,
    required this.agentCancellationRuntime,
  });

  final LoadLatestMessageToolCallsUsecase loadLatestMessageToolCallsUsecase;
  final MessageRepository messageRepository;
  final ResolveToolApprovalDecisionUsecase resolveToolApprovalDecision;
  final RunResolvedToolUsecase runResolvedToolUsecase;
  final GetAgentIterationDecisionUsecase getAgentIterationDecisionUsecase;
  final AgentCancellationRuntime agentCancellationRuntime;

  Future<AgentIterationDecision> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final latestToolCalls = await loadLatestMessageToolCallsUsecase.call(
      conversationId: conversationId,
    );
    final updates = <_ToolResultUpdate>[];
    var hasPendingTools = false;

    if (!latestToolCalls.hasToolCalls) {
      return AgentIterationDecision.done;
    }

    if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
      await _stopPendingTools(messageId: latestToolCalls.messageId);

      return AgentIterationDecision.done;
    }

    if (latestToolCalls.notFoundToolCallIds.isNotEmpty) {
      updates.addAll(
        latestToolCalls.notFoundToolCallIds.map(
          (toolCallId) => _ToolResultUpdate(
            toolCallId: toolCallId,
            resultStatus: ToolCallResultStatus.toolNotFound,
            responseRaw: 'Tool not found for tool call: $toolCallId.',
          ),
        ),
      );
    }

    if (latestToolCalls.previouslyFailedToolCallIds.isNotEmpty) {
      updates.addAll(
        latestToolCalls.previouslyFailedToolCallIds.map(
          (toolCallId) => _ToolResultUpdate(
            toolCallId: toolCallId,
            resultStatus: ToolCallResultStatus.executionError,
            responseRaw:
                'Tool execution was already attempted and failed. '
                'Not retrying.',
          ),
        ),
      );
    }

    final grantedTools = <ToolToCall>[];
    for (final toolToCall in latestToolCalls.toolsToRun) {
      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        updates.add(
          _ToolResultUpdate(
            toolCallId: toolToCall.id,
            resultStatus: ToolCallResultStatus.stoppedByUser,
          ),
        );
        continue;
      }

      final decision = await resolveToolApprovalDecision(
        conversationId: conversationId,
        workspaceId: workspaceId,
        toolCallId: toolToCall.id,
        resolvedTool: toolToCall.tool,
      );

      switch (decision.permissionResult) {
        case ToolPermissionResult.granted:
          grantedTools.add(toolToCall);
        case ToolPermissionResult.needsConfirmation:
          hasPendingTools = true;
        case ToolPermissionResult.disabledInConversation:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInConversation,
              responseRaw:
                  'Tool "${toolToCall.tool.toolIdentifier}" is disabled for '
                  'this conversation.',
            ),
          );
        case ToolPermissionResult.disabledInWorkspace:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInWorkspace,
              responseRaw:
                  'Tool "${toolToCall.tool.toolIdentifier}" is disabled in '
                  'workspace settings.',
            ),
          );
        case ToolPermissionResult.notConfigured:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.notConfigured,
              responseRaw:
                  'Tool "${toolToCall.tool.toolIdentifier}" is not configured. '
                  'Enable it in workspace settings to use it.',
            ),
          );
      }
    }

    if (grantedTools.isNotEmpty) {
      final executionResults = await Future.wait(
        grantedTools.map(
          (tool) => _executeSafely(
            conversationId: conversationId,
            toolToCall: tool,
          ),
        ),
      );
      updates.addAll(executionResults);
    }

    if (updates.isNotEmpty) {
      await _updateToolResults(
        messageId: latestToolCalls.messageId,
        updates: updates,
      );
    }

    if (hasPendingTools) {
      return AgentIterationDecision.waitForToolApproval;
    }

    if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
      return AgentIterationDecision.done;
    }

    return getAgentIterationDecisionUsecase.call(
      messageId: latestToolCalls.messageId,
    );
  }

  Future<_ToolExecutionResult> _executeTool({
    required String conversationId,
    required ToolToCall toolToCall,
  }) async {
    final arguments =
        safeJsonDecode(toolToCall.argumentsRaw) ?? const <String, dynamic>{};

    try {
      final result = await runResolvedToolUsecase(
        conversationId: conversationId,
        tool: toolToCall.tool,
        arguments: arguments,
      );
      if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
        return const _ToolExecutionResult(
          resultStatus: ToolCallResultStatus.stoppedByUser,
        );
      }
      if (result == null) {
        return const _ToolExecutionResult(
          resultStatus: ToolCallResultStatus.toolNotFound,
        );
      }

      return _ToolExecutionResult(
        resultStatus: ToolCallResultStatus.success,
        responseRaw: result.toString(),
      );
    } on FormatException catch (error, stackTrace) {
      _logToolExecutionError(
        conversationId: conversationId,
        toolCallId: toolToCall.id,
        tool: toolToCall.tool,
        error: error,
        stackTrace: stackTrace,
      );

      return _ToolExecutionResult(
        resultStatus: ToolCallResultStatus.executionError,
        responseRaw: 'Tool execution failed: ${error.message}',
      );
    } on Object catch (error, stackTrace) {
      _logToolExecutionError(
        conversationId: conversationId,
        toolCallId: toolToCall.id,
        tool: toolToCall.tool,
        error: error,
        stackTrace: stackTrace,
      );

      return const _ToolExecutionResult(
        resultStatus: ToolCallResultStatus.executionError,
      );
    }
  }

  Future<_ToolResultUpdate> _executeSafely({
    required String conversationId,
    required ToolToCall toolToCall,
  }) async {
    try {
      final result = await _executeTool(
        conversationId: conversationId,
        toolToCall: toolToCall,
      );

      return _ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: result.resultStatus,
        responseRaw: result.responseRaw,
      );
    } on Object catch (error, stackTrace) {
      _logToolExecutionError(
        conversationId: conversationId,
        toolCallId: toolToCall.id,
        tool: toolToCall.tool,
        error: error,
        stackTrace: stackTrace,
      );

      return _ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus:
            agentCancellationRuntime.isCancellationRequested(
              conversationId,
            )
            ? ToolCallResultStatus.stoppedByUser
            : ToolCallResultStatus.executionError,
      );
    }
  }

  Future<void> _stopPendingTools({required String messageId}) async {
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

  Future<void> _updateToolResults({
    required String messageId,
    required List<_ToolResultUpdate> updates,
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
        resultStatus: update.resultStatus,
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

final runAllowedToolsUsecaseProvider = Provider<RunAllowedToolsUsecase>((ref) {
  return RunAllowedToolsUsecase(
    loadLatestMessageToolCallsUsecase: ref.watch(
      loadLatestMessageToolCallsUsecaseProvider,
    ),
    messageRepository: ref.watch(messageRepositoryProvider),
    resolveToolApprovalDecision: ref.watch(
      resolveToolApprovalDecisionUsecaseProvider,
    ),
    runResolvedToolUsecase: ref.watch(runResolvedToolUsecaseProvider),
    getAgentIterationDecisionUsecase: ref.watch(
      getAgentIterationDecisionUsecaseProvider,
    ),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
  );
});

class _ToolResultUpdate {
  const _ToolResultUpdate({
    required this.toolCallId,
    required this.resultStatus,
    this.responseRaw,
  });

  final String toolCallId;
  final ToolCallResultStatus resultStatus;
  final String? responseRaw;
}

class _ToolExecutionResult {
  const _ToolExecutionResult({required this.resultStatus, this.responseRaw});

  final ToolCallResultStatus resultStatus;
  final String? responseRaw;
}
