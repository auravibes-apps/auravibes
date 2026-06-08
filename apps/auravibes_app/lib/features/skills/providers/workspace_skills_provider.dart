import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_skills_provider.g.dart';

@riverpod
Future<List<WorkspaceSkill>> workspaceSkills(
  Ref ref,
  String workspaceId,
) async {
  final skillsRepository = ref.watch(skillsRepositoryProvider);
  final appSkillSettings = ref.watch(
    appSkillWorkspaceSettingsRepositoryProvider,
  );
  final appSkillRegistry = ref.watch(appSkillRegistryProvider);
  final userSkills = await skillsRepository.getWorkspaceSkills(workspaceId);
  final result = <WorkspaceSkill>[
    for (final skill in userSkills)
      WorkspaceSkill(
        id: skill.id,
        slug: skill.slug,
        title: skill.title,
        description: skill.description,
        source: SkillSource.user,
        kind: skill.kind,
        isEnabled: skill.isEnabled,
      ),
  ];

  for (final skill in appSkillRegistry.getAll()) {
    final isEnabled = await appSkillSettings.isAppSkillEnabled(
      workspaceId,
      skill.identifier,
    );
    result.add(
      WorkspaceSkill(
        id: skill.identifier,
        slug: skill.slug,
        title: skill.title,
        description: skill.description,
        source: SkillSource.app,
        kind: skill.kind,
        isEnabled: isEnabled,
        titleKey: skill.titleKey,
        descriptionKey: skill.descriptionKey,
      ),
    );
  }

  result.sort((a, b) => a.title.compareTo(b.title));
  return result;
}
