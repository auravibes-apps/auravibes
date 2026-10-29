import 'dart:async';

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/sanitize_workspace_tool_result.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_call_loader.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_decision_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/persist_tool_call_results_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _logger = Logger('agent_tool_execution_service');

typedef _ToolApprovalRequest = ({
  ResolveToolApprovalDecisionUsecase? resolver,
  ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolverForWorkspace,
  String conversationId,
  String workspaceId,
  String toolCallId,
  ResolvedTool resolvedTool,
  String? argumentsRaw,
});

typedef _ToolExecutionErrorRequest = ({
  String conversationId,
  String toolCallId,
  ResolvedTool tool,
  Object error,
  StackTrace stackTrace,
  String? failurePhase,
});

typedef _AgentToolApprovalRequest =
    agent.AgentToolApprovalRequest<ResolvedTool>;

typedef _AgentToolExecutionErrorRequest =
    agent.AgentToolExecutionErrorRequest<ResolvedTool>;

typedef _ToolResultsRequest = ({
  String conversationId,
  String messageId,
  List<agent.AgentToolResultUpdate> updates,
  Map<String, Map<String, Object?>> appDataByToolCallId,
});

typedef _PersistToolResultsRequest = ({
  MessageRepository messageRepository,
  PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
  _ToolResultsRequest request,
  MessageMetadataEntity metadata,
  List<MessageToolCallEntity> toolCalls,
});

typedef _StoppedToolCallsRequest = ({
  MessageRepository messageRepository,
  String messageId,
  MessageMetadataEntity metadata,
  List<MessageToolCallEntity> updatedToolCalls,
  String conversationId,
  MessageStatus status,
});

class AgentToolExecutionService({
  required AgentToolCallLoader loadLatestMessageToolCallsUsecase,
  required MessageRepository messageRepository,
  required ResolvedToolService runResolvedToolUsecase,
  required AgentToolDecisionService getAgentIterationDecisionUsecase,
  required AgentCancellationRuntime agentCancellationRuntime,
  ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecision,
  ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionForWorkspace,
  PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
  super.outputPolicyForTool,
}) extends agent.AgentToolExecutionRunner<ResolvedTool> {
  this
    : super(
        provider: AppAllowedToolsDataProvider(
          messageRepository: messageRepository,
          loadLatestMessageToolCallsService: loadLatestMessageToolCallsUsecase,
          resolvedToolService: runResolvedToolUsecase,
          toolDecisionService: getAgentIterationDecisionUsecase,
          agentCancellationRuntime: agentCancellationRuntime,
          resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
          resolveToolApprovalDecisionUsecaseForWorkspace:
              resolveToolApprovalDecisionForWorkspace,
          persistToolCallResultsUsecase: persistToolCallResultsUsecase,
        ),
      );
}

