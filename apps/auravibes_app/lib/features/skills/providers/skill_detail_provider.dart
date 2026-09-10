import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:auravibes_engine/auravibes_engine.dart' show AppSkillDefinition;

part 'skill_detail_provider.g.dart';

typedef _EnabledStateRequest = ({
  Ref ref,
  CloudSkillStore? cloud,
  SkillEntity? sourceSkill,
  String skillId,
  String workspaceId,
});

typedef _SkillDetailRequest = ({
  Ref ref,
  CloudSkillStore? cloud,
  SkillEntity? sourceSkill,
  AppSkillDefinition? appSkill,
  String skillId,
  String workspaceId,
});

typedef _NativeSkillDetailRequest = ({
  AppSkillDefinition appSkill,
  SkillEntity? sourceSkill,
  String workspaceId,
  bool isEnabled,
});

@riverpod
Future<SkillDetail?> skillDetail(
  Ref ref,
  String workspaceId,
  String skillId,
) async {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  final sourceSkill = await _loadSourceSkill(ref, cloud, skillId);
  final appSkill = ref.watch(appSkillRegistryProvider).getByIdentifier(skillId);
  return _buildSkillDetail((
    ref: ref,
    cloud: cloud,
    sourceSkill: sourceSkill,
    appSkill: appSkill,
    skillId: skillId,
    workspaceId: workspaceId,
  ));
}

Future<SkillDetail?> _buildSkillDetail(_SkillDetailRequest request) async {
  final sourceSkill = request.sourceSkill;
  final appSkill = request.appSkill;
  if (sourceSkill != null && !_isNativeAppRecord(sourceSkill, appSkill)) {
    return SkillDetail.fromUserSkill(sourceSkill);
  }
  if (appSkill == null) return null;

  final isEnabled = await _loadEnabledState(
    _enabledStateRequest(request, appSkill),
  );
  return _buildNativeSkillDetail(
    _nativeSkillDetailRequest(request, appSkill, isEnabled),
  );
}

_EnabledStateRequest _enabledStateRequest(
  _SkillDetailRequest request,
  AppSkillDefinition appSkill,
) => (
  ref: request.ref,
  cloud: request.cloud,
  sourceSkill: request.sourceSkill,
  skillId: appSkill.identifier,
  workspaceId: request.workspaceId,
);

_NativeSkillDetailRequest _nativeSkillDetailRequest(
  _SkillDetailRequest request,
  AppSkillDefinition appSkill,
  bool isEnabled,
) => (
  appSkill: appSkill,
  sourceSkill: request.sourceSkill,
  workspaceId: request.workspaceId,
  isEnabled: isEnabled,
);

Future<SkillEntity?> _loadSourceSkill(
  Ref ref,
  CloudSkillStore? cloud,
  String skillId,
) async {
  if (cloud != null) return cloud.skill(skillId);
  return ref.watch(skillsRepositoryProvider).getSkillById(skillId);
}

bool _isNativeAppRecord(
  SkillEntity sourceSkill,
  AppSkillDefinition? appSkill,
) =>
    sourceSkill.source == SkillSource.app &&
    sourceSkill.kind == SkillKind.native &&
    appSkill != null;

Future<bool> _loadEnabledState(_EnabledStateRequest request) async {
  final sourceEnabled = request.sourceSkill?.isEnabled;
  if (sourceEnabled != null) return sourceEnabled;
  if (request.cloud != null) {
    return request.cloud!.isAppSkillEnabled(request.skillId);
  }
  return request.ref
      .watch(appSkillWorkspaceSettingsRepositoryProvider)
      .isAppSkillEnabled(request.workspaceId, request.skillId);
}

SkillDetail _buildNativeSkillDetail(_NativeSkillDetailRequest request) {
  return _nativeSkillDetailBuilder(request);
}

final SkillDetail Function(_NativeSkillDetailRequest request)
_nativeSkillDetailBuilder = (request) {
  final values = _nativeSkillValues(request.appSkill, request.sourceSkill);
  return SkillDetail(
    source: SkillSource.app,
    id: request.appSkill.identifier,
    workspaceId: request.workspaceId,
    kind: .native,
    title: values.title,
    slug: values.slug,
    description: values.description,
    content: values.content,
    isEnabled: request.isEnabled,
    isCredentialOptional: values.isCredentialOptional,
    appTools: request.appSkill.nativeTools,
    titleKey: values.titleKey,
    descriptionKey: values.descriptionKey,
    contentKey: values.contentKey,
  );
};

({
  String title,
  String slug,
  String description,
  String content,
  bool isCredentialOptional,
  String? titleKey,
  String? descriptionKey,
  String? contentKey,
})
_nativeSkillValues(AppSkillDefinition appSkill, SkillEntity? sourceSkill) {
  final text = _nativeSkillText(appSkill, sourceSkill);
  final keys = _nativeSkillKeys(appSkill, sourceSkill);
  return (
    title: text.title,
    slug: text.slug,
    description: text.description,
    content: text.content,
    isCredentialOptional: _nativeSkillCredentialOptional(sourceSkill),
    titleKey: keys.titleKey,
    descriptionKey: keys.descriptionKey,
    contentKey: keys.contentKey,
  );
}

({String title, String slug, String description, String content})
_nativeSkillText(AppSkillDefinition appSkill, SkillEntity? sourceSkill) => (
  title: sourceSkill?.title ?? appSkill.title,
  slug: sourceSkill?.slug ?? appSkill.slug,
  description: sourceSkill?.description ?? appSkill.description,
  content: sourceSkill?.content ?? appSkill.content,
);

bool _nativeSkillCredentialOptional(SkillEntity? sourceSkill) =>
    sourceSkill?.isCredentialOptional ?? false;

({String? titleKey, String? descriptionKey, String? contentKey})
_nativeSkillKeys(AppSkillDefinition appSkill, SkillEntity? sourceSkill) => (
  titleKey: sourceSkill == null ? appSkill.titleKey : null,
  descriptionKey: sourceSkill == null ? appSkill.descriptionKey : null,
  contentKey: sourceSkill == null ? appSkill.contentKey : null,
);
