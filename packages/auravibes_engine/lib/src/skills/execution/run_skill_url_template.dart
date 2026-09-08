import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/execution/resolve_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/execution/skill_http_client.dart';
import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/url_response.dart';

class const RunSkillUrlTemplate(
  final ResolveSkillUrlTemplate _resolver,
  final SkillHttpClient _httpClient,
) {
  CancelableOperation<UrlResponse> call({
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