class const AppAllowedToolsDataProvider({
  required final MessageRepository messageRepository,
  required final AgentToolCallLoader loadLatestMessageToolCallsService,
  required final ResolvedToolService resolvedToolService,
  required final AgentToolDecisionService toolDecisionService,
  required final AgentCancellationRuntime agentCancellationRuntime,
  final ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecisionUsecase,
  final ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionUsecaseForWorkspace,
  final PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
}) implements agent.AgentToolExecutionProvider<ResolvedTool> {
  @override
  Future<agent.AgentToolApprovalDecision> resolveToolApprovalDecision(
    _AgentToolApprovalRequest request,
  ) => _resolveToolApprovalDecision((
    resolver: resolveToolApprovalDecisionUsecase,
    resolverForWorkspace: resolveToolApprovalDecisionUsecaseForWorkspace,
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    toolCallId: request.toolCallId,
    resolvedTool: request.resolvedTool,
    argumentsRaw: request.argumentsRaw,
  ));

  @override
  void logToolExecutionError(_AgentToolExecutionErrorRequest request) =>
      _logToolExecutionError(request);

  @override
  Future<agent.LoadLatestMessageToolCallsResult<ResolvedTool>>
  loadLatestToolCalls({required String conversationId}) {
    return loadLatestMessageToolCallsService.call(
      conversationId: conversationId,
    );
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) => resolvedToolService.call(
    conversationId: conversationId,
    toolCallId: toolCallId,
    tool: tool,
    arguments: arguments,
  );

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
  Future<void> stopPendingTools({
    required String messageId,
    required String conversationId,
  }) async {
    await _stopPendingTools(
      messageRepository,
      messageId,
      conversationId: conversationId,
    );
  }

  @override
  Future<void> updateToolResults({
    required String conversationId,
    required String messageId,
    required List<agent.AgentToolResultUpdate> updates,
  }) async {
    final appDataByToolCallId = _takeSuccessfulAppResults(
      resolvedToolService,
      conversationId,
      updates,
    );
    await _updateToolResults(messageRepository, persistToolCallResultsUsecase, (
      conversationId: conversationId,
      messageId: messageId,
      updates: updates,
      appDataByToolCallId: appDataByToolCallId,
    ));
  }
}

Map<String, Map<String, Object?>> _takeSuccessfulAppResults(
  ResolvedToolService resolvedToolService,
  String conversationId,
  List<agent.AgentToolResultUpdate> updates,
) {
  final appDataByToolCallId = <String, Map<String, Object?>>{};
  for (final update in updates) {
    final appData = resolvedToolService.takeMcpAppResultData(
      conversationId: conversationId,
      toolCallId: update.toolCallId,
    );
    if (appData == null || !_hasSuccessfulAppResult(update)) continue;
    appDataByToolCallId[update.toolCallId] = appData;
  }

  return appDataByToolCallId;
}

bool _hasSuccessfulAppResult(agent.AgentToolResultUpdate update) =>
    update.resultStatus == .success;

Future<agent.AgentToolApprovalDecision> _resolveToolApprovalDecision(
  _ToolApprovalRequest request,
) async {
  final resolver = _approvalResolver(request);
  if (resolver == null) {
    throw StateError('No tool approval resolver is configured');
  }

  final decision = await _resolvePermission(
    resolver,
    request,
    request.resolvedTool,
  );

  return _toApprovalDecision(decision);
}

ResolveToolApprovalDecisionUsecase? _approvalResolver(
  _ToolApprovalRequest request,
) =>
    request.resolverForWorkspace?.call(request.workspaceId) ?? request.resolver;

Future<ToolApprovalDecision> _resolvePermission(
  ResolveToolApprovalDecisionUsecase resolver,
  _ToolApprovalRequest request,
  ResolvedTool approvalTool,
) {
  if (approvalTool.isConnectorCommand || approvalTool.isWorkspaceCommand) {
    return resolver.callForRequest((
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      toolCallId: request.toolCallId,
      resolvedTool: approvalTool,
      argumentsRaw: request.argumentsRaw,
    ));
  }

  return resolver.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    toolCallId: request.toolCallId,
    resolvedTool: approvalTool,
  );
}

agent.AgentToolApprovalDecision _toApprovalDecision(
  ToolApprovalDecision decision,
) => agent.AgentToolApprovalDecision(
  permissionResult: AgentToolStatusMapper.toPermissionResult(
    decision.permissionResult,
  ),
);

Future<void> _stopPendingTools(
  MessageRepository messageRepository,
  String messageId, {
  required String conversationId,
}) async {
  final message = await messageRepository.getMessageById(messageId);
  if (message == null) return;

  final metadata = message.metadata ?? const MessageMetadataEntity();
  final updated = _stoppedPendingToolCalls(metadata.toolCalls);
  if (updated == null) return;

  await _persistStoppedToolCalls((
    messageRepository: messageRepository,
    messageId: messageId,
    metadata: metadata,
    updatedToolCalls: updated,
    conversationId: conversationId,
    status: .sent,
  ));
}

