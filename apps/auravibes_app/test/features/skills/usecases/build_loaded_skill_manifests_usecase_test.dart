import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase;

void main() {
  test(
    'loads Skill guidance with Connector tool IDs and no tool definitions',
    () async {
      final listSkills = _MockListAvailableSkillsUsecase();
      final usecase = BuildLoadedSkillManifestsUsecase((_) => listSkills);
      when(
        () => listSkills.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loaded,
        ),
      ).thenAnswer(
        (_) async => const [
          AvailableSkill(
            id: 'skill-1',
            slug: 'crm',
            title: 'CRM',
            description: 'Use Notion for CRM.',
            content: 'Search before creating records.',
            source: .user,
            kind: .template,
            connectorToolIds: [
              'connector/notion/search',
              'connector/notion/create',
            ],
          ),
        ],
      );

      final manifests = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(manifests.single.slug, 'crm');
      expect(manifests.single.connectorToolIds, [
        'connector/notion/create',
        'connector/notion/search',
      ]);
      expect(manifests.single.toJson(), isNot(contains('tools')));
      expect(manifests.single.revision, isNotEmpty);
    },
  );
}
