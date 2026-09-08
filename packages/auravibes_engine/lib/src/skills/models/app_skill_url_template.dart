import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';

class const AppSkillUrlTemplate({
  required final SkillUrlTemplate template,
  required final Map<String, SkillTemplateInputDefinition> inputs,
  final Map<String, SkillCredentialAttributeDefinition> credentialDefinitions =
      const {},
});
