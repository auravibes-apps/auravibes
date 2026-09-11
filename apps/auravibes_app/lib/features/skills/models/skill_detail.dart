import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AppSkillDefinition, AppSkillToolDefinition;

typedef SkillDetailNativeValues = ({
  String title,
  String slug,
  String description,
  String content,
  bool isCredentialOptional,
  String? titleKey,
  String? descriptionKey,
  String? contentKey,
});

typedef SkillDetailNativeRequest = ({
  AppSkillDefinition appSkill,
  SkillEntity? sourceSkill,
  String workspaceId,
  bool isEnabled,
});

class const SkillDetail({
  required final String id,
  required final String? workspaceId,
  required final SkillSource source,
  required final SkillKind kind,
  required final String title,
  required final String slug,
  required final String description,
  required final String content,
  required final bool isEnabled,
  required final bool isCredentialOptional,
  final String? credentialDefinitionId,
  final List<AppSkillToolDefinition> appTools = const [],
  final String? titleKey,
  final String? descriptionKey,
  final String? contentKey,
}) {
  factory fromNative(
    SkillDetailNativeRequest request,
    SkillDetailNativeValues values,
  ) = _NativeSkillDetail;

  bool get isUserSkill => source == SkillSource.user;

  // App skills may not have a persisted workspace row.
  static SkillDetail fromUserSkill(SkillEntity skill) =>
      _UserSkillSkillDetail(skill);

  bool hasSource(SkillSource value) => source == value;
}

class _NativeSkillDetail extends SkillDetail {
  new(SkillDetailNativeRequest request, SkillDetailNativeValues values)
    : super(
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
}

class _UserSkillSkillDetail extends SkillDetail {
  new(SkillEntity skill)
    : super(
        source: skill.source,
        id: skill.id,
        workspaceId: skill.workspaceId,
        kind: skill.kind,
        title: skill.title,
        slug: skill.slug,
        description: skill.description,
        content: skill.content,
        isEnabled: skill.isEnabled,
        isCredentialOptional: skill.isCredentialOptional,
        credentialDefinitionId: skill.credentialDefinitionId,
      );
}
