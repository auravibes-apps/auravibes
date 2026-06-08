import 'package:auravibes_app/domain/entities/skill_entity.dart';

class AvailableSkill {
  const AvailableSkill({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.content,
    required this.source,
    required this.kind,
    this.isCredentialOptional = false,
    this.credentialDefinitionId,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final String content;
  final SkillSource source;
  final SkillKind kind;
  final bool isCredentialOptional;
  final String? credentialDefinitionId;
}
