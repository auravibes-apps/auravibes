import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/chats/agent_adapters/build_skill_context_messages_service.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('BuildSkillContextMessagesService', () {
    test('builds catalog metadata without conversation skill bodies', () async {
      final listUseCase = _MockListAvailableSkillsUsecase();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final buildManifests = _MockBuildLoadedSkillManifestsUsecase();
      final usecase = BuildSkillContextMessagesService(
        listUseCase.call,
        listAgentSkills,
        buildManifests,
      );
      const skill = AvailableSkill(
        source: SkillSource.user,
        id: 'skill-1',
        slug: 'research',
        title: 'Research',
        description: '',
        content: 'Use primary sources.',
        kind: .template,
      );
      when(
        () => listUseCase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .catalog,
        ),
      ).thenAnswer((_) async => const [skill]);
      when(
        () => listUseCase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loaded,
        ),
      ).thenAnswer((_) async => const [skill]);
      when(
        () => listAgentSkills.loadSelectedAgent(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer((_) async => null);
      when(
        () => listAgentSkills.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => buildManifests.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          extraSkills: any(named: 'extraSkills'),
        ),
      ).thenAnswer(
        (_) async => [
          SkillManifest(
            slug: 'research',
            title: 'Research',
            description: 'Use primary sources.',
            revision: 'r1',
            tools: const [],
          ),
        ],
      );

      final messages = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(messages, hasLength(1));
      expect(messages.single.metadata['kind'], skillCatalogMetadataKind);
      expect(messages.single.content, contains('<skill_catalog'));
      expect(messages.single.content, contains('"revision":"r1"'));
      expect(messages.single.content, isNot(contains('Use primary sources.')));
    });

    test('escapes XML special characters in skill title and content', () async {
      final listUseCase = _MockListAvailableSkillsUsecase();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final buildManifests = _MockBuildLoadedSkillManifestsUsecase();
      final usecase = BuildSkillContextMessagesService(
        listUseCase.call,
        listAgentSkills,
        buildManifests,
      );
      when(
        () => listUseCase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: .catalog,
        ),
      ).thenAnswer(
        (_) async => [
          const AvailableSkill(
            source: SkillSource.user,
            id: '1',
            slug: 'slug',
            title: '<a&b"c\'d>',
            description: '',
            content: '<x&y"z\'w>',
            kind: .template,
          ),
        ],
      );
      when(
        () => listUseCase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: .loaded,
        ),
      ).thenAnswer(
        (_) async => [
          const AvailableSkill(
            source: SkillSource.user,
            id: '1',
            slug: 'slug',
            title: '<a&b"c\'d>',
            description: '',
            content: '<x&y"z\'w>',
            kind: .template,
          ),
        ],
      );
      when(
        () => listAgentSkills.loadSelectedAgent(
          conversationId: 'c',
          workspaceId: 'w',
        ),
      ).thenAnswer((_) async => null);
      when(() => listAgentSkills.call(conversationId: 'c', workspaceId: 'w'))
          .thenAnswer((_) async => const []);
      when(
        () => buildManifests.call(
          conversationId: 'c',
          workspaceId: 'w',
          extraSkills: any(named: 'extraSkills'),
        ),
      ).thenAnswer(
        (_) async => [
          SkillManifest(
            slug: 'slug',
            title: '<a&b"c\'d>',
            description: '',
            revision: 'r1',
            tools: [],
          ),
        ],
      );

      final messages = await usecase.call(
        conversationId: 'c',
        workspaceId: 'w',
      );

      expect(messages, hasLength(1));
      expect(messages.single.content, contains('&lt;a&amp;b'));
      expect(messages.single.content, contains(r'''b\"c'd&gt;'''));
      expect(messages.single.content, isNot(contains('<x&y')));
    });

    test(
      'keeps agent skills inline without conversation skill bodies',
      () async {
        final listUseCase = _MockListAvailableSkillsUsecase();
        final listAgentSkills = _MockListConversationAgentSkillsUsecase();
        final buildManifests = _MockBuildLoadedSkillManifestsUsecase();
        final usecase = BuildSkillContextMessagesService(
          listUseCase.call,
          listAgentSkills,
          buildManifests,
        );
        final now = DateTime(2026);
        const loadedSkill = AvailableSkill(
          source: SkillSource.user,
          id: 'skill-1',
          slug: 'skill_one',
          title: 'Skill One',
          description: '',
          content: 'Loaded content',
          kind: .template,
        );
        const duplicateAgentSkill = AvailableSkill(
          source: SkillSource.user,
          id: 'skill-1',
          slug: 'skill_one',
          title: 'Skill One Duplicate',
          description: '',
          content: 'Agent duplicate content',
          kind: .template,
        );
        const appAgentSkill = AvailableSkill(
          source: SkillSource.app,
          id: 'app-skill',
          slug: 'app_skill',
          title: 'App Skill',
          description: '',
          content: 'App content',
          kind: .native,
        );

        when(
          () => listUseCase.call(
            conversationId: any(named: 'conversationId'),
            workspaceId: any(named: 'workspaceId'),
            filter: .catalog,
          ),
        ).thenAnswer((_) async => [loadedSkill]);
        when(
          () => listUseCase.call(
            conversationId: any(named: 'conversationId'),
            workspaceId: any(named: 'workspaceId'),
            filter: .loaded,
          ),
        ).thenAnswer((_) async => [loadedSkill]);
        when(
          () => listAgentSkills.loadSelectedAgent(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer(
          (_) async => AgentEntity(
            id: 'agent-1',
            workspaceId: 'workspace-1',
            name: 'Agent',
            content: 'Agent prompt',
            skills: const [],
            createdAt: now,
            updatedAt: now,
          ),
        );
        when(
          () => listAgentSkills.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async => [duplicateAgentSkill, appAgentSkill]);
        when(
          () => buildManifests.call(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            extraSkills: any(named: 'extraSkills'),
          ),
        ).thenAnswer(
          (_) async => [
            SkillManifest(
              slug: 'skill_one',
              title: 'Skill One',
              description: '',
              revision: 'r1',
              tools: [],
            ),
            SkillManifest(
              slug: 'app_skill',
              title: 'App Skill',
              description: '',
              revision: 'r2',
              tools: [],
            ),
          ],
        );

        final messages = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(messages, hasLength(4));
        expect(messages.firstOrNull?.content, 'Agent prompt');
        expect(messages[1].metadata['kind'], skillCatalogMetadataKind);
        expect(messages[1].content, isNot(contains('Loaded content')));
        expect(messages[2].content, contains('Agent duplicate content'));
        expect(messages[3].content, contains('App content'));
      },
    );

    test('skips selected agent from another workspace', () async {
      final listUseCase = _MockListAvailableSkillsUsecase();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final usecase = BuildSkillContextMessagesService(
        listUseCase.call,
        listAgentSkills,
      );
      when(
        () => listUseCase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: .catalog,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => listUseCase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: .loaded,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => listAgentSkills.loadSelectedAgent(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer((_) async => null);
      when(
        () => listAgentSkills.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer((_) async => const []);

      final messages = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(messages, isEmpty);
    });
  });
}

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase;

class _MockListConversationAgentSkillsUsecase extends Mock
    implements ListConversationAgentSkillsUsecase;

class _MockBuildLoadedSkillManifestsUsecase extends Mock
    implements BuildLoadedSkillManifestsUsecase;
