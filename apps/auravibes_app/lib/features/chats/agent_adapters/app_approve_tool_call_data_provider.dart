import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/sanitize_workspace_tool_result.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/persist_tool_call_results_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:logging/logging.dart';

final _logger = Logger('approve_tool_call_service');

typedef _ToolCallLookupRequest = ({
  String conversationId,
  String messageId,
  String toolCallId,
});

typedef _ToolResolutionRequest = ({
  ConversationRepository conversationRepository,
  LoadConversationToolSpecsUsecase? loadConversationToolSpecsUsecase,
  LoadConversationToolSpecsUsecase Function(String workspaceId)?
  loadConversationToolSpecsUsecaseForWorkspace,
  ToolResolverService toolResolverService,
  String conversationId,
  String toolName,
});

typedef _ToolGrantRequest = ({
  ConversationRepository conversationRepository,
  ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecisionUsecase,
  ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionUsecaseForWorkspace,
  ConversationToolsRepository? conversationToolsRepository,
  ConversationToolsRepository Function(String workspaceId)?
  conversationToolsRepositoryForWorkspace,
  String conversationId,
  ResolvedTool tool,
});

typedef _ToolCallPatchRequest = ({
  String conversationId,
  String messageId,
  String toolCallId,
  ToolCallResultStatus resultStatus,
  String? responseRaw,
  String? responseContextRaw,
  Map<String, Object?>? appData,
  List<agent.AgentToolResultMedia> media,
  bool outputTruncated,
  int? originalResponseBytes,
  bool fullOutputForContext,
});

typedef _ToolCallPersistenceRequest = ({
  MessageRepository messageRepository,
  String messageId,
  MessageMetadataEntity metadata,
  String conversationId,
  MessageStatus? status,
  String toolCallId,
  List<agent.AgentToolResultMedia> media,
  PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
});

typedef _ToolExecutionErrorRequest =
    agent.AgentToolExecutionErrorRequest<ResolvedTool>;

class const AppApproveToolCallDataProvider({
  required final MessageRepository messageRepository,
  required final ConversationRepository conversationRepository,
  required final ToolResolverService toolResolverService,
  required final AgentToolResumeService agentToolResumeService,
  required final ResolvedToolService runResolvedToolUsecase,
  required final AgentCancellationRuntime agentCancellationRuntime,
  required final void Function() onToolCallChanged,
  final ConversationToolsRepository? conversationToolsRepository,
  final ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecisionUsecase,
  final ConversationToolsRepository Function(String workspaceId)?
  conversationToolsRepositoryForWorkspace,
  final ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionUsecaseForWorkspace,
  final LoadConversationToolSpecsUsecase? loadConversationToolSpecsUsecase,
  final LoadConversationToolSpecsUsecase Function(String workspaceId)?
  loadConversationToolSpecsUsecaseForWorkspace,
  final PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
}) implements agent.ApproveToolCallProvider<ResolvedTool> {
  this
    : assert(
        conversationToolsRepository != null ||
            conversationToolsRepositoryForWorkspace != null,
        'A conversation tools repository is required.',
      ),
      assert(
        resolveToolApprovalDecisionUsecase != null ||
            resolveToolApprovalDecisionUsecaseForWorkspace != null,
        'A tool approval usecase is required.',
      ),
      assert(
        loadConversationToolSpecsUsecase != null ||
            loadConversationToolSpecsUsecaseForWorkspace != null,
        'A conversation tool specs usecase is required.',
      );

  @override
  Future<void> updateToolCallResult(
    agent.AgentToolCallResultUpdateRequest request,
  ) async {
    final appData = runResolvedToolUsecase.takeMcpAppResultData(
      conversationId: request.conversationId,
      toolCallId: request.toolCallId,
    );
    await _patchToolCall(
      messageRepository,
      onToolCallChanged,
      persistToolCallResultsUsecase,
      _toolCallPatchRequest(request, appData),
    );
  }

  @override
  void logToolExecutionError(_ToolExecutionErrorRequest request) =>
      _logToolExecutionError(request);

  @override
  Future<agent.AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) {
    return _loadToolCall(messageRepository, (
      conversationId: conversationId,
      messageId: messageId,
      toolCallId: toolCallId,
    ));
  }

  @override
  Future<ResolvedTool?> resolveTool({
    required String conversationId,
    required String toolName,
    required String argumentsRaw,
  }) {
    return _resolveTool((
      conversationRepository: conversationRepository,
      loadConversationToolSpecsUsecase: loadConversationToolSpecsUsecase,
      loadConversationToolSpecsUsecaseForWorkspace:
          loadConversationToolSpecsUsecaseForWorkspace,
      toolResolverService: toolResolverService,
      conversationId: conversationId,
      toolName: toolName,
    ));
  }

  @override
  Future<void> grantToolForConversation({
    required String conversationId,
    required ResolvedTool tool,
  }) {
    return _grantToolForConversation((
      conversationRepository: conversationRepository,
      resolveToolApprovalDecisionUsecase: resolveToolApprovalDecisionUsecase,
      resolveToolApprovalDecisionUsecaseForWorkspace:
          resolveToolApprovalDecisionUsecaseForWorkspace,
      conversationToolsRepository: conversationToolsRepository,
      conversationToolsRepositoryForWorkspace:
          conversationToolsRepositoryForWorkspace,
      conversationId: conversationId,
      tool: tool,
    ));
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) => runResolvedToolUsecase.call(
    conversationId: conversationId,
    toolCallId: toolCallId,
    tool: tool,
    arguments: arguments,
  );

  @override
  Future<void> markToolCallRunning({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) {
    return _patchToolCall(
      messageRepository,
      onToolCallChanged,
      persistToolCallResultsUsecase,
      (
        conversationId: conversationId,
        messageId: messageId,
        toolCallId: toolCallId,
        resultStatus: .running,
        responseRaw: null,
        responseContextRaw: null,
        appData: null,
        media: const [],
        outputTruncated: false,
        originalResponseBytes: null,
        fullOutputForContext: false,
      ),
    );
  }

  @override
  Future<void> resumeConversationIfReady({
    required String messageId,
    required String conversationId,
  }) {
    return agentToolResumeService.call(messageId: messageId);
  }

  @override
  bool isCancellationRequested(String conversationId) {
    return agentCancellationRuntime.isCancellationRequested(conversationId);
  }
}

