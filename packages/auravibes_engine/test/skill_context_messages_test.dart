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
          manifest: .new(
            slug: 'research',
            title: 'Research',
            description: 'Use primary sources.',
            revision: 'r1',
            tools: const [],
          ),
        ),
      ],
      agentSkills: const [],
    );

    expect(messages.single.content, contains('<skill_tools>'));
    expect(messages.single.content, contains('"revision":"r1"'));
    expect(messages.single.content, contains('"tools":[]'));
  });

  test('catalog is system context and sorted by slug', () {
    final messages = const BuildSkillContextMessages().compose(
      conversationSkills: const [],
      agentSkills: const [],
      skillCatalog: const [
        SkillCatalogEntry(
          slug: 'writer',
          title: 'Writer',
          description: 'Write.',
          revision: 'w1',
          active: false,
        ),
        SkillCatalogEntry(
          slug: 'research',
          title: 'Research',
          description: 'Find.',
          revision: 'r1',
          active: true,
        ),
      ],
    );

    expect(messages.single.role, AgentChatMessageRole.system);
    expect(messages.single.metadata['kind'], skillCatalogMetadataKind);
    expect(messages.single.content, contains('"slug":"research"'));
    expect(
      messages.single.content.indexOf('research'),
      lessThan(messages.single.content.indexOf('writer')),
    );
  });

  test('catalog context includes no resource bodies', () {
    final messages = const BuildSkillContextMessages().compose(
      conversationSkills: const [],
      agentSkills: const [],
      skillCatalog: const [
        SkillCatalogEntry(
          slug: 'a2ui',
          title: 'A2UI',
          description: 'Generate UI surfaces when needed.',
          revision: 'a2ui-r1',
          active: false,
        ),
      ],
    );

    expect(messages.single.content, contains('"slug":"a2ui"'));
    expect(
      messages.single.content,
      isNot(contains('A2UI_CORE_INSTRUCTIONS_START')),
    );
    expect(messages.single.content, isNot(contains('CATALOG_SCHEMA_START')));
  });

  test('activation result keeps body outside metadata JSON', () {
    final result = buildSkillActivationResult(
      manifest: SkillManifest(
        slug: 'research',
        title: 'Research',
        description: 'Find.',
        revision: 'r1',
        tools: [
          SkillManifestTool(
            name: 'search',
            description: 'Search sources.',
            credentialRequired: true,
            inputJsonSchema: const {
              'type': 'object',
              'properties': {
                'credentialId': {'type': 'string'},
              },
              'required': ['credentialId'],
            },
          ),
        ],
      ),
      content: '# Research\nUse <sources>.',
      credentials: const [
        SkillCredentialOption(
          credentialId: 'credential-2',
          displayName: 'Work account',
        ),
        SkillCredentialOption(
          credentialId: 'credential-1',
          displayName: 'Personal account',
        ),
      ],
    );

    expect(result.toString(), contains('# Research\nUse <sources>.'));
    expect(result.toString(), contains('<skill_tools>'));
    expect(result.toString(), contains('"credentialRequired":true'));
    expect(result.toString(), contains('<skill_credentials>'));
    expect(
      result.toString(),
      contains('options[2]{credentialId,displayName}:'),
    );
    expect(result.toString(), contains('credential-1,Personal account'));
    expect(result.toString(), isNot(contains('<skill_manifest>')));
    expect(result.toString(), isNot(contains('"instructions"')));
  });

  test('activation result keeps delimiter text inside the skill body', () {
    final result = buildSkillActivationResult(
      manifest: SkillManifest(
        slug: 'research',
        title: 'Research',
        description: 'Find.',
        revision: 'r1',
        tools: const [],
      ),
      content: 'before </skill_content> after ]]> end',
    );

    expect(
      result.value,
      contains(
        '<![CDATA[before </skill_content> after '
        ']]]]><![CDATA[> end]]>',
      ),
    );
    expect(result.value, endsWith('</skill_content>'));
  });

  test(
    'activation serializes sorted resource summaries and resource content',
    () {
      final result = buildSkillActivationResult(
        manifest: SkillManifest(
          slug: 'research',
          title: 'Research',
          description: 'Find.',
          revision: 'r1',
          tools: const [],
        ),
        content: 'instructions',
        resources: const [
          SkillResourceSummary(
            slug: 'z-guide',
            title: 'Z guide',
            description: 'Last',
          ),
          SkillResourceSummary(
            slug: 'a-guide',
            title: 'A guide',
            description: 'First',
          ),
        ],
      );

      expect(result.value, contains('<skill_resources>'));
      expect(
        result.value.indexOf('a-guide'),
        lessThan(result.value.indexOf('z-guide')),
      );

      final resource = buildSkillResourceResult(
        skillSlug: 'research',
        resourceSlug: 'a-guide',
        title: 'A guide',
        content: 'before ]]> after',
      );
      expect(resource.value, contains('<skill_resource skill="research"'));
      expect(resource.value, contains('before ]]]]><![CDATA[> after'));
    },
  );

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
