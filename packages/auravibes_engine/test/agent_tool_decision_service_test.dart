import 'package:auravibes_engine/src/agent_iteration_decision.dart';
import 'package:auravibes_engine/src/agent_tool_decision_service.dart';
import 'package:test/test.dart';

void main() {
  test('pure decision handles missing and mixed lifecycle states', () {
    expect(decideAgentToolIteration(null), AgentIterationDecision.done);
    expect(decideAgentToolIteration(const []), AgentIterationDecision.done);
    expect(
      decideAgentToolIteration(const [
        AgentToolCallState.resolved,
        AgentToolCallState.pending,
      ]),
      AgentIterationDecision.waitForToolApproval,
    );
    expect(
      decideAgentToolIteration(const [
        AgentToolCallState.pending,
        AgentToolCallState.stopped,
      ]),
      AgentIterationDecision.done,
    );
  });

  test('waits for approval when any tool is pending', () async {
    const usecase = AgentToolDecisionService(
      provider: _FakeAgentToolCallDataProvider(
        states: [AgentToolCallState.pending],
      ),
    );

    final result = await usecase(messageId: 'message-1');

    expect(result, AgentIterationDecision.waitForToolApproval);
  });

  test('continues when all tools are resolved', () async {
    const usecase = AgentToolDecisionService(
      provider: _FakeAgentToolCallDataProvider(
        states: [AgentToolCallState.resolved],
      ),
    );

    final result = await usecase(messageId: 'message-1');

    expect(result, AgentIterationDecision.continueIteration);
  });

  test('stops when any tool stopped the loop', () async {
    const usecase = AgentToolDecisionService(
      provider: _FakeAgentToolCallDataProvider(
        states: [AgentToolCallState.stopped],
      ),
    );

    final result = await usecase(messageId: 'message-1');

    expect(result, AgentIterationDecision.done);
  });
}

class const _FakeAgentToolCallDataProvider({
  required final List<AgentToolCallState>? states,
}) implements AgentToolDecisionProvider {
  @override
  Future<List<AgentToolCallState>?> getToolCallStates(String messageId) async {
    return states;
  }
}
