import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/assess_skill_access_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_access_summary_provider.g.dart';

typedef _AccessUsecaseCallbacks = ({
  Future<bool> Function(String definitionId) hasCredential,
  Future<bool> Function(String skillId) hasAppCredential,
  CloudSkillStore? cloudStore,
  bool Function(String skillId) requiresAppCredential,
});
typedef _GetLocalCredentials<T> = Future<List<T>> Function({
  required String workspaceId,
  required String credentialDefinitionId,
});
typedef _AccessUsecaseSources<T> = ({
  Ref ref,
  String workspaceId,
  CloudSkillStore? cloud,
  _GetLocalCredentials<T>? getLocalCredentials,
  AppSkillRegistry registry,
});

@riverpod
AssessSkillAccessUsecase assessSkillAccessUsecase(
  Ref ref,
  String workspaceId,
) => _createAccessUsecase(ref, workspaceId);

AssessSkillAccessUsecase _createAccessUsecase(Ref ref, String workspaceId) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  final credentials = cloud == null
      ? ref.watch(skillCredentialsRepositoryProvider)
      : null;
  final sources = (
    ref: ref,
    workspaceId: workspaceId,
    cloud: cloud,
    getLocalCredentials: credentials?.getUsableCredentialsForDefinition,
    registry: ref.watch(appSkillRegistryProvider),
  );

  return _makeAssessSkillAccessUsecase(_accessUsecaseCallbacks(sources));
}

_AccessUsecaseCallbacks _accessUsecaseCallbacks<T>(
  _AccessUsecaseSources<T> sources,
) => (
  hasCredential: (id) => _hasCredential(
    sources.cloud,
    sources.workspaceId,
    id,
    sources.getLocalCredentials,
  ),
  hasAppCredential: _appCredentialReader(sources.ref, sources.workspaceId),
  cloudStore: sources.cloud,
  requiresAppCredential: _appCredentialRequirement(sources.registry),
);

AssessSkillAccessUsecase _makeAssessSkillAccessUsecase(
  _AccessUsecaseCallbacks callbacks,
) => AssessSkillAccessUsecase(
  hasCredential: callbacks.hasCredential,
  hasAppCredential: callbacks.hasAppCredential,
  cloudStore: callbacks.cloudStore,
  requiresAppCredential: callbacks.requiresAppCredential,
);

Future<bool> Function(String skillId) _appCredentialReader(
  Ref ref,
  String workspaceId,
) =>
    (skillId) async => (await ref.read(
      appSkillCredentialCandidatesProvider(workspaceId, skillId).future,
    )).isNotEmpty;

bool Function(String skillId) _appCredentialRequirement(
  AppSkillRegistry registry,
) =>
    (skillId) => registry.getByIdentifier(skillId)?.requiresCredential ?? false;

@riverpod
Future<SkillAccessSummary?> skillAccessSummary(
  Ref ref,
  String workspaceId,
  String skillId,
) => _loadSkillAccessSummary(ref, workspaceId, skillId);

Future<SkillAccessSummary?> _loadSkillAccessSummary(
  Ref ref,
  String workspaceId,
  String skillId,
) async {
  final usecase = ref.watch(assessSkillAccessUsecaseProvider(workspaceId));
  final skill = await ref.watch(
    skillDetailProvider(workspaceId, skillId).future,
  );
  if (skill == null) return null;
  final tools = await _skillTools(ref, workspaceId, skillId, skill.isUserSkill);

  return await usecase.call(skill: skill, tools: tools);
}

Future<List<SkillTemplateToolEntity>> _skillTools(
  Ref ref,
  String workspaceId,
  String skillId,
  bool isUserSkill,
) async {
  if (!isUserSkill) return const [];

  return await ref.watch(
    skillTemplateToolsProvider(workspaceId, skillId).future,
  );
}

Future<bool> _hasCredential<T>(
  CloudSkillStore? cloud,
  String workspaceId,
  String definitionId,
  _GetLocalCredentials<T>? getLocalCredentials,
) async {
  if (cloud != null) {
    return (await cloud.usableCredentials(definitionId)).isNotEmpty;
  }
  if (getLocalCredentials == null) {
    throw StateError('Credential store unavailable');
  }

  return (await getLocalCredentials(
    workspaceId: workspaceId,
    credentialDefinitionId: definitionId,
  )).isNotEmpty;
}

@riverpod
Future<List<AppSkillCredentialCandidate>> appSkillCredentialCandidates(
  Ref ref,
  String workspaceId,
  String skillId,
) async {
  final skill = ref.watch(appSkillRegistryProvider).getByIdentifier(skillId);
  if (skill == null) throw StateError('Skill metadata unavailable');

  return await ref
      .watch(listAppSkillCredentialCandidatesUsecaseProvider)
      .call(workspaceId: workspaceId, skill: skill);
}
