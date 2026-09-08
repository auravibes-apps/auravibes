import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('skill context includes deterministic manifest', () {
    final messages = const BuildSkillContextMessages().compose(
      conversationSkills: [
        AgentSkill(
          title: 'Research',
          content: 'Use primary sources.',
          identity: 'user:skill-1',
          manifest: SkillManifest(
            slug: 'research',
            title: 'Research',
            instructions: 'Use primary sources.',
            revision: 'r1',
            tools: const [],
          ),
        ),
      ],
      agentSkills: const [],
    );

    expect(messages.single.content, contains('<skill_manifest>'));
    expect(
      messages.single.content,
      contains('&quot;revision&quot;:&quot;r1&quot;'),
    );
  });

  test('composes agent context and deduplicated skill sources', () {
    final messages = const BuildSkillContextMessages().compose(
      agentContent: 'You are precise.',
      conversationSkills: const [
        AgentSkill(
          title: 'Research',
          content: 'Use primary sources.',
          identity: 'user:research',
        ),
      ],
      agentSkills: const [
        AgentSkill(
          title: 'Research',
          content: 'Use primary sources.',
          identity: 'user:research',
        ),
        AgentSkill(
          title: 'Writer',
          content: 'Keep it concise.',
          identity: 'app:writer',
        ),
      ],
    );

    expect(messages.map((message) => message.role), [
      AgentChatMessageRole.system,
      AgentChatMessageRole.user,
      AgentChatMessageRole.user,
    ]);
    expect(messages.first.content, 'You are precise.');
    expect(
      messages.where((message) => message.content.contains('Research')),
      hasLength(1),
    );
  });
}
