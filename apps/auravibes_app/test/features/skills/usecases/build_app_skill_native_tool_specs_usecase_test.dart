import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/skill_tool_slugs.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase;

void main() {
  test('loaded service Skills do not add Connector tool specs', () async {
    final listUsecase = _MockListAvailableSkillsUsecase();
    final usecase = BuildAppSkillNativeToolSpecsUsecase(
      (_) => listUsecase,
      null,
    );
    when(
      () => listUsecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .loaded,
      ),
    ).thenAnswer((_) async => [_appSkill('brave')]);

    final specs = await usecase.call(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(specs, isEmpty);
  });

  test(
    'loaded Skills manager exposes its native management commands',
    () async {
      final listUsecase = _MockListAvailableSkillsUsecase();
      final usecase = BuildAppSkillNativeToolSpecsUsecase(
        (_) => listUsecase,
        null,
      );
      when(
        () => listUsecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          filter: .loaded,
        ),
      ).thenAnswer((_) async => [_appSkill(SkillToolSlugs.skillsManager)]);

      final specs = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(
        specs.map((spec) => spec.name),
        contains('skill__app_native__skills_manager__list_user_skills'),
      );
    },
  );

  test('loaded Agents Skill exposes native agent execution', () async {
    final listUsecase = _MockListAvailableSkillsUsecase();
    final usecase = BuildAppSkillNativeToolSpecsUsecase(
      (_) => listUsecase,
      null,
    );
    when(
      () => listUsecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        filter: .loaded,
      ),
    ).thenAnswer((_) async => [_appSkill(agentsSkillSlug)]);

    final specs = await usecase.call(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(specs.map((spec) => spec.name), [
      'skill__app_native__agents__run_sub_agent',
    ]);
  });
}

AvailableSkill _appSkill(String slug) => AvailableSkill(
  id: slug,
  slug: slug,
  title: slug,
  description: '',
  content: '',
  source: .app,
  kind: .native,
);
