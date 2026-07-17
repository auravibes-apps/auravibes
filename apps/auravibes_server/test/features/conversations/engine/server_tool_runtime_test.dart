import 'package:auravibes_engine/src/sub_agents/sub_agent_tool_specs.dart';
import 'package:auravibes_engine/src/tool_name_resolver.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('server executes durable sub-agent tools', () {
    expect(
      serverToolIsExecutable(
        AgentResolvedToolName.skillNative(
          tableId: runSubAgentToolName,
          skillSlug: agentsSkillSlug,
          toolIdentifier: runSubAgentToolName,
        ),
      ),
      isTrue,
    );
  });
  test(
    'approval pause resumes once and completed replay skips side effect',
    () {
      var sideEffects = 0;
      for (final status in [
        'pending',
        'approved',
        'running',
        'success',
        'denied',
      ]) {
        if (serverToolReplayAction(status) == ServerToolReplayAction.execute) {
          sideEffects++;
        }
      }

      expect(sideEffects, 1);
      expect(serverToolReplayAction('pending'), ServerToolReplayAction.pause);
      expect(serverToolReplayAction('running'), ServerToolReplayAction.skip);
    },
  );
}
