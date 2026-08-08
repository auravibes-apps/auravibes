import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/agent_harness/build_skill_context_messages_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('BuildSkillContextMessagesService', () {
    test('attaches loaded manifest by skill slug', () async {
      final listUseCase = _MockListAvailableSkillsUsecase();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final buildManifests = _MockBuildLoadedSkillManifestsUsecase();
      final usecase = BuildSkillContextMessagesService(
        listUseCase.call,
        listAgentSkills,
        buildManifests,
      );
      const skill = AvailableSkill(
        id: 'skill-1',
        slug: 'research',
        title: 'Research',
        description: '',
        content: 'Use primary sources.',
        source: SkillSource.user,
        kind: SkillKind.template,
      );
      when(
        () => listUseCase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: SkillLoadFilter.loaded,
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
        ),
      ).thenAnswer(
        (_) async => [
          SkillManifest(
            slug: 'research',
            title: 'Research',
            instructions: 'Use primary sources.',
            revision: 'r1',
            tools: const [],
          ),
        ],
      );

      final messages = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(messages.single.content, contains('<skill_manifest>'));
      expect(
        messages.single.content,
        contains('&quot;revision&quot;:&quot;r1&quot;'),
      );
    });

    test('escapes XML special characters in skill title and content', () async {
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
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer(
        (_) async => [
          const AvailableSkill(
            id: '1',
            slug: 'slug',
            title: '<a&b"c\'d>',
            description: '',
            content: '<x&y"z\'w>',
            source: SkillSource.user,
            kind: SkillKind.template,
          ),
        ],
      );
      when(
        () => listAgentSkills.loadSelectedAgent(
          conversationId: 'c',
          workspaceId: 'w',
        ),
      ).thenAnswer(
        (_) async => null,
      );
      when(
        () => listAgentSkills.call(conversationId: 'c', workspaceId: 'w'),
      ).thenAnswer((_) async => const []);

      final messages = await usecase.call(
        conversationId: 'c',
        workspaceId: 'w',
      );

      expect(
        messages.single.content,
        '<skill><name>&lt;a&amp;b&quot;c&#39;d&gt;</name>'
        '<content>&lt;x&amp;y&quot;z&#39;w&gt;</content></skill>',
      );
    });

    test('prepends selected agent prompt and dedupes runtime skills', () async {
      final listUseCase = _MockListAvailableSkillsUsecase();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final usecase = BuildSkillContextMessagesService(
        listUseCase.call,
        listAgentSkills,
      );
      final now = DateTime(2026);
      const loadedSkill = AvailableSkill(
        id: 'skill-1',
        slug: 'skill_one',
        title: 'Skill One',
        description: '',
        content: 'Loaded content',
        source: SkillSource.user,
        kind: SkillKind.template,
      );
      const duplicateAgentSkill = AvailableSkill(
        id: 'skill-1',
        slug: 'skill_one',
        title: 'Skill One Duplicate',
        description: '',
        content: 'Agent duplicate content',
        source: SkillSource.user,
        kind: SkillKind.template,
      );
      const appAgentSkill = AvailableSkill(
        id: 'app-skill',
        slug: 'app_skill',
        title: 'App Skill',
        description: '',
        content: 'App content',
        source: SkillSource.app,
        kind: SkillKind.native,
      );

      when(
        () => listUseCase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
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

      final messages = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(messages, hasLength(3));
      expect(messages.firstOrNull?.content, 'Agent prompt');
      expect(messages[1].content, contains('Loaded content'));
      expect(messages[1].content, isNot(contains('Agent duplicate content')));
      expect(messages[2].content, contains('App content'));
    });

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
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => listAgentSkills.loadSelectedAgent(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer(
        (_) async => null,
      );
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
    implements ListAvailableSkillsUsecase {}

class _MockListConversationAgentSkillsUsecase extends Mock
    implements ListConversationAgentSkillsUsecase {}

class _MockBuildLoadedSkillManifestsUsecase extends Mock
    implements BuildLoadedSkillManifestsUsecase {}
