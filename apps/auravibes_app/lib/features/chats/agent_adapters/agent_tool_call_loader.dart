import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_status_mapper.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

typedef ToolToCall = agent.AgentToolToCall<ResolvedTool>;

typedef LoadLatestMessageToolCallsResult =
    agent.LoadLatestMessageToolCallsResult<ResolvedTool>;

typedef _ToolResolutionRequest = ({
  ConversationRepository conversationRepository,
  LoadConversationToolSpecsUsecase Function(String workspaceId)
  loadConversationToolSpecsUsecaseForWorkspace,
  ToolResolverService toolResolverService,
  String conversationId,
  String toolName,
});

class AgentToolCallLoader({
  required MessageRepository messageRepository,
  required ConversationRepository conversationRepository,
  required LoadConversationToolSpecsUsecase Function(String workspaceId)
  loadConversationToolSpecsUsecaseForWorkspace,
  required ToolResolverService toolResolverService,
}) extends agent.AgentToolCallLoader<ResolvedTool> {
  this
    : super(
        provider: AppAgentToolCallProvider(
          messageRepository: messageRepository,
          conversationRepository: conversationRepository,
          loadConversationToolSpecsUsecaseForWorkspace:
              loadConversationToolSpecsUsecaseForWorkspace,
          toolResolverService: toolResolverService,
        ),
      );
}

class const AppAgentToolCallProvider({
  required final MessageRepository messageRepository,
  required final ConversationRepository conversationRepository,
  required final LoadConversationToolSpecsUsecase Function(String workspaceId)
  loadConversationToolSpecsUsecaseForWorkspace,
  required final ToolResolverService toolResolverService,
}) implements agent.AgentToolCallProvider<ResolvedTool> {
  @override
  Future<List<agent.AgentToolMessage>> loadMessages(
    String conversationId,
  ) async {
    final messages = await messageRepository.getMessagesByConversation(
      conversationId,
    );

    return messages.map(_toAgentToolMessage).toList();
  }

  @override
  Future<ResolvedTool?> resolveTool({
    required String conversationId,
    required String toolName,
  }) {
    return _resolveTool((
      conversationRepository: conversationRepository,
      loadConversationToolSpecsUsecaseForWorkspace:
          loadConversationToolSpecsUsecaseForWorkspace,
      toolResolverService: toolResolverService,
      conversationId: conversationId,
      toolName: toolName,
    ));
  }
}

Future<ResolvedTool?> _resolveTool(_ToolResolutionRequest request) async {
  final conversation = await request.conversationRepository.getConversationById(
    request.conversationId,
  );
  final catalog = conversation == null
      ? agent.buildToolCatalog<ResolvedTool>([])
      : await request
            .loadConversationToolSpecsUsecaseForWorkspace(
              conversation.workspaceId,
            )
            .buildCatalog(
              conversationId: request.conversationId,
              workspaceId: conversation.workspaceId,
            );

  return request.toolResolverService.resolveTool(request.toolName, catalog);
}

agent.AgentToolMessage _toAgentToolMessage(MessageEntity message) {
  return agent.AgentToolMessage(
    id: message.id,
    isUser: message.isUser,
    toolCalls: _agentToolCalls(message.metadata?.toolCalls),
  );
}

List<agent.AgentMessageToolCall> _agentToolCalls(
  Iterable<MessageToolCallEntity>? toolCalls,
) => [
  for (final toolCall in toolCalls ?? const <MessageToolCallEntity>[])
    if (!toolCall.isRunning)
      agent.AgentMessageToolCall(
        id: toolCall.id,
        name: toolCall.name,
        argumentsRaw: toolCall.argumentsRaw,
        lifecycle: AgentToolStatusMapper.toLifecycle(toolCall.resultStatus),
      ),
];

final agentToolCallLoaderProvider = Provider<AgentToolCallLoader>((ref) {
  return AgentToolCallLoader(
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    loadConversationToolSpecsUsecaseForWorkspace: (workspaceId) =>
        ref.read(loadConversationToolSpecsUsecaseProvider(workspaceId)),
    toolResolverService: const ToolResolverService(),
  );
});
