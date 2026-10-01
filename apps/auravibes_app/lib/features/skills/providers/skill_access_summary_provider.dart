import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/assess_skill_access_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_access_summary_provider.g.dart';

@riverpod
AssessSkillAccessUsecase assessSkillAccessUsecase(Ref ref, String workspaceId) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  final credentials = cloud == null
      ? ref.watch(skillCredentialsRepositoryProvider)
      : null;
  final registry = ref.watch(appSkillRegistryProvider);

  return AssessSkillAccessUsecase(
    hasCredential: (id) async {
      if (cloud != null) return (await cloud.usableCredentials(id)).isNotEmpty;
      if (credentials == null) throw StateError('Credential store unavailable');

      return (await credentials.getUsableCredentialsForDefinition(
        workspaceId: workspaceId,
        credentialDefinitionId: id,
      )).isNotEmpty;
    },
    hasAppCredential: (id) async => (await ref.read(
      appSkillCredentialCandidatesProvider(workspaceId, id).future,
    )).isNotEmpty,
    cloudStore: cloud,
    requiresAppCredential: (id) =>
        registry.getByIdentifier(id)?.requiresCredential ?? false,
  );
}

@riverpod
Future<SkillAccessSummary?> skillAccessSummary(
  Ref ref,
  String workspaceId,
  String skillId,
) async {
  final usecase = ref.watch(assessSkillAccessUsecaseProvider(workspaceId));
  final skill = await ref.watch(
    skillDetailProvider(workspaceId, skillId).future,
  );
  if (skill == null) return null;
  final tools = skill.isUserSkill
      ? await ref.watch(skillTemplateToolsProvider(workspaceId, skillId).future)
      : <Never>[];

  return await usecase.call(skill: skill, tools: tools);
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
