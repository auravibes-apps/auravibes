import 'package:async/async.dart';
import 'package:auravibes_skills/src/execution/resolve_skill_url_template.dart';
import 'package:auravibes_skills/src/execution/skill_http_client.dart';
import 'package:auravibes_skills/src/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_skills/src/models/skill_template_input_definition.dart';
import 'package:auravibes_skills/src/models/skill_url_template.dart';
import 'package:auravibes_skills/src/models/url_response.dart';

class RunSkillUrlTemplate {
  const RunSkillUrlTemplate(this._resolver, this._httpClient);

  final ResolveSkillUrlTemplate _resolver;
  final SkillHttpClient _httpClient;

  CancelableOperation<AppSkillUrlResponse> call({
    required SkillUrlTemplate template,
    required Map<String, dynamic> inputs,
    required Map<String, String> credentials,
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
    Map<String, SkillCredentialAttributeDefinition> credentialDefinitions =
        const {},
  }) {
    final request = _resolver(
      template: template,
      inputs: inputs,
      credentials: credentials,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );

    return _httpClient(request);
  }
}
