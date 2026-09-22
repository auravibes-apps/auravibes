import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_definition.dart';

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
  final bool requiresCredential = false,
  final AppSkillJobOperation? jobOperation,
  final String? titleKey,
  final String? descriptionKey,
}) {
  SkillTemplateDefinition? get definition {
    final template = urlTemplate;
    return template == null
        ? null
        : SkillTemplateDefinition(
            request: template.template,
            inputs: template.inputs,
            credentialDefinitions: template.credentialDefinitions,
            inputSchemaOverride: Map<String, Object?>.from(inputJsonSchema),
          );
  }
}

enum AppSkillJobOperation { create, status, cancel, output }