List<MessageToolCallEntity>? _stoppedPendingToolCalls(
  List<MessageToolCallEntity> toolCalls,
) {
  if (!toolCalls.any((toolCall) => toolCall.isPending)) return null;

  return [
    for (final toolCall in toolCalls)
      if (toolCall.isPending)
        toolCall.copyWith(resultStatus: ToolCallResultStatus.stoppedByUser)
      else
        toolCall,
  ];
}

Future<void> _persistStoppedToolCalls(_StoppedToolCallsRequest request) async {
  final _ = await request.messageRepository.patchMessage(
    request.messageId,
    .new(
      metadata: request.metadata.copyWith(toolCalls: request.updatedToolCalls),
      status: request.status,
    ),
    conversationId: request.conversationId,
  );
}

Future<void> _updateToolResults(
  MessageRepository messageRepository,
  PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
  _ToolResultsRequest request,
) async {
  final message = await messageRepository.getMessageById(request.messageId);
  if (message == null) return;

  await _persistUpdatedToolResults(
    messageRepository,
    persistToolCallResultsUsecase,
    request,
    message.metadata ?? const MessageMetadataEntity(),
  );
}

Future<void> _persistUpdatedToolResults(
  MessageRepository messageRepository,
  PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
  _ToolResultsRequest request,
  MessageMetadataEntity metadata,
) async {
  final updatedToolCalls = _toolCallsWithResults(
    metadata.toolCalls,
    request.updates,
    request.appDataByToolCallId,
  );
  await _persistToolResults((
    messageRepository: messageRepository,
    persistToolCallResultsUsecase: persistToolCallResultsUsecase,
    request: request,
    metadata: metadata,
    toolCalls: updatedToolCalls,
  ));
}

Future<void> _persistToolResults(_PersistToolResultsRequest request) async {
  final patch = _toolResultsPatch(request);
  final media = _toolResultMedia(request.request.updates);
  await _persistToolResultsByMedia(request, patch, media);
}

MessagePatch _toolResultsPatch(_PersistToolResultsRequest request) {
  final metadata = request.metadata.copyWith(toolCalls: request.toolCalls);

  return MessagePatch(
    metadata: metadata,
    status: metadata.hasPendingToolCalls ? null : .sent,
  );
}

Future<void> _persistToolResultsByMedia(
  _PersistToolResultsRequest request,
  MessagePatch patch,
  List<ToolCallResultMedia> media,
) async {
  final usecase = request.persistToolCallResultsUsecase;
  if (media.isNotEmpty && usecase == null) {
    throw StateError('Tool result media persistence is not configured.');
  }
  if (usecase == null) {
    await _persistToolResultsWithoutMedia(request, patch);

    return;
  }

  await _persistToolResultsWithMedia(usecase, request.request, patch, media);
}

Future<void> _persistToolResultsWithoutMedia(
  _PersistToolResultsRequest request,
  MessagePatch patch,
) async {
  final repository = request.messageRepository;
  final persistenceRequest = request.request;
  final _ = await repository.patchMessage(
    persistenceRequest.messageId,
    patch,
    conversationId: persistenceRequest.conversationId,
  );
}

Future<void> _persistToolResultsWithMedia(
  PersistToolCallResultsUsecase usecase,
  _ToolResultsRequest request,
  MessagePatch patch,
  List<ToolCallResultMedia> media,
) => usecase.call((
  messageId: request.messageId,
  conversationId: request.conversationId,
  patch: patch,
  media: media,
));

List<ToolCallResultMedia> _toolResultMedia(
  List<agent.AgentToolResultUpdate> updates,
) => [
  for (final update in updates)
    if (update.media.isNotEmpty)
      (toolCallId: update.toolCallId, media: update.media),
];

