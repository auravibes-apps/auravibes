import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

class SubAgentTurnRuntime {
  agent.ContinueSubAgentTurn? _runner;

  agent.ContinueSubAgentTurn? get runner => _runner;

  set runner(agent.ContinueSubAgentTurn runner) => _runner = runner;

  void clear(agent.ContinueSubAgentTurn runner) {
    if (_runner != runner) return;

    _runner = null;
  }

  Future<agent.AgentIterationDecision> call({
    required String conversationId,
    required agent.AgentIterationContext context,
  }) {
    final runner = this.runner;
    if (runner == null) {
      throw StateError('Sub-agent runner is not configured.');
    }

    return runner(conversationId: conversationId, context: context);
  }
}

final subAgentTurnRuntimeProvider = Provider<SubAgentTurnRuntime>((ref) {
  return SubAgentTurnRuntime();
});
