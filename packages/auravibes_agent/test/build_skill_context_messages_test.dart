import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:test/test.dart';

void main() {
  test('builds escaped skill context messages', () {
    const usecase = BuildSkillContextMessages();

    final result = usecase([
      const AgentSkill(
        title: 'Plan & Build',
        content: '<do work>',
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.role, AgentChatMessageRole.user);
    expect(
      result.single.content,
      '<skill><name>Plan &amp; Build</name><content>&lt;do work&gt;</content></skill>',
    );
    expect(result.single.metadata['kind'], skillContextMetadataKind);
  });
}
