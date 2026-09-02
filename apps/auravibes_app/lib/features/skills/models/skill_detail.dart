import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AppSkillToolDefinition;

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
  // App skills may not have a persisted workspace row.
  // ignore: unnecessary-nullable
  factory fromUserSkill(SkillEntity skill) {
    return SkillDetail(
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

  bool get isUserSkill => source == SkillSource.user;
}
