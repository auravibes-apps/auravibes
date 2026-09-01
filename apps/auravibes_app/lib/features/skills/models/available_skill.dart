import 'package:auravibes_app/domain/entities/skill_entity.dart';

class const AvailableSkill({
  required final String id,
  required final String slug,
  required final String title,
  required final String description,
  required final String content,
  required final SkillSource source,
  required final SkillKind kind,
  final bool isCredentialOptional = false,
  final String? credentialDefinitionId,
});
