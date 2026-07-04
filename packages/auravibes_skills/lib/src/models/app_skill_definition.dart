import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';

class AppSkillDefinition {
  const AppSkillDefinition({
    required this.identifier,
    required this.slug,
    required this.title,
    required this.description,
    required this.content,
    this.nativeTools = const [],
    this.requiresCredential = false,
    this.compatibleModelProviderIds = const [],
    this.titleKey,
    this.descriptionKey,
    this.contentKey,
  });

  final String identifier;
  final String slug;
  final String title;
  final String description;
  final String content;
  final List<AppSkillToolDefinition> nativeTools;
  final bool requiresCredential;
  final List<String> compatibleModelProviderIds;
  final String? titleKey;
  final String? descriptionKey;
  final String? contentKey;
}
