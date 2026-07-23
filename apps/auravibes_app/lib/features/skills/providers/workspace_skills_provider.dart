import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_settings_adapter.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_skills_provider.g.dart';

final _logger = Logger('workspace_skills');

@riverpod
Future<List<WorkspaceSkill>> workspaceSkills(
  Ref ref,
  String workspaceId,
) async {
  _logger.info('Load started: workspace=$workspaceId.');
  try {
    final session = await ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    final gateway = await ref.watch(
      cloudWorkspaceStateGatewayProvider(session).future,
    );
    if (gateway != null) {
      _logger.info('Cloud snapshot requested: workspace=$workspaceId.');
      final skills = await CloudSkillSettingsAdapter(
        gateway,
      ).watchSkills().first;
      final appSkillRegistry = ref.watch(appSkillRegistryProvider);
      final skillsById = {for (final skill in skills) skill.id: skill};
      for (final skill in appSkillRegistry.getAll()) {
        final cloudSkill = skillsById[skill.identifier];
        if (cloudSkill != null && cloudSkill.source != SkillSource.app) {
          continue;
        }
        skillsById[skill.identifier] = WorkspaceSkill(
          id: skill.identifier,
          slug: skill.slug,
          title: skill.title,
          description: skill.description,
          source: SkillSource.app,
          kind: SkillKind.native,
          isEnabled: cloudSkill?.isEnabled ?? false,
          titleKey: skill.titleKey,
          descriptionKey: skill.descriptionKey,
        );
      }
      final result = skillsById.values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      _logger.info(
        'Cloud snapshot loaded: workspace=$workspaceId, '
        'skills=${result.length}.',
      );

      return result;
    }

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
          kind: SkillKind.native,
          isEnabled: isEnabled,
          titleKey: skill.titleKey,
          descriptionKey: skill.descriptionKey,
        ),
      );
    }

    result.sort((a, b) => a.title.compareTo(b.title));
    _logger.info(
      'Local snapshot loaded: workspace=$workspaceId, skills=${result.length}.',
    );

    return result;
  } on Object catch (error, stackTrace) {
    _logger.severe('Load failed: workspace=$workspaceId.', error, stackTrace);
    rethrow;
  }
}
