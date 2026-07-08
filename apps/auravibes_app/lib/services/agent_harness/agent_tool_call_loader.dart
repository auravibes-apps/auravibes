// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
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
    required ToolResolverService toolResolverService,
  }) : super(
         provider: AppAgentToolCallProvider(
           messageRepository: messageRepository,
           toolResolverService: toolResolverService,
         ),
       );
}

class AppAgentToolCallProvider
    implements agent.AgentToolCallProvider<ResolvedTool> {
  const AppAgentToolCallProvider({
    required this.messageRepository,
    required this.toolResolverService,
  });

  final MessageRepository messageRepository;
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
  ResolvedTool? resolveTool(String toolName) {
    return toolResolverService.resolveTool(toolName);
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
              resultStatus: toAgentToolCallResultStatus(toolCall.resultStatus),
            ),
      ],
    );
  }
}

final agentToolCallLoaderProvider = Provider<AgentToolCallLoader>((ref) {
  return AgentToolCallLoader(
    messageRepository: ref.watch(messageRepositoryProvider),
    toolResolverService: const ToolResolverService(),
  );
});
