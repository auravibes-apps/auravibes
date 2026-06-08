import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/services/skills/models/app_skill_tool_definition.dart';

class SkillDetail {
  const SkillDetail({
    required this.id,
    required this.workspaceId,
    required this.source,
    required this.kind,
    required this.title,
    required this.slug,
    required this.description,
    required this.content,
    required this.isEnabled,
    required this.isCredentialOptional,
    this.credentialDefinitionId,
    this.appTools = const [],
    this.titleKey,
    this.descriptionKey,
    this.contentKey,
  });

  factory SkillDetail.fromUserSkill(SkillEntity skill) {
    return SkillDetail(
      id: skill.id,
      workspaceId: skill.workspaceId,
      source: skill.source,
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

  final String id;
  final String? workspaceId;
  final SkillSource source;
  final SkillKind kind;
  final String title;
  final String slug;
  final String description;
  final String content;
  final bool isEnabled;
  final bool isCredentialOptional;
  final String? credentialDefinitionId;
  final List<AppSkillToolDefinition> appTools;
  final String? titleKey;
  final String? descriptionKey;
  final String? contentKey;

  bool get isUserSkill => source == SkillSource.user;
}
