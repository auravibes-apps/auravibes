import 'package:auravibes_app/domain/entities/skill_entity.dart';

class const WorkspaceSkill({
  required final String id,
  required final String slug,
  required final String title,
  required final String description,
  required final SkillSource source,
  required final SkillKind kind,
  required final bool isEnabled,
  final String? titleKey,
  final String? descriptionKey,
});
