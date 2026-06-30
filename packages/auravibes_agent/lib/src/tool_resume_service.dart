import 'package:auravibes_agent/src/agent_iteration_context.dart';
import 'package:auravibes_agent/src/agent_iteration_decision.dart';

class AgentToolResumeReference {
  const AgentToolResumeReference({
    required this.conversationId,
    required this.workspaceId,
  });

  final String conversationId;
  final String workspaceId;
}

abstract interface class AgentToolResumeProvider {
  Future<AgentToolResumeReference?> getResumeReference(String messageId);

  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  });

  Future<void> continueAgent({
    required String conversationId,
    required AgentIterationContext context,
  });
}

class AgentToolResumeService {
  const AgentToolResumeService({required this.provider});

  final AgentToolResumeProvider provider;

  Future<void> call({required String messageId}) async {
    final reference = await provider.getResumeReference(messageId);
    if (reference == null) return;

    final decision = await provider.runAllowedTools(
      conversationId: reference.conversationId,
      workspaceId: reference.workspaceId,
    );
    if (decision != AgentIterationDecision.continueIteration) return;

    await provider.continueAgent(
      conversationId: reference.conversationId,
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.toolResume,
      ),
    );
  }
}