_ToolCallPatchRequest _toolCallPatchRequest(
  agent.AgentToolCallResultUpdateRequest request,
  Map<String, Object?>? appData,
) => (
  messageId: request.messageId,
  toolCallId: request.toolCallId,
  resultStatus: AgentToolStatusMapper.toResultStatus(request.resultStatus),
  responseRaw: request.responseRaw,
  responseContextRaw: request.responseContextRaw,
  appData: _successfulToolCall(request) ? appData : null,
  media: request.media,
  outputTruncated: request.outputTruncated,
  originalResponseBytes: request.originalResponseBytes,
  fullOutputForContext: request.fullOutputForContext,
  conversationId: request.conversationId,
);

bool _successfulToolCall(agent.AgentToolCallResultUpdateRequest request) =>
    request.resultStatus == .success;

Future<agent.AgentApprovableToolCall?> _loadToolCall(
  MessageRepository messageRepository,
  _ToolCallLookupRequest request,
) async {
  final message = await messageRepository.getMessageById(request.messageId);
  if (message == null) return null;
  if (message.conversationId != request.conversationId) {
    _logToolApprovalOwnershipMismatch(request, message.conversationId);
    throw const MessageValidationException('Fork reference is read-only');
  }

  final toolCall = _findToolCall(message.metadata, request.toolCallId);
  if (toolCall == null) return null;

  return _toApprovableToolCall(message.conversationId, toolCall);
}

void _logToolApprovalOwnershipMismatch(
  _ToolCallLookupRequest request,
  String actualConversationId,
) {
  _logger.warning(
    'Tool approval message ownership mismatch '
    'request=$request actualConversationId=$actualConversationId',
  );
}

MessageToolCallEntity? _findToolCall(
  MessageMetadataEntity? metadata,
  String toolCallId,
) {
  final matches = metadata?.toolCalls.where((tool) => tool.id == toolCallId);
  if (matches == null || matches.length != 1) return null;

  return matches.single;
}

agent.AgentApprovableToolCall _toApprovableToolCall(
  String conversationId,
  MessageToolCallEntity toolCall,
) => agent.AgentApprovableToolCall(
  conversationId: conversationId,
  name: toolCall.name,
  argumentsRaw: toolCall.argumentsRaw,
);

