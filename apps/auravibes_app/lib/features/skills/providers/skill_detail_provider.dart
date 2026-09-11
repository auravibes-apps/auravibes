import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_engine/auravibes_engine.dart' show AppSkillDefinition;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_detail_provider.g.dart';

typedef _EnabledStateRequest = ({
  Ref ref,
  CloudSkillStore? cloud,
  SkillEntity? sourceSkill,
  String skillId,
  String workspaceId,
});

typedef _SkillDetailInput = ({Ref ref, String skillId, String workspaceId});

typedef _SkillDetailRequestInput = ({
  _SkillDetailInput input,
  CloudSkillStore? cloud,
  SkillEntity? sourceSkill,
  AppSkillDefinition? appSkill,
});

typedef _NativeSkillText = ({
  String title,
  String slug,
  String description,
  String content,
});

typedef _NativeSkillKeys = ({
  String? titleKey,
  String? descriptionKey,
  String? contentKey,
});

typedef _SkillDetailRequest = ({
  Ref ref,
  CloudSkillStore? cloud,
  SkillEntity? sourceSkill,
  AppSkillDefinition? appSkill,
  String skillId,
  String workspaceId,
});

@riverpod
Future<SkillDetail?> skillDetail(
  Ref ref,
  String workspaceId,
  String skillId,
) async {
  return await _buildSkillDetail(
    await _loadSkillDetailRequest((
      ref: ref,
      skillId: skillId,
      workspaceId: workspaceId,
    )),
  );
}

Future<_SkillDetailRequest> _loadSkillDetailRequest(
  _SkillDetailInput request,
) async => _skillDetailRequest(await _loadSkillDetailInputs(request));

Future<_SkillDetailRequestInput> _loadSkillDetailInputs(
  _SkillDetailInput request,
) async {
  final cloud = request.ref.watch(cloudSkillStoreProvider(request.workspaceId));
  final sourceSkill = await _loadSourceSkill(
    request.ref,
    cloud,
    request.skillId,
  );

  return _skillDetailInput(request, cloud, sourceSkill);
}

_SkillDetailRequestInput _skillDetailInput(
  _SkillDetailInput input,
  CloudSkillStore? cloud,
  SkillEntity? sourceSkill,
) => (
  input: input,
  cloud: cloud,
  sourceSkill: sourceSkill,
  appSkill: _appSkill(input.ref, input.skillId),
);

AppSkillDefinition? _appSkill(Ref ref, String skillId) =>
    ref.watch(appSkillRegistryProvider).getByIdentifier(skillId);

_SkillDetailRequest _skillDetailRequest(_SkillDetailRequestInput request) {
  final input = request.input;

  return (
    ref: input.ref,
    cloud: request.cloud,
    sourceSkill: request.sourceSkill,
    appSkill: request.appSkill,
    skillId: input.skillId,
    workspaceId: input.workspaceId,
  );
}

Future<SkillDetail?> _buildSkillDetail(_SkillDetailRequest request) async {
  final sourceSkill = request.sourceSkill;
  final appSkill = request.appSkill;
  if (sourceSkill != null && !_isNativeAppRecord(sourceSkill, appSkill)) {
    return SkillDetail.fromUserSkill(sourceSkill);
  }

  return await _buildNativeSkillDetailIfAvailable(request);
}

Future<SkillDetail?> _buildNativeSkillDetailIfAvailable(
  _SkillDetailRequest request,
) async {
  final appSkill = request.appSkill;
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

SkillDetailNativeRequest _nativeSkillDetailRequest(
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
) {
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
  final cloud = request.cloud;
  if (cloud != null) return await cloud.isAppSkillEnabled(request.skillId);

  return await request.ref
      .watch(appSkillWorkspaceSettingsRepositoryProvider)
      .isAppSkillEnabled(request.workspaceId, request.skillId);
}

SkillDetail _buildNativeSkillDetail(SkillDetailNativeRequest request) {
  return _nativeSkillDetailBuilder(request);
}

SkillDetail _nativeSkillDetailBuilder(SkillDetailNativeRequest request) {
  final values = _nativeSkillValues(request.appSkill, request.sourceSkill);

  return SkillDetail.fromNative(request, values);
}

SkillDetailNativeValues _nativeSkillValues(
  AppSkillDefinition appSkill,
  SkillEntity? sourceSkill,
) {
  final text = _nativeSkillText(appSkill, sourceSkill);
  final keys = _nativeSkillKeys(appSkill, sourceSkill);

  return _nativeSkillValuesFrom(
    text,
    keys,
    _nativeSkillCredentialOptional(sourceSkill),
  );
}

SkillDetailNativeValues _nativeSkillValuesFrom(
  _NativeSkillText text,
  _NativeSkillKeys keys,
  bool isCredentialOptional,
) => (
  title: text.title,
  slug: text.slug,
  description: text.description,
  content: text.content,
  isCredentialOptional: isCredentialOptional,
  titleKey: keys.titleKey,
  descriptionKey: keys.descriptionKey,
  contentKey: keys.contentKey,
);

_NativeSkillText _nativeSkillText(
  AppSkillDefinition appSkill,
  SkillEntity? sourceSkill,
) {
  if (sourceSkill != null) return _sourceSkillText(sourceSkill);

  return _appSkillText(appSkill);
}

_NativeSkillText _sourceSkillText(SkillEntity skill) => (
  title: skill.title,
  slug: skill.slug,
  description: skill.description,
  content: skill.content,
);

_NativeSkillText _appSkillText(AppSkillDefinition skill) => (
  title: skill.title,
  slug: skill.slug,
  description: skill.description,
  content: skill.content,
);

bool _nativeSkillCredentialOptional(SkillEntity? sourceSkill) =>
    sourceSkill?.isCredentialOptional ?? false;

_NativeSkillKeys _nativeSkillKeys(
  AppSkillDefinition appSkill,
  SkillEntity? sourceSkill,
) => (
  titleKey: sourceSkill == null ? appSkill.titleKey : null,
  descriptionKey: sourceSkill == null ? appSkill.descriptionKey : null,
  contentKey: sourceSkill == null ? appSkill.contentKey : null,
);