List<MessageToolCallEntity> _toolCallsWithResults(
  List<MessageToolCallEntity> toolCalls,
  List<agent.AgentToolResultUpdate> updates,
  Map<String, Map<String, Object?>> appDataByToolCallId,
) => [
  for (final toolCall in toolCalls)
    _toolCallWithResult(toolCall, updates, appDataByToolCallId),
];

MessageToolCallEntity _toolCallWithResult(
  MessageToolCallEntity toolCall,
  List<agent.AgentToolResultUpdate> updates,
  Map<String, Map<String, Object?>> appDataByToolCallId,
) {
  final update = updates
      .where((candidate) => candidate.toolCallId == toolCall.id)
      .firstOrNull;
  if (update == null) return toolCall;

  if (update.approvalRequested) {
    return _markToolCallApprovalRequested(toolCall);
  }

  return _toolCallWithResultStatus(toolCall, update, appDataByToolCallId);
}

MessageToolCallEntity _markToolCallApprovalRequested(
  MessageToolCallEntity toolCall,
) => toolCall.copyWith(approvalRequested: true);

MessageToolCallEntity _toolCallWithResultStatus(
  MessageToolCallEntity toolCall,
  agent.AgentToolResultUpdate update,
  Map<String, Map<String, Object?>> appDataByToolCallId,
) {
  final status = update.resultStatus;
  if (status == null) return toolCall;

  final withStatus = toolCall.copyWith(
    resultStatus: AgentToolStatusMapper.toResultStatus(status),
  );

  return sanitizeWorkspaceToolResult(
    _applyToolExecutionOutput(
      withStatus,
      update,
    ).copyWith(appData: appDataByToolCallId[update.toolCallId]),
  );
}

MessageToolCallEntity _applyToolExecutionOutput(
  MessageToolCallEntity toolCall,
  agent.AgentToolResultUpdate update,
) => toolCall.copyWith(
  responseRaw: update.responseRaw,
  responseContextRaw: update.responseContextRaw,
  outputTruncated: update.outputTruncated,
  originalResponseBytes: update.originalResponseBytes,
  fullOutputForContext: update.fullOutputForContext,
);

void _logToolExecutionError(_ToolExecutionErrorRequest request) {
  _logger.severe(
    'Tool execution failed '
    'conversationId=${request.conversationId} '
    'toolCallId=${request.toolCallId} '
    'toolType=${request.tool.type.name} '
    'toolIdentifier=${request.tool.toolIdentifier} '
    'failurePhase=${request.failurePhase ?? 'unknown'} '
    'errorType=${request.error.runtimeType} '
    'errorMessage=${_toolExecutionErrorMessage(request.error)} '
    'stackTrace=${LogRedaction.redact(request.stackTrace)}',
  );
}

String _toolExecutionErrorMessage(Object error) {
  const redact = LogRedaction.redact;

  return switch (error) {
    UnsupportedError(:final message) => redact(message),
    StateError(:final message) => redact(message),
    TimeoutException(:final message, :final duration) =>
      '${redact(message)} duration=${duration?.inSeconds}s',
    _ => redact(error),
  };
}

final Provider<AgentToolExecutionService> agentToolExecutionServiceProvider =
    Provider<AgentToolExecutionService>((ref) {
      return AgentToolExecutionService(
        loadLatestMessageToolCallsUsecase: ref.watch(
          agentToolCallLoaderProvider,
        ),
        messageRepository: ref.watch(messageRepositoryProvider),
        runResolvedToolUsecase: ref.watch(resolvedToolServiceProvider),
        getAgentIterationDecisionUsecase: ref.watch(
          agentToolDecisionServiceProvider,
        ),
        agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
        resolveToolApprovalDecisionForWorkspace: (workspaceId) =>
            ref.read(resolveToolApprovalDecisionUsecaseProvider(workspaceId)),
        persistToolCallResultsUsecase: ref.watch(
          persistToolCallResultsUsecaseProvider,
        ),
      );
    });
