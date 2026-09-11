import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_settings_adapter.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_engine/auravibes_engine.dart' show AppSkillDefinition;
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_skills_provider.g.dart';

final _logger = Logger('workspace_skills');

typedef _AppendLocalAppSkillsRequest = ({
  Ref ref,
  AppSkillWorkspaceSettingsRepository settings,
  String workspaceId,
  List<WorkspaceSkill> result,
});

@riverpod
Future<List<WorkspaceSkill>> workspaceSkills(
  Ref ref,
  String workspaceId,
) async {
  _logger.info('Load started: workspace=$workspaceId.');
  try {
    return await _loadWorkspaceSkills(ref, workspaceId);
  } on Object catch (error, stackTrace) {
    _logger.severe('Load failed: workspace=$workspaceId.', error, stackTrace);
    rethrow;
  }
}

Future<List<WorkspaceSkill>> _loadWorkspaceSkills(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await _cloudGateway(ref, workspaceId);
  if (gateway != null) {
    return await _loadCloudSkills(ref, gateway, workspaceId);
  }

  return await _loadLocalSkills(ref, workspaceId);
}

Future<CloudWorkspaceStateGateway?> _cloudGateway(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );

  return await ref.watch(cloudWorkspaceStateGatewayProvider(session).future);
}

Future<List<WorkspaceSkill>> _loadCloudSkills(
  Ref ref,
  CloudWorkspaceStateGateway gateway,
  String workspaceId,
) async {
  _logger.info('Cloud snapshot requested: workspace=$workspaceId.');
  final skills = await CloudSkillSettingsAdapter(gateway).watchSkills().first;
  final result = _mergeCloudAppSkills(ref, skills);
  _logger.info(
    'Cloud snapshot loaded: workspace=$workspaceId, skills=${result.length}.',
  );

  return result;
}

List<WorkspaceSkill> _mergeCloudAppSkills(
  Ref ref,
  List<WorkspaceSkill> skills,
) {
  final skillsById = {for (final skill in skills) skill.id: skill};
  _addCloudAppSkills(ref, skillsById);
  final result = skillsById.values.toList();
  _sortSkills(result);

  return result;
}

void _addCloudAppSkills(Ref ref, Map<String, WorkspaceSkill> skillsById) {
  for (final skill in ref.watch(appSkillRegistryProvider).getAll()) {
    final cloudSkill = skillsById[skill.identifier];
    if (_isCloudUserSkill(cloudSkill)) continue;

    skillsById[skill.identifier] = _appWorkspaceSkill(
      skill,
      isEnabled: cloudSkill?.isEnabled ?? false,
    );
  }
}

bool _isCloudUserSkill(WorkspaceSkill? skill) {
  return skill != null && skill.source != SkillSource.app;
}

WorkspaceSkill _appWorkspaceSkill(
  AppSkillDefinition skill, {
  required bool isEnabled,
}) {
  return WorkspaceSkill(
    source: SkillSource.app,
    id: skill.identifier,
    slug: skill.slug,
    title: skill.title,
    description: skill.description,
    kind: .native,
    isEnabled: isEnabled,
    titleKey: skill.titleKey,
    descriptionKey: skill.descriptionKey,
  );
}

Future<List<WorkspaceSkill>> _loadLocalSkills(
  Ref ref,
  String workspaceId,
) async {
  final result = await _loadUserSkills(ref, workspaceId);
  final settings = ref.watch(appSkillWorkspaceSettingsRepositoryProvider);

  await _appendLocalAppSkills((
    ref: ref,
    settings: settings,
    workspaceId: workspaceId,
    result: result,
  ));
  _sortAndLogLocalSkills(workspaceId, result);

  return result;
}

void _sortAndLogLocalSkills(String workspaceId, List<WorkspaceSkill> skills) {
  _sortSkills(skills);
  _logLocalSkills(workspaceId, skills);
}

void _logLocalSkills(String workspaceId, List<WorkspaceSkill> skills) {
  _logger.info(
    'Local snapshot loaded: workspace=$workspaceId, skills=${skills.length}.',
  );
}

Future<List<WorkspaceSkill>> _loadUserSkills(
  Ref ref,
  String workspaceId,
) async {
  final skillsRepository = ref.watch(skillsRepositoryProvider);
  final userSkills = await skillsRepository.getWorkspaceSkills(workspaceId);

  return userSkills.map(_userWorkspaceSkill).toList();
}

WorkspaceSkill _userWorkspaceSkill(SkillEntity skill) {
  return WorkspaceSkill(
    source: SkillSource.user,
    id: skill.id,
    slug: skill.slug,
    title: skill.title,
    description: skill.description,
    kind: skill.kind,
    isEnabled: skill.isEnabled,
  );
}

Future<void> _appendLocalAppSkills(_AppendLocalAppSkillsRequest request) async {
  for (final skill in request.ref.watch(appSkillRegistryProvider).getAll()) {
    final isEnabled = await request.settings.isAppSkillEnabled(
      request.workspaceId,
      skill.identifier,
    );
    request.result.add(_appWorkspaceSkill(skill, isEnabled: isEnabled));
  }
}

void _sortSkills(List<WorkspaceSkill> skills) {
  skills.sort((a, b) => a.title.compareTo(b.title));
}