Future<ResolvedTool?> _resolveTool(_ToolResolutionRequest request) async {
  final conversation = await request.conversationRepository.getConversationById(
    request.conversationId,
  );
  if (conversation == null) {
    return await _resolveWithoutConversation(request);
  }

  return await _resolveToolInConversation(request, conversation);
}

Future<ResolvedTool?> _resolveToolInConversation(
  _ToolResolutionRequest request,
  ConversationEntity conversation,
) async {
  final catalog = await _loadConversationToolCatalog(request, conversation);

  return request.toolResolverService.resolveTool(request.toolName, catalog);
}

Future<ResolvedTool?> _resolveWithoutConversation(
  _ToolResolutionRequest request,
) => Future.value(
  request.toolResolverService.resolveTool(
    request.toolName,
    agent.buildToolCatalog<ResolvedTool>([]),
  ),
);

Future<agent.ToolCatalog<ResolvedTool>> _loadConversationToolCatalog(
  _ToolResolutionRequest request,
  ConversationEntity conversation,
) async {
  final loadToolSpecs = _loadToolSpecs(request, conversation.workspaceId);
  if (loadToolSpecs == null) {
    throw StateError('Conversation tool specs usecase is unavailable.');
  }

  return await loadToolSpecs.buildCatalog(
    conversationId: request.conversationId,
    workspaceId: conversation.workspaceId,
  );
}

LoadConversationToolSpecsUsecase? _loadToolSpecs(
  _ToolResolutionRequest request,
  String workspaceId,
) =>
    request.loadConversationToolSpecsUsecaseForWorkspace?.call(workspaceId) ??
    request.loadConversationToolSpecsUsecase;

Future<void> _grantToolForConversation(_ToolGrantRequest request) async {
  final conversationId = request.conversationId;
  final conversation = await request.conversationRepository.getConversationById(
    conversationId,
  );
  if (conversation == null) return;

  await _grantToolForConversationInWorkspace(request, conversation);
}

Future<void> _grantToolForConversationInWorkspace(
  _ToolGrantRequest request,
  ConversationEntity conversation,
) async {
  final approvalUsecase = _approvalUsecase(request, conversation.workspaceId);
  if (approvalUsecase == null) {
    throw StateError('Tool approval usecase is unavailable.');
  }
  final permissionTableId = await _permissionTableId(
    approvalUsecase,
    request.conversationId,
    conversation.workspaceId,
    request.tool,
  );
  if (permissionTableId == null) return;

  final toolsRepository = _conversationToolsRepository(
    request,
    conversation.workspaceId,
  );
  if (toolsRepository == null) {
    throw StateError('Conversation tools repository is unavailable.');
  }
  await _setAlwaysAllow(
    toolsRepository,
    request.conversationId,
    permissionTableId,
  );
}

Future<String?> _permissionTableId(
  ResolveToolApprovalDecisionUsecase approvalUsecase,
  String conversationId,
  String workspaceId,
  ResolvedTool tool,
) => approvalUsecase.resolvePermissionTableId(
  conversationId: conversationId,
  workspaceId: workspaceId,
  resolvedTool: tool,
);

Future<void> _setAlwaysAllow(
  ConversationToolsRepository repository,
  String conversationId,
  String permissionTableId,
) async {
  final _ = await repository.setConversationToolPermission(
    conversationId,
    permissionTableId,
    permissionMode: .alwaysAllow,
  );
}

ResolveToolApprovalDecisionUsecase? _approvalUsecase(
  _ToolGrantRequest request,
  String workspaceId,
) =>
    request.resolveToolApprovalDecisionUsecaseForWorkspace?.call(workspaceId) ??
    request.resolveToolApprovalDecisionUsecase;

ConversationToolsRepository? _conversationToolsRepository(
  _ToolGrantRequest request,
  String workspaceId,
) =>
    request.conversationToolsRepositoryForWorkspace?.call(workspaceId) ??
    request.conversationToolsRepository;

Future<void> _patchToolCall(
  MessageRepository messageRepository,
  void Function() onToolCallChanged,
  PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
  _ToolCallPatchRequest request,
) async {
  final message = await _loadOwnedToolCallMessage(messageRepository, request);
  if (message == null) return;

  await _patchOwnedToolCall(
    messageRepository,
    persistToolCallResultsUsecase,
    message,
    request,
  );
  onToolCallChanged();
}

