import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_execution_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_conversation_data_provider.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

typedef _ChildFinishRequest = ({
  String conversationId,
  agent.SubAgentCompletionStatus status,
  Object? error,
  StackTrace? stackTrace,
});

class AgentToolResumeService({
  required MessageRepository messageRepository,
  required ConversationRepository conversationRepository,
  required AgentToolExecutionService toolExecutionService,
  required agent.AgentLoopRunner agentLoop,
  ActiveSubAgentRuntime? activeSubAgents,
}) extends agent.AgentToolResumeRunner {
  this
    : super(
        provider: AppAgentToolResumeProvider(
          messageRepository: messageRepository,
          conversationRepository: conversationRepository,
          toolExecutionService: toolExecutionService,
          agentLoop: agentLoop,
          activeSubAgents: activeSubAgents,
        ),
      );
}

class const AppAgentToolResumeProvider({
  required final MessageRepository messageRepository,
  required final ConversationRepository conversationRepository,
  required final AgentToolExecutionService toolExecutionService,
  required final agent.AgentLoopRunner agentLoop,
  required final ActiveSubAgentRuntime? activeSubAgents,
}) implements agent.AgentToolResumeProvider {
  @override
  Future<agent.AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    final decision = await _runAllowedTools(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    if (decision != agent.AgentIterationDecision.done) return decision;

    _finishChildIfNeeded(activeSubAgents, (
      conversationId: conversationId,
      status: .done,
      error: null,
      stackTrace: null,
    ));

    return decision;
  }

  @override
  Future<void> continueAgent({
    required String conversationId,
    required agent.AgentIterationContext context,
  }) async {
    final decision = await _continueAgent(
      conversationId: conversationId,
      context: context,
    );
    if (decision == agent.AgentIterationDecision.waitForToolApproval) return;

    _finishChildIfNeeded(activeSubAgents, (
      conversationId: conversationId,
      status: .done,
      error: null,
      stackTrace: null,
    ));
  }

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

  Future<agent.AgentIterationDecision> _runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    try {
      return await toolExecutionService.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      );
    } on Object catch (error, stackTrace) {
      _finishChildIfNeeded(activeSubAgents, (
        conversationId: conversationId,
        status: .error,
        error: error,
        stackTrace: stackTrace,
      ));
      rethrow;
    }
  }

  Future<agent.AgentIterationDecision> _continueAgent({
    required String conversationId,
    required agent.AgentIterationContext context,
  }) async {
    try {
      return await agentLoop(conversationId: conversationId, context: context);
    } on Object catch (error, stackTrace) {
      _finishChildIfNeeded(activeSubAgents, (
        conversationId: conversationId,
        status: .error,
        error: error,
        stackTrace: stackTrace,
      ));
      rethrow;
    }
  }
}

void _finishChildIfNeeded(
  ActiveSubAgentRuntime? runtime,
  _ChildFinishRequest request,
) {
  if (runtime == null) return;

  final parentId = runtime.parentOf(request.conversationId);
  if (parentId == null) return;

  runtime.finish((
    parentId: parentId,
    childId: request.conversationId,
    status: request.status,
    error: request.error,
    stackTrace: request.stackTrace,
  ));
}

final agentToolResumeServiceProvider = Provider<AgentToolResumeService>(
  (ref) => AgentToolResumeService(
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    toolExecutionService: ref.watch(agentToolExecutionServiceProvider),
    agentLoop: ref.watch(appAgentLoopProvider),
    activeSubAgents: ref.watch(activeSubAgentRuntimeProvider.notifier),
  ),
  dependencies: [appAgentLoopProvider],
);
