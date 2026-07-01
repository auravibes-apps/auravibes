import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/services/agent_harness/agent_service.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_execution_service.dart';
import 'package:riverpod/riverpod.dart';

class AgentToolResumeService extends agent.AgentToolResumeRunner {
  AgentToolResumeService({
    required MessageRepository messageRepository,
    required ConversationRepository conversationRepository,
    required AgentToolExecutionService toolExecutionService,
    required AgentService agentService,
  }) : super(
         provider: AppAgentToolResumeProvider(
           messageRepository: messageRepository,
           conversationRepository: conversationRepository,
           toolExecutionService: toolExecutionService,
           agentService: agentService,
         ),
       );
}

class AppAgentToolResumeProvider implements agent.AgentToolResumeProvider {
  const AppAgentToolResumeProvider({
    required this.messageRepository,
    required this.conversationRepository,
    required this.toolExecutionService,
    required this.agentService,
  });

  final MessageRepository messageRepository;
  final ConversationRepository conversationRepository;
  final AgentToolExecutionService toolExecutionService;
  final AgentService agentService;

  @override
  Future<agent.AgentToolResumeReference?> getResumeReference(
    String messageId,
  ) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return null;

    final conversation = await conversationRepository.getConversationById(
      message.conversationId,
    );
    if (conversation == null) return null;

    return agent.AgentToolResumeReference(
      conversationId: conversation.id,
      workspaceId: conversation.workspaceId,
    );
  }

  @override
  Future<agent.AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) {
    return toolExecutionService.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  @override
  Future<void> continueAgent({
    required String conversationId,
    required agent.AgentIterationContext context,
  }) async {
    final _ = await agentService.call(
      conversationId: conversationId,
      context: context,
    );
  }
}

final agentToolResumeServiceProvider = Provider<AgentToolResumeService>((ref) {
  return AgentToolResumeService(
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    toolExecutionService: ref.watch(agentToolExecutionServiceProvider),
    agentService: ref.watch(agentServiceProvider),
  );
});
