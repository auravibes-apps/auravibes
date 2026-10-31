import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/agent_tool_execution_service.dart';
import 'package:auravibes_engine/src/agent_tool_loop_guard.dart';
import 'package:test/test.dart';

void main() {
  test('canonicalizes arguments and detects an identical call and result', () {
    final first = agentToolOutcomeFingerprint(
      toolName: 'search',
      argumentsRaw: '{"query":"cats","limit":5}',
      resultStatus: AgentToolResultStatus.success,
      responseRaw: '["cat"]',
    );
    final reordered = agentToolOutcomeFingerprint(
      toolName: 'search',
      argumentsRaw: '{ "limit": 5, "query": "cats" }',
      resultStatus: AgentToolResultStatus.success,
      responseRaw: '["cat"]',
    );

    expect(first, reordered);
    expect(hasRepeatedNoProgressToolCycle([first], reordered), isTrue);
  });

  test('changed arguments or results count as progress', () {
    final original = agentToolOutcomeFingerprint(
      toolName: 'search',
      argumentsRaw: '{"query":"cats"}',
      resultStatus: AgentToolResultStatus.success,
      responseRaw: '["cat"]',
    );
    final changedArguments = agentToolOutcomeFingerprint(
      toolName: 'search',
      argumentsRaw: '{"query":"dogs"}',
      resultStatus: AgentToolResultStatus.success,
      responseRaw: '["cat"]',
    );
    final changedResult = agentToolOutcomeFingerprint(
      toolName: 'search',
      argumentsRaw: '{"query":"cats"}',
      resultStatus: AgentToolResultStatus.success,
      responseRaw: '["cat", "kitten"]',
    );
    final truncatedResult = agentToolOutcomeFingerprint(
      toolName: 'search',
      argumentsRaw: '{"query":"cats"}',
      resultStatus: AgentToolResultStatus.success,
      responseRaw: 'same truncated preview',
      outputDigest: 'first-full-result-digest',
    );
    final changedTruncatedResult = agentToolOutcomeFingerprint(
      toolName: 'search',
      argumentsRaw: '{"query":"cats"}',
      resultStatus: AgentToolResultStatus.success,
      responseRaw: 'same truncated preview',
      outputDigest: 'different-full-result-digest',
    );

    expect(changedArguments, isNot(original));
    expect(changedResult, isNot(original));
    expect(changedTruncatedResult, isNot(truncatedResult));
    expect(
      hasRepeatedNoProgressToolCycle([original], changedArguments),
      isFalse,
    );
    expect(hasRepeatedNoProgressToolCycle([original], changedResult), isFalse);
  });

  test(
    'detects a repeated multi-tool cycle but allows changed cycle results',
    () {
      expect(hasRepeatedNoProgressToolCycle(['a', 'b', 'a'], 'b'), isTrue);
      expect(
        hasRepeatedNoProgressToolCycle(['a', 'b', 'a'], 'changed-b'),
        isFalse,
      );
    },
  );
}
