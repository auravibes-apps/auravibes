import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/agent_harness/build_skill_context_messages_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('BuildSkillContextMessagesService', () {
    test('escapes XML special characters in skill title and content', () async {
      final listUseCase = _MockListAvailableSkillsUsecase();
      final conversations = _MockConversationRepository();
      final agents = _MockAgentsRepository();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final usecase = BuildSkillContextMessagesService(
        listUseCase,
        conversations,
        agents,
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
      when(() => conversations.getConversationById('c')).thenAnswer(
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
      final conversations = _MockConversationRepository();
      final agents = _MockAgentsRepository();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final usecase = BuildSkillContextMessagesService(
        listUseCase,
        conversations,
        agents,
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
        () => conversations.getConversationById('conversation-1'),
      ).thenAnswer(
        (_) async => ConversationEntity(
          id: 'conversation-1',
          title: 'Conversation',
          workspaceId: 'workspace-1',
          isPinned: false,
          createdAt: now,
          updatedAt: now,
          agentId: 'agent-1',
        ),
      );
      when(
        () => agents.getAgentById('agent-1'),
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
      final conversations = _MockConversationRepository();
      final agents = _MockAgentsRepository();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final usecase = BuildSkillContextMessagesService(
        listUseCase,
        conversations,
        agents,
        listAgentSkills,
      );
      final now = DateTime(2026);

      when(
        () => listUseCase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => conversations.getConversationById('conversation-1'),
      ).thenAnswer(
        (_) async => ConversationEntity(
          id: 'conversation-1',
          title: 'Conversation',
          workspaceId: 'workspace-1',
          isPinned: false,
          createdAt: now,
          updatedAt: now,
          agentId: 'agent-1',
        ),
      );
      when(() => agents.getAgentById('agent-1')).thenAnswer(
        (_) async => AgentEntity(
          id: 'agent-1',
          workspaceId: 'workspace-2',
          name: 'Agent',
          content: 'Cross workspace prompt',
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

class _MockConversationRepository extends Mock
    implements ConversationRepository {}

class _MockAgentsRepository extends Mock implements AgentsRepository {}

class _MockListConversationAgentSkillsUsecase extends Mock
    implements ListConversationAgentSkillsUsecase {}
