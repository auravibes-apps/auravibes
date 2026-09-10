import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
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

typedef _ToolExecutionErrorRequest = ({
  String conversationId,
  String toolCallId,
  ResolvedTool tool,
  Object error,
  StackTrace stackTrace,
});

class const AppApproveToolCallDataProvider({
  required final MessageRepository messageRepository,
  required final ConversationRepository conversationRepository,
  final ConversationToolsRepository? conversationToolsRepository,
  final ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecisionUsecase,
  final ConversationToolsRepository Function(String workspaceId)?
  conversationToolsRepositoryForWorkspace,
  final ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionUsecaseForWorkspace,
  final LoadConversationToolSpecsUsecase? loadConversationToolSpecsUsecase,
  final LoadConversationToolSpecsUsecase Function(String workspaceId)?
  loadConversationToolSpecsUsecaseForWorkspace,
  required final ToolResolverService toolResolverService,
  required final AgentToolResumeService agentToolResumeService,
  required final ResolvedToolService runResolvedToolUsecase,
  required final AgentCancellationRuntime agentCancellationRuntime,
  required final void Function() onToolCallChanged,
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

  late final Future<void> Function({
    required String messageId,
    required String toolCallId,
    required agent.AgentToolResultStatus resultStatus,
    String? responseRaw,
  })
  updateToolCallResult =
      ({
        required messageId,
        required toolCallId,
        required resultStatus,
        responseRaw,
      }) async {
        await _patchToolCall(messageRepository, onToolCallChanged, (
          messageId: messageId,
          toolCallId: toolCallId,
          resultStatus: AgentToolStatusMapper.toResultStatus(resultStatus),
          responseRaw: responseRaw,
        ));
      };

  late final void Function({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Object error,
    required StackTrace stackTrace,
  })
  logToolExecutionError =
      ({
        required conversationId,
        required toolCallId,
        required tool,
        required error,
        required stackTrace,
      }) {
        _logToolExecutionError((
          conversationId: conversationId,
          toolCallId: toolCallId,
          tool: tool,
          error: error,
          stackTrace: stackTrace,
        ));
      };

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

  final toolCall = message.metadata?.toolCalls
      .where((tool) => tool.id == request.toolCallId)
      .firstOrNull;
  if (toolCall == null) return null;

  return agent.AgentApprovableToolCall(
    conversationId: message.conversationId,
    name: toolCall.name,
    argumentsRaw: toolCall.argumentsRaw,
  );
}

Future<ResolvedTool?> _resolveTool(_ToolResolutionRequest request) async {
  final conversation = await request.conversationRepository.getConversationById(
    request.conversationId,
  );
  if (conversation == null) {
    return request.toolResolverService.resolveTool(
      request.toolName,
      agent.buildToolCatalog<ResolvedTool>([]),
    );
  }
  final loadToolSpecs =
      request.loadConversationToolSpecsUsecaseForWorkspace?.call(
        conversation.workspaceId,
      ) ??
      request.loadConversationToolSpecsUsecase;
  if (loadToolSpecs == null) {
    throw StateError('Conversation tool specs usecase is unavailable.');
  }
  final catalog = await loadToolSpecs.buildCatalog(
    conversationId: request.conversationId,
    workspaceId: conversation.workspaceId,
  );

  return request.toolResolverService.resolveTool(request.toolName, catalog);
}

Future<void> _grantToolForConversation(_ToolGrantRequest request) async {
  final conversation = await request.conversationRepository.getConversationById(
    request.conversationId,
  );
  if (conversation == null) return;
  final approvalUsecase =
      request.resolveToolApprovalDecisionUsecaseForWorkspace?.call(
        conversation.workspaceId,
      ) ??
      request.resolveToolApprovalDecisionUsecase;
  if (approvalUsecase == null) {
    throw StateError('Tool approval usecase is unavailable.');
  }
  final permissionTableId = await approvalUsecase.resolvePermissionTableId(
    conversationId: request.conversationId,
    workspaceId: conversation.workspaceId,
    resolvedTool: request.tool,
  );
  if (permissionTableId == null) return;

  final toolsRepository =
      request.conversationToolsRepositoryForWorkspace?.call(
        conversation.workspaceId,
      ) ??
      request.conversationToolsRepository;
  if (toolsRepository == null) {
    throw StateError('Conversation tools repository is unavailable.');
  }
  final _ = await toolsRepository.setConversationToolPermission(
    request.conversationId,
    permissionTableId,
    permissionMode: .alwaysAllow,
  );
}

Future<void> _patchToolCall(
  MessageRepository messageRepository,
  void Function() onToolCallChanged,
  _ToolCallPatchRequest request,
) async {
  final message = await messageRepository.getMessageById(request.messageId);
  if (message == null) return;

  final metadata = message.metadata ?? const MessageMetadataEntity();
  final updatedToolCalls = metadata.toolCalls.map((toolCall) {
    if (toolCall.id != request.toolCallId) return toolCall;

    return toolCall.copyWith(
      resultStatus: request.resultStatus,
      responseRaw: request.responseRaw,
    );
  }).toList();

  final _ = await messageRepository.patchMessage(
    request.messageId,
    .new(metadata: metadata.copyWith(toolCalls: updatedToolCalls)),
  );
  onToolCallChanged();
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
