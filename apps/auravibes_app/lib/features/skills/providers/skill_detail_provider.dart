import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_detail_provider.g.dart';

@riverpod
Future<SkillDetail?> skillDetail(
  Ref ref,
  String workspaceId,
  String skillId,
) async {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  final sourceSkill = cloud != null
      ? await cloud.skill(skillId)
      : await ref.watch(skillsRepositoryProvider).getSkillById(skillId);
  final appSkill = ref.watch(appSkillRegistryProvider).getByIdentifier(skillId);
  final isNativeAppRecord =
      sourceSkill?.source == SkillSource.app &&
      sourceSkill?.kind == SkillKind.native &&
      appSkill != null;
  if (sourceSkill != null && !isNativeAppRecord) {
    return SkillDetail.fromUserSkill(sourceSkill);
  }
  if (appSkill == null) return null;

  final isEnabled =
      sourceSkill?.isEnabled ??
      (cloud != null
          ? await cloud.isAppSkillEnabled(appSkill.identifier)
          : await ref
                .watch(appSkillWorkspaceSettingsRepositoryProvider)
                .isAppSkillEnabled(workspaceId, appSkill.identifier));

  return SkillDetail(
    id: appSkill.identifier,
    workspaceId: workspaceId,
    source: SkillSource.app,
    kind: SkillKind.native,
    title: sourceSkill?.title ?? appSkill.title,
    slug: sourceSkill?.slug ?? appSkill.slug,
    description: sourceSkill?.description ?? appSkill.description,
    content: sourceSkill?.content ?? appSkill.content,
    isEnabled: isEnabled,
    isCredentialOptional: sourceSkill?.isCredentialOptional ?? false,
    appTools: appSkill.nativeTools,
    titleKey: sourceSkill == null ? appSkill.titleKey : null,
    descriptionKey: sourceSkill == null ? appSkill.descriptionKey : null,
    contentKey: sourceSkill == null ? appSkill.contentKey : null,
  );
}
