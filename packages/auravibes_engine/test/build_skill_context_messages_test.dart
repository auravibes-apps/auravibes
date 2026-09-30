import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('builds escaped skill context messages', () {
    const usecase = BuildSkillContextMessages();

    final result = usecase([
      const AgentSkill(title: 'Plan & Build', content: '<do work>'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.role, AgentChatMessageRole.user);
    expect(
      result.single.content,
      '<skill><name>Plan &amp; Build</name><content>&lt;do work&gt;</content></skill>',
    );
    expect(result.single.metadata['kind'], skillContextMetadataKind);
  });

  test('publishes the same catalog revision in context metadata', () {
    const entries = [
      SkillCatalogEntry(
        slug: 'research',
        title: 'Research',
        description: 'Find sources',
        revision: 'skill-r1',
        active: true,
      ),
    ];
    final messages = const BuildSkillContextMessages().compose(
      conversationSkills: const [],
      agentSkills: const [],
      skillCatalog: entries,
    );
    final catalogMessage = messages.single;

    expect(
      catalogMessage.metadata[skillCatalogRevisionMetadataKey],
      buildSkillCatalogRevision(entries),
    );
    expect(
      catalogMessage.content,
      contains(
        catalogMessage.metadata[skillCatalogRevisionMetadataKey]! as String,
      ),
    );
  });
}
