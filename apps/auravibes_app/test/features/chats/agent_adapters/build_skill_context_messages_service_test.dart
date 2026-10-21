import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/chats/agent_adapters/build_skill_context_messages_service.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('BuildSkillContextMessagesService', () {
    test('next continuation rebuilds selected catalog revision', () async {
      final listSkills = _MockListAvailableSkillsUsecase();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final buildManifests = _MockBuildLoadedSkillManifestsUsecase();
      var revision = 'r1';
      var title = 'Original';
      when(
        () => listSkills.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          filter: .catalog,
        ),
      ).thenAnswer(
        (_) async => [
          AvailableSkill(
            id: 'skill',
            slug: 'research',
            title: title,
            description: '',
            content: '',
            source: .user,
            kind: .template,
          ),
        ],
      );
      when(
        () => listSkills.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          filter: .loaded,
        ),
      ).thenAnswer(
        (_) async => [
          AvailableSkill(
            id: 'skill',
            slug: 'research',
            title: title,
            description: '',
            content: '',
            source: .user,
            kind: .template,
          ),
        ],
      );
      when(
        () => listAgentSkills.loadSelectedAgent(
          conversationId: 'conversation',
          workspaceId: 'workspace',
        ),
      ).thenAnswer((_) async => null);
      when(
        () => listAgentSkills.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => buildManifests.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          extraSkills: any(named: 'extraSkills'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => [
          SkillManifest(
            slug: 'research',
            title: title,
            description: '',
            revision: revision,
          ),
        ],
      );
      final service = BuildSkillContextMessagesService(
        listSkills.call,
        listAgentSkills,
        buildManifests,
      );

      final first = await service.call(
        conversationId: 'conversation',
        workspaceId: 'workspace',
      );
      title = 'Updated';
      revision = 'r2';
      final second = await service.call(
        conversationId: 'conversation',
        workspaceId: 'workspace',
      );

      expect(first.single.content, contains('Original'));
      expect(second.single.content, contains('Updated'));
      expect(second.single.metadata[skillCatalogSelectedRevisionsMetadataKey], {
        'research': 'r2',
      });
    });

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
        id: 'skill-1',
        slug: 'research',
        title: 'Research',
        description: '',
        content: 'Use primary sources.',
        source: .user,
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
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => [
          SkillManifest(
            slug: 'research',
            title: 'Research',
            description: 'Use primary sources.',
            revision: 'r1',
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
            id: '1',
            slug: 'slug',
            title: '<a&b"c\'d>',
            description: '',
            content: '<x&y"z\'w>',
            source: .user,
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
            id: '1',
            slug: 'slug',
            title: '<a&b"c\'d>',
            description: '',
            content: '<x&y"z\'w>',
            source: .user,
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
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => [
          SkillManifest(
            slug: 'slug',
            title: '<a&b"c\'d>',
            description: '',
            revision: 'r1',
            connectorToolIds: [],
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
          id: 'skill-1',
          slug: 'skill_one',
          title: 'Skill One',
          description: '',
          content: 'Loaded content',
          source: .user,
          kind: .template,
        );
        const duplicateAgentSkill = AvailableSkill(
          id: 'skill-1',
          slug: 'skill_one',
          title: 'Skill One Duplicate',
          description: '',
          content: 'Agent duplicate content',
          source: .user,
          kind: .template,
        );
        const appAgentSkill = AvailableSkill(
          id: 'app-skill',
          slug: 'app_skill',
          title: 'App Skill',
          description: '',
          content: 'App content',
          source: .app,
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
            languageCode: any(named: 'languageCode'),
          ),
        ).thenAnswer(
          (_) async => [
            SkillManifest(
              slug: 'skill_one',
              title: 'Skill One',
              description: '',
              revision: 'r1',
            ),
            SkillManifest(
              slug: 'app_skill',
              title: 'App Skill',
              description: '',
              revision: 'r2',
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

    testWidgets('localizes built-in agent guidance and its manifest tools', (
      tester,
    ) async {
      await tester.pumpWidget(
        const TestableApp(child: SizedBox.shrink(), startLocale: .new('es')),
      );
      final _ = await tester.pumpAndSettle();
      await _waitForSpanishTranslations(tester);

      final listSkills = _MockListAvailableSkillsUsecase();
      final listAgentSkills = _MockListConversationAgentSkillsUsecase();
      final buildManifests = _MockBuildLoadedSkillManifestsUsecase();
      final service = BuildSkillContextMessagesService(
        listSkills.call,
        listAgentSkills,
        buildManifests,
      );
      const agentsSkill = AvailableSkill(
        id: agentsSkillSlug,
        slug: agentsSkillSlug,
        title: agentsSkillTitle,
        description: '',
        content: agentsSkillContent,
        source: .app,
        kind: .native,
      );
      when(
        () => listSkills.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          filter: .catalog,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => listSkills.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          filter: .loaded,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => listAgentSkills.loadSelectedAgent(
          conversationId: 'conversation',
          workspaceId: 'workspace',
        ),
      ).thenAnswer((_) async => null);
      when(
        () => listAgentSkills.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
        ),
      ).thenAnswer((_) async => [agentsSkill]);
      when(
        () => buildManifests.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          extraSkills: any(named: 'extraSkills'),
          languageCode: 'es',
        ),
      ).thenAnswer((_) async => const []);

      final messages = await service.call(
        conversationId: 'conversation',
        workspaceId: 'workspace',
        languageCode: 'es',
      );
      final content = messages.map((message) => message.content).join('\n');

      expect(content, contains('Usa list_agents'));
      expect(content, isNot(contains('Use list_agents to find configured')));
      verify(
        () => buildManifests.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          extraSkills: any(named: 'extraSkills'),
          languageCode: 'es',
        ),
      ).called(1);
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

Future<void> _waitForSpanishTranslations(WidgetTester tester) async {
  final _ = await tester.runAsync(() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (LocaleKeys.app_skills_agents_content.trExists()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  expect(LocaleKeys.app_skills_agents_content.trExists(), isTrue);
}

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase;

class _MockListConversationAgentSkillsUsecase extends Mock
    implements ListConversationAgentSkillsUsecase;

class _MockBuildLoadedSkillManifestsUsecase extends Mock
    implements BuildLoadedSkillManifestsUsecase;
