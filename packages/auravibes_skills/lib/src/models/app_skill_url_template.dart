import 'package:auravibes_skills/src/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_skills/src/models/skill_template_input_definition.dart';
import 'package:auravibes_skills/src/models/skill_url_template.dart';

class AppSkillUrlTemplate {
  const AppSkillUrlTemplate({
    required this.template,
    required this.inputs,
    this.credentialDefinitions = const {},
  });

  final SkillUrlTemplate template;
  final Map<String, SkillTemplateInputDefinition> inputs;
  final Map<String, SkillCredentialAttributeDefinition> credentialDefinitions;
}
