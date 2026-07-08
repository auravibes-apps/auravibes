import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';

const defaultAppSkillToolInputJsonSchema = {
  'type': 'object',
  'properties': <String, Object?>{},
  'additionalProperties': false,
};

class AppSkillToolDefinition {
  const AppSkillToolDefinition({
    required this.slug,
    required this.title,
    required this.description,
    this.inputJsonSchema = defaultAppSkillToolInputJsonSchema,
    this.urlTemplate,
    this.callback,
    this.requiresCredential = false,
    this.titleKey,
    this.descriptionKey,
  }) : assert(
         urlTemplate == null || callback == null,
         'AppSkillToolDefinition cannot use both urlTemplate and callback.',
       );

  final String slug;
  final String title;
  final String description;
  final Map<String, dynamic> inputJsonSchema;
  final AppSkillUrlTemplate? urlTemplate;
  final AppSkillToolCallback? callback;
  final bool requiresCredential;
  final String? titleKey;
  final String? descriptionKey;
}
