import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase {}

class _MockBuildSkillTemplateToolSpecsUsecase extends Mock
    implements BuildSkillTemplateToolSpecsUsecase {}

class _MockBuildAppSkillNativeToolSpecsUsecase extends Mock
    implements BuildAppSkillNativeToolSpecsUsecase {}

void main() {
  test(
    'groups loaded materialized tools by skill and emits stable revision',
    () async {
      final listSkills = _MockListAvailableSkillsUsecase();
      final templateSpecs = _MockBuildSkillTemplateToolSpecsUsecase();
      final nativeSpecs = _MockBuildAppSkillNativeToolSpecsUsecase();
      final usecase = BuildLoadedSkillManifestsUsecase(
        (_) => listSkills,
        templateSpecs,
        nativeSpecs,
      );
      when(
        () => listSkills.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer(
        (_) async => const [
          AvailableSkill(
            source: SkillSource.user,
            id: 'skill-1',
            slug: 'research',
            title: 'Research',
            description: 'Research sources.',
            content: 'Use primary sources.',
            kind: SkillKind.template,
          ),
        ],
      );
      when(
        () => templateSpecs.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer(
        (_) async => [
          ToolSpec(
            name: 'skill__user__research__search',
            description: 'Search sources.',
            inputJsonSchema: const {'type': 'object'},
          ),
          ToolSpec(
            name: 'skill__user__research__fetch',
            description: 'Fetch a source.',
            inputJsonSchema: const {'type': 'object'},
          ),
        ],
      );
      when(
        () => nativeSpecs.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer((_) async => const []);

      final manifests = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(manifests.single.slug, 'research');
      expect(manifests.single.tools.map((tool) => tool.name), [
        'fetch',
        'search',
      ]);
      expect(manifests.single.revision, isNotEmpty);
      expect(manifests.single.instructions, 'Use primary sources.');
    },
  );
}
