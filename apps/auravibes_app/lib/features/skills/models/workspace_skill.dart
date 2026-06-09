import 'package:auravibes_app/domain/entities/skill_entity.dart';

class WorkspaceSkill {
  const WorkspaceSkill({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.source,
    required this.kind,
    required this.isEnabled,
    this.titleKey,
    this.descriptionKey,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final SkillSource source;
  final SkillKind kind;
  final bool isEnabled;
  final String? titleKey;
  final String? descriptionKey;
}
