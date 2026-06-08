import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/services/skills/models/app_skill_tool_definition.dart';

class AppSkillDefinition {
  // Null means the app skill uses literal text instead of localization keys.
  // ignore: unnecessary-nullable
  const AppSkillDefinition({
    required this.identifier,
    required this.slug,
    required this.title,
    required this.description,
    required this.content,
    required this.kind,
    this.nativeTools = const [],
    this.titleKey,
    this.descriptionKey,
    this.contentKey,
  });

  final String identifier;
  final String slug;
  final String title;
  final String description;
  final String content;
  final SkillKind kind;
  final List<AppSkillToolDefinition> nativeTools;
  final String? titleKey;
  final String? descriptionKey;
  final String? contentKey;
}
