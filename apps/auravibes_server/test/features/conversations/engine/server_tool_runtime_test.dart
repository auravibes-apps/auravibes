import 'package:auravibes_engine/src/skills/service_skills/service_skill_definitions.dart';
import 'package:auravibes_engine/src/sub_agents/sub_agent_tool_specs.dart';
import 'package:auravibes_engine/src/tool_name_resolver.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
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
  test('server executes declarative service native tools', () {
    final skill = serviceSkillDefinitions.first;
    final nativeTool = skill.nativeTools.first;

    expect(
      serverToolIsExecutable(
        AgentResolvedToolName.skillNative(
          tableId: nativeTool.slug,
          skillSlug: skill.slug,
          toolIdentifier: nativeTool.slug,
        ),
      ),
      isTrue,
    );
  });

  test('cloud native credentials require the matching service', () {
    expect(cloudServiceConnectionId('service:credential-1'), 'credential-1');
    expect(cloudServiceConnectionId('credential-1'), 'credential-1');
    expect(
      isCloudAppSkillCredential(
        const {'kind': 'appSkillCredential', 'serviceId': 'search'},
        'search',
      ),
      isTrue,
    );
    expect(
      isCloudAppSkillCredential(
        const {'kind': 'appSkillCredential', 'serviceId': 'other'},
        'search',
      ),
      isFalse,
    );
    expect(
      isCloudAppSkillCredential(
        const {'kind': 'modelProvider', 'serviceId': 'search'},
        'search',
      ),
      isFalse,
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
