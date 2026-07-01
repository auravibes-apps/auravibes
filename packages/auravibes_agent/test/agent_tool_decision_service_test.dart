import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_agent/src/agent_tool_decision_service.dart';
import 'package:test/test.dart';

void main() {
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

class _FakeAgentToolCallDataProvider implements AgentToolDecisionProvider {
  const _FakeAgentToolCallDataProvider({required this.states});

  final List<AgentToolCallState>? states;

  @override
  Future<List<AgentToolCallState>?> getToolCallStates(String messageId) async {
    return states;
  }
}
