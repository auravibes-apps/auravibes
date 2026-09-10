import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:logging/logging.dart';

final _logger = Logger('approve_tool_call_service');

typedef _ToolCallLookupRequest = ({String messageId, String toolCallId});

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
  String messageId,
  String toolCallId,
  ToolCallResultStatus resultStatus,
  String? responseRaw,
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
  Future<void> updateToolCallResult({
    required String messageId,
    required String toolCallId,
    required agent.AgentToolResultStatus resultStatus,
    String? responseRaw,
  }) => _patchToolCall(messageRepository, onToolCallChanged, (
    messageId: messageId,
    toolCallId: toolCallId,
    resultStatus: AgentToolStatusMapper.toResultStatus(resultStatus),
    responseRaw: responseRaw,
  ));

  @override
  void logToolExecutionError(_ToolExecutionErrorRequest request) =>
      _logToolExecutionError(request);

  @override
  Future<agent.AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
  }) {
    return _loadToolCall(messageRepository, (
      messageId: messageId,
      toolCallId: toolCallId,
    ));
  }

  @override
  Future<ResolvedTool?> resolveTool({
    required String conversationId,
    required String toolName,
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
  }) {
    return _patchToolCall(messageRepository, onToolCallChanged, (
      messageId: messageId,
      toolCallId: toolCallId,
      resultStatus: .running,
      responseRaw: null,
    ));
  }

  @override
  Future<void> resumeConversationIfReady({required String messageId}) {
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
    conversationId,
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
  await _setAlwaysAllow(toolsRepository, conversationId, permissionTableId);
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
  final message = await messageRepository.getMessageById(request.messageId);
  if (message == null) return;

  final metadata = message.metadata ?? const MessageMetadataEntity();
  final updatedToolCalls = _updatedToolCalls(metadata.toolCalls, request);

  await _persistToolCallPatch(
    messageRepository,
    request.messageId,
    metadata.copyWith(toolCalls: updatedToolCalls),
  );
  onToolCallChanged();
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

Future<void> _persistToolCallPatch(
  MessageRepository messageRepository,
  String messageId,
  MessageMetadataEntity metadata,
) async {
  final _ = await messageRepository.patchMessage(
    messageId,
    .new(metadata: metadata),
  );
}

void _logToolExecutionError(_ToolExecutionErrorRequest request) {
  _logger.severe(
    'Approved tool execution failed '
    'conversationId=${request.conversationId} '
    'toolCallId=${request.toolCallId} '
    'toolType=${request.tool.type.name} '
    'toolIdentifier=${request.tool.toolIdentifier}',
    request.error,
    request.stackTrace,
  );
}
