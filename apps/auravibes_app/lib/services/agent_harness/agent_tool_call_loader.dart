// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_status_mapper.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

// ignore: unused-code, existing app harness tests import these helper aliases.
typedef ToolToCall = agent.AgentToolToCall<ResolvedTool>;

// ignore: unused-code, existing app harness tests import these helper aliases.
typedef LoadLatestMessageToolCallsResult =
    agent.LoadLatestMessageToolCallsResult<ResolvedTool>;

class AgentToolCallLoader extends agent.AgentToolCallLoader<ResolvedTool> {
  AgentToolCallLoader({
    required MessageRepository messageRepository,
    required ConversationRepository conversationRepository,
    required LoadConversationToolSpecsUsecase Function(String workspaceId)
    loadConversationToolSpecsUsecaseForWorkspace,
    required ToolResolverService toolResolverService,
  }) : super(
         provider: AppAgentToolCallProvider(
           messageRepository: messageRepository,
           conversationRepository: conversationRepository,
           loadConversationToolSpecsUsecaseForWorkspace:
               loadConversationToolSpecsUsecaseForWorkspace,
           toolResolverService: toolResolverService,
         ),
       );
}

class AppAgentToolCallProvider
    implements agent.AgentToolCallProvider<ResolvedTool> {
  const AppAgentToolCallProvider({
    required this.messageRepository,
    required this.conversationRepository,
    required this.loadConversationToolSpecsUsecaseForWorkspace,
    required this.toolResolverService,
  });

  final MessageRepository messageRepository;
  final ConversationRepository conversationRepository;
  final LoadConversationToolSpecsUsecase Function(String workspaceId)
  loadConversationToolSpecsUsecaseForWorkspace;
  final ToolResolverService toolResolverService;

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
  }) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    final catalog = conversation == null
        ? agent.buildToolCatalog<ResolvedTool>([])
        : await loadConversationToolSpecsUsecaseForWorkspace(
            conversation.workspaceId,
          ).buildCatalog(
            conversationId: conversationId,
            workspaceId: conversation.workspaceId,
          );

    return toolResolverService.resolveTool(toolName, catalog);
  }

  agent.AgentToolMessage _toAgentToolMessage(MessageEntity message) {
    return agent.AgentToolMessage(
      id: message.id,
      isUser: message.isUser,
      toolCalls: [
        for (final toolCall
            in message.metadata?.toolCalls ?? const <MessageToolCallEntity>[])
          if (!toolCall.isRunning)
            agent.AgentMessageToolCall(
              id: toolCall.id,
              name: toolCall.name,
              argumentsRaw: toolCall.argumentsRaw,
              lifecycle: toAgentToolCallLifecycle(toolCall.resultStatus),
            ),
      ],
    );
  }
}

final agentToolCallLoaderProvider = Provider<AgentToolCallLoader>((ref) {
  return AgentToolCallLoader(
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    loadConversationToolSpecsUsecaseForWorkspace: (workspaceId) =>
        ref.read(loadConversationToolSpecsUsecaseProvider(workspaceId)),
    toolResolverService: const ToolResolverService(),
  );
});
