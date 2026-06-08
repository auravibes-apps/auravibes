import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_detail_provider.g.dart';

@riverpod
Future<SkillDetail?> skillDetail(
  Ref ref,
  String workspaceId,
  String skillId,
) async {
  final skillsRepository = ref.watch(skillsRepositoryProvider);
  final userSkill = await skillsRepository.getSkillById(skillId);
  if (userSkill != null && userSkill.workspaceId == workspaceId) {
    return SkillDetail.fromUserSkill(userSkill);
  }

  final appSkillRegistry = ref.watch(appSkillRegistryProvider);
  final appSkills = appSkillRegistry.getAll().where(
    (skill) => skill.identifier == skillId,
  );
  final appSkill = appSkills.firstOrNull;
  if (appSkill == null) return null;

  final appSkillSettings = ref.watch(
    appSkillWorkspaceSettingsRepositoryProvider,
  );
  final isEnabled = await appSkillSettings.isAppSkillEnabled(
    workspaceId,
    appSkill.identifier,
  );

  return SkillDetail(
    id: appSkill.identifier,
    workspaceId: workspaceId,
    source: SkillSource.app,
    kind: appSkill.kind,
    title: appSkill.title,
    slug: appSkill.slug,
    description: appSkill.description,
    content: appSkill.content,
    isEnabled: isEnabled,
    isCredentialOptional: false,
    appTools: appSkill.nativeTools,
    titleKey: appSkill.titleKey,
    descriptionKey: appSkill.descriptionKey,
    contentKey: appSkill.contentKey,
  );
}
