import 'package:auravibes_skills/src/models/app_skill_tool_callback.dart';
import 'package:auravibes_skills/src/models/app_skill_url_template.dart';

class AppSkillToolDefinition {
  const AppSkillToolDefinition({
    required this.slug,
    required this.title,
    required this.description,
    this.inputJsonSchema,
    this.urlTemplate,
    this.callback,
    this.requiresCredential = false,
    this.titleKey,
    this.descriptionKey,
  });

  final String slug;
  final String title;
  final String description;
  final Map<String, dynamic>? inputJsonSchema;
  final AppSkillUrlTemplate? urlTemplate;
  final AppSkillToolCallback? callback;
  final bool requiresCredential;
  final String? titleKey;
  final String? descriptionKey;
}
