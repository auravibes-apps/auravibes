import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
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
    ActiveSubAgentRuntime? activeSubAgents,
  }) : super(
         provider: AppAgentToolResumeProvider(
           messageRepository: messageRepository,
           conversationRepository: conversationRepository,
           toolExecutionService: toolExecutionService,
           agentService: agentService,
           activeSubAgents: activeSubAgents,
         ),
       );
}

class AppAgentToolResumeProvider implements agent.AgentToolResumeProvider {
  const AppAgentToolResumeProvider({
    required this.messageRepository,
    required this.conversationRepository,
    required this.toolExecutionService,
    required this.agentService,
    required this.activeSubAgents,
  });

  final MessageRepository messageRepository;
  final ConversationRepository conversationRepository;
  final AgentToolExecutionService toolExecutionService;
  final AgentService agentService;
  final ActiveSubAgentRuntime? activeSubAgents;

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
  }) async {
    final decision = await toolExecutionService.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    if (decision != agent.AgentIterationDecision.done) return decision;

    final runtime = activeSubAgents;
    if (runtime == null) return decision;

    final parentId = runtime.parentOf(conversationId);
    if (parentId == null) return decision;

    runtime.finish(parentId: parentId, childId: conversationId);

    return decision;
  }

  @override
  Future<void> continueAgent({
    required String conversationId,
    required agent.AgentIterationContext context,
  }) async {
    final decision = await agentService.call(
      conversationId: conversationId,
      context: context,
    );
    if (decision == agent.AgentIterationDecision.waitForToolApproval) return;

    final runtime = activeSubAgents;
    if (runtime == null) return;

    final parentId = runtime.parentOf(conversationId);
    if (parentId == null) return;

    runtime.finish(parentId: parentId, childId: conversationId);
  }
}

final agentToolResumeServiceProvider = Provider<AgentToolResumeService>((ref) {
  return AgentToolResumeService(
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    toolExecutionService: ref.watch(agentToolExecutionServiceProvider),
    agentService: ref.watch(agentServiceProvider),
    activeSubAgents: ref.watch(activeSubAgentRuntimeProvider.notifier),
  );
});
