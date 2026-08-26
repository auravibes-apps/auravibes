// ignore_for_file: always_put_required_named_parameters_first
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_resume_service.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_status_mapper.dart';
import 'package:auravibes_app/services/agent_harness/resolved_tool_service.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:logging/logging.dart';

final _logger = Logger('approve_tool_call_service');

class AppApproveToolCallDataProvider
    implements agent.ApproveToolCallProvider<ResolvedTool> {
  const AppApproveToolCallDataProvider({
    required this.messageRepository,
    required this.conversationRepository,
    this.conversationToolsRepository,
    this.resolveToolApprovalDecisionUsecase,
    this.conversationToolsRepositoryForWorkspace,
    this.resolveToolApprovalDecisionUsecaseForWorkspace,
    this.loadConversationToolSpecsUsecase,
    this.loadConversationToolSpecsUsecaseForWorkspace,
    required this.toolResolverService,
    required this.agentToolResumeService,
    required this.runResolvedToolUsecase,
    required this.agentCancellationRuntime,
    required this.onToolCallChanged,
  }) : assert(
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

  final MessageRepository messageRepository;
  final ConversationRepository conversationRepository;
  final ConversationToolsRepository? conversationToolsRepository;
  final ResolveToolApprovalDecisionUsecase? resolveToolApprovalDecisionUsecase;
  final ConversationToolsRepository Function(String workspaceId)?
  conversationToolsRepositoryForWorkspace;
  final ResolveToolApprovalDecisionUsecase Function(String workspaceId)?
  resolveToolApprovalDecisionUsecaseForWorkspace;
  final LoadConversationToolSpecsUsecase? loadConversationToolSpecsUsecase;
  final LoadConversationToolSpecsUsecase Function(String workspaceId)?
  loadConversationToolSpecsUsecaseForWorkspace;
  final ToolResolverService toolResolverService;
  final AgentToolResumeService agentToolResumeService;
  final ResolvedToolService runResolvedToolUsecase;
  final AgentCancellationRuntime agentCancellationRuntime;
  final void Function() onToolCallChanged;

  @override
  Future<agent.AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
  }) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return null;

    final toolCall = message.metadata?.toolCalls
        .where((tool) => tool.id == toolCallId)
        .firstOrNull;
    if (toolCall == null) return null;

    return agent.AgentApprovableToolCall(
      conversationId: message.conversationId,
      name: toolCall.name,
      argumentsRaw: toolCall.argumentsRaw,
    );
  }

  @override
  Future<ResolvedTool?> resolveTool({
    required String conversationId,
    required String toolName,
  }) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      return toolResolverService.resolveTool(
        toolName,
        agent.buildToolCatalog<ResolvedTool>([]),
      );
    }
    final loadToolSpecs =
        loadConversationToolSpecsUsecaseForWorkspace?.call(
          conversation.workspaceId,
        ) ??
        loadConversationToolSpecsUsecase;
    if (loadToolSpecs == null) {
      throw StateError('Conversation tool specs usecase is unavailable.');
    }
    final catalog = await loadToolSpecs.buildCatalog(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
    );

    return toolResolverService.resolveTool(toolName, catalog);
  }

  @override
  Future<void> grantToolForConversation({
    required String conversationId,
    required ResolvedTool tool,
  }) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) return;
    final approvalUsecase =
        resolveToolApprovalDecisionUsecaseForWorkspace?.call(
          conversation.workspaceId,
        ) ??
        resolveToolApprovalDecisionUsecase;
    if (approvalUsecase == null) {
      throw StateError('Tool approval usecase is unavailable.');
    }
    final permissionTableId = await approvalUsecase.resolvePermissionTableId(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
      resolvedTool: tool,
    );
    if (permissionTableId == null) return;

    final toolsRepository =
        conversationToolsRepositoryForWorkspace?.call(
          conversation.workspaceId,
        ) ??
        conversationToolsRepository;
    if (toolsRepository == null) {
      throw StateError('Conversation tools repository is unavailable.');
    }
    final _ = await toolsRepository.setConversationToolPermission(
      conversationId,
      permissionTableId,
      permissionMode: ToolPermissionMode.alwaysAllow,
    );
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
  }) async {
    await _patchToolCall(
      messageId: messageId,
      toolCallId: toolCallId,
      resultStatus: ToolCallResultStatus.running,
    );
  }

  @override
  Future<void> updateToolCallResult({
    required String messageId,
    required String toolCallId,
    required agent.AgentToolResultStatus resultStatus,
    String? responseRaw,
  }) async {
    await _patchToolCall(
      messageId: messageId,
      toolCallId: toolCallId,
      resultStatus: AgentToolStatusMapper.toResultStatus(resultStatus),
      responseRaw: responseRaw,
    );
  }

  @override
  Future<void> resumeConversationIfReady({required String messageId}) {
    return agentToolResumeService.call(messageId: messageId);
  }

  @override
  bool isCancellationRequested(String conversationId) {
    return agentCancellationRuntime.isCancellationRequested(conversationId);
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

  Future<void> _patchToolCall({
    required String messageId,
    required String toolCallId,
    required ToolCallResultStatus resultStatus,
    String? responseRaw,
  }) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (toolCall.id != toolCallId) return toolCall;

      return toolCall.copyWith(
        resultStatus: resultStatus,
        responseRaw: responseRaw,
      );
    }).toList();

    final _ = await messageRepository.patchMessage(
      messageId,
      MessagePatch(metadata: metadata.copyWith(toolCalls: updatedToolCalls)),
    );
    onToolCallChanged();
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
    'Approved tool execution failed '
    'conversationId=$conversationId '
    'toolCallId=$toolCallId '
    'toolType=${tool.type.name} '
    'toolIdentifier=${tool.toolIdentifier}',
    error,
    stackTrace,
  );
}
