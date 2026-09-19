import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_effective_tool_approval_usecase.dart';
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
  String argumentsRaw,
  ResolveEffectiveToolApprovalUsecase? resolveEffectiveToolApprovalUsecase,
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
});

typedef _ToolCallPersistenceRequest = ({
  MessageRepository messageRepository,
  String messageId,
  MessageMetadataEntity metadata,
  String conversationId,
  MessageStatus? status,
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
  final ResolveEffectiveToolApprovalUsecase?
  resolveEffectiveToolApprovalUsecase,
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
  ) => _patchToolCall(messageRepository, onToolCallChanged, (
    messageId: request.messageId,
    toolCallId: request.toolCallId,
    resultStatus: AgentToolStatusMapper.toResultStatus(request.resultStatus),
    responseRaw: request.responseRaw,
    conversationId: request.conversationId,
  ));

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
      argumentsRaw: argumentsRaw,
      resolveEffectiveToolApprovalUsecase: resolveEffectiveToolApprovalUsecase,
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
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) {
    return runResolvedToolUsecase(
      conversationId: conversationId,
      tool: tool,
      arguments: arguments,
    );
  }

  @override
  Future<void> markToolCallRunning({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) {
    return _patchToolCall(messageRepository, onToolCallChanged, (
      conversationId: conversationId,
      messageId: messageId,
      toolCallId: toolCallId,
      resultStatus: .running,
      responseRaw: null,
    ));
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

Future<agent.AgentApprovableToolCall?> _loadToolCall(
  MessageRepository messageRepository,
  _ToolCallLookupRequest request,
) async {
  final message = await messageRepository.getMessageById(request.messageId);
  if (message == null) return null;
  if (message.conversationId != request.conversationId) {
    _logger.warning(
      'Tool approval message ownership mismatch '
      'messageId=${request.messageId} '
      'toolCallId=${request.toolCallId} '
      'requestedConversationId=${request.conversationId} '
      'actualConversationId=${message.conversationId}',
    );
    throw const MessageValidationException('Fork reference is read-only');
  }

  final toolCall = _findToolCall(message.metadata, request.toolCallId);
  if (toolCall == null) return null;

  return _toApprovableToolCall(message.conversationId, toolCall);
}

MessageToolCallEntity? _findToolCall(
  MessageMetadataEntity? metadata,
  String toolCallId,
) => metadata?.toolCalls.where((tool) => tool.id == toolCallId).firstOrNull;

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
  final resolved = request.toolResolverService.resolveTool(
    request.toolName,
    catalog,
  );

  return await _resolveEffectiveTool(request, conversation, resolved);
}

Future<ResolvedTool?> _resolveEffectiveTool(
  _ToolResolutionRequest request,
  ConversationEntity conversation,
  ResolvedTool? resolved,
) {
  final resolver = request.resolveEffectiveToolApprovalUsecase;
  if (resolved == null || resolver == null) return Future.value(resolved);

  return resolver.call(
    conversationId: request.conversationId,
    workspaceId: conversation.workspaceId,
    requestedTool: resolved,
    argumentsRaw: request.argumentsRaw,
  );
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
  _ToolCallPatchRequest request,
) async {
  final message = await _loadOwnedToolCallMessage(messageRepository, request);
  if (message == null) return;

  await _patchOwnedToolCall(messageRepository, message, request);
  onToolCallChanged();
}

Future<void> _patchOwnedToolCall(
  MessageRepository messageRepository,
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
          : toolCall.copyWith(
              resultStatus: request.resultStatus,
              responseRaw: request.responseRaw,
            ),
    )
    .toList();

Future<void> _persistToolCallPatch(_ToolCallPersistenceRequest request) async {
  final _ = await request.messageRepository.patchMessage(
    request.messageId,
    .new(metadata: request.metadata, status: request.status),
    conversationId: request.conversationId,
  );
}

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