Future<void> _patchOwnedToolCall(
  MessageRepository messageRepository,
  PersistToolCallResultsUsecase? persistToolCallResultsUsecase,
  MessageEntity message,
  _ToolCallPatchRequest request,
) async {
  final updatedMetadata = _updatedToolCallMetadata(message, request);

  await _persistToolCallPatch((
    messageRepository: messageRepository,
    messageId: request.messageId,
    metadata: updatedMetadata,
    conversationId: request.conversationId,
    status: updatedMetadata.hasPendingToolCalls ? null : .sent,
    toolCallId: request.toolCallId,
    media: request.media,
    persistToolCallResultsUsecase: persistToolCallResultsUsecase,
  ));
}

MessageMetadataEntity _updatedToolCallMetadata(
  MessageEntity message,
  _ToolCallPatchRequest request,
) {
  final metadata = message.metadata ?? const MessageMetadataEntity();

  return metadata.copyWith(
    toolCalls: _updatedToolCalls(metadata.toolCalls, request),
  );
}

Future<MessageEntity?> _loadOwnedToolCallMessage(
  MessageRepository messageRepository,
  _ToolCallPatchRequest request,
) async {
  final message = await messageRepository.getMessageById(request.messageId);
  if (message == null) return null;
  if (message.conversationId != request.conversationId) {
    throw const MessageValidationException('Fork reference is read-only');
  }

  return message;
}

List<MessageToolCallEntity> _updatedToolCalls(
  List<MessageToolCallEntity> toolCalls,
  _ToolCallPatchRequest request,
) => toolCalls
    .map(
      (toolCall) => toolCall.id != request.toolCallId
          ? toolCall
          : _updatedToolCall(toolCall, request),
    )
    .toList();

MessageToolCallEntity _updatedToolCall(
  MessageToolCallEntity toolCall,
  _ToolCallPatchRequest request,
) => sanitizeWorkspaceToolResult(
  _applyToolCallPatch(
    toolCall.copyWith(resultStatus: request.resultStatus),
    request,
  ),
);

MessageToolCallEntity _applyToolCallPatch(
  MessageToolCallEntity toolCall,
  _ToolCallPatchRequest request,
) => toolCall.copyWith(
  responseRaw: request.responseRaw,
  responseContextRaw: request.responseContextRaw,
  appData: request.appData,
  outputTruncated: request.outputTruncated,
  originalResponseBytes: request.originalResponseBytes,
  fullOutputForContext: request.fullOutputForContext,
);

Future<void> _persistToolCallPatch(_ToolCallPersistenceRequest request) {
  final usecase = request.persistToolCallResultsUsecase;
  if (request.media.isNotEmpty && usecase == null) {
    throw StateError('Tool result media persistence is not configured.');
  }

  final patch = MessagePatch(
    metadata: request.metadata,
    status: request.status,
  );
  if (usecase == null) return _patchApprovedToolCall(request, patch);

  return _persistApprovedToolCallMedia(request, usecase, patch);
}

Future<void> _patchApprovedToolCall(
  _ToolCallPersistenceRequest request,
  MessagePatch patch,
) async {
  final _ = await request.messageRepository.patchMessage(
    request.messageId,
    patch,
    conversationId: request.conversationId,
  );
}

Future<void> _persistApprovedToolCallMedia(
  _ToolCallPersistenceRequest request,
  PersistToolCallResultsUsecase usecase,
  MessagePatch patch,
) => usecase.call((
  messageId: request.messageId,
  conversationId: request.conversationId,
  patch: patch,
  media: [(toolCallId: request.toolCallId, media: request.media)],
));

void _logToolExecutionError(_ToolExecutionErrorRequest request) {
  _logger.severe(
    'Approved tool execution failed '
    'conversationId=${request.conversationId} '
    'toolCallId=${request.toolCallId} '
    'toolType=${request.tool.type.name} '
    'toolIdentifier=${request.tool.toolIdentifier} '
    'failurePhase=${request.failurePhase ?? 'unknown'} '
    'error=${LogRedaction.redact(request.error)} '
    'stackTrace=${LogRedaction.redact(request.stackTrace)}',
  );
}
