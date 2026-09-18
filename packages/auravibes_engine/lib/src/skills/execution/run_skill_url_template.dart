import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/execution/resolve_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/execution/skill_http_client.dart';
import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/url_response.dart';

/// Executes a versioned declarative skill definition.
class const SkillTemplateExecutor(
  final ResolveSkillUrlTemplate _resolver,
  final SkillHttpClient _httpClient,
) {
  // ignore: unnecessary-nullable, explicit null selects legacy/fallback execution inputs.
  CancelableOperation<UrlResponse> call({
    required Map<String, dynamic> inputs,
    required Map<String, String> credentials,
    SkillTemplateDefinition? definition,
    SkillUrlTemplate? template,
    Map<String, SkillTemplateInputDefinition>? inputDefinitions,
    Map<String, dynamic>? schema,
    Map<String, SkillCredentialAttributeDefinition> credentialDefinitions =
        const {},
  }) {
    final resolvedDefinition = definition;
    final resolvedTemplate = resolvedDefinition?.request ?? template;
    final resolvedInputDefinitions =
        resolvedDefinition?.inputs ?? inputDefinitions;
    if (resolvedTemplate == null || resolvedInputDefinitions == null) {
      throw ArgumentError('A skill template definition is required.');
    }
    final request = _resolver(
      template: resolvedTemplate,
      inputs: inputs,
      credentials: credentials,
      inputDefinitions: resolvedInputDefinitions,
      schema: schema ?? resolvedDefinition?.inputSchema,
      credentialDefinitions: {
        ...credentialDefinitions,
        ...?resolvedDefinition?.credentialDefinitions,
      },
    );

    return _httpClient(request);
  }
}
