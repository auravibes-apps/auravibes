import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';

const Map<String, dynamic> defaultAppSkillToolInputJsonSchema = {
  'type': 'object',
  'properties': <String, Object?>{},
  'additionalProperties': false,
};

class const AppSkillToolDefinition({
  required final String slug,
  required final String title,
  required final String description,
  final Map<String, dynamic> inputJsonSchema =
      defaultAppSkillToolInputJsonSchema,
  final AppSkillUrlTemplate? urlTemplate,
  final AppSkillToolCallback? callback,
  final bool requiresCredential = false,
  final String? titleKey,
  final String? descriptionKey,
}) {
  this
    : assert(
        urlTemplate == null || callback == null,
        'AppSkillToolDefinition cannot use both urlTemplate and callback.',
      );
}
