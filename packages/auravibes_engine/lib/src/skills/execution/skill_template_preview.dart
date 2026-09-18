import 'package:auravibes_engine/src/skills/execution/resolve_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_definition.dart';
import 'package:auravibes_engine/src/skills/models/url_request.dart';

class const SkillTemplateRequestPreview({
  required final String method,
  required final String url,
  required final Map<String, String> headers,
  required final Map<String, String> query,
  required final String? body,
});

SkillTemplateRequestPreview renderSkillTemplatePreview({
  required SkillTemplateDefinition definition,
  required Map<String, dynamic> inputs,
}) {
  final credentialDefinitions = {
    ...definition.credentialDefinitions,
    for (final name in _credentialNames(definition))
      name:
          definition.credentialDefinitions[name] ??
          const SkillCredentialAttributeDefinition(description: 'Credential'),
  };
  final request = const ResolveSkillUrlTemplate()(
    template: definition.request,
    inputs: inputs,
    credentials: {
      for (final name in credentialDefinitions.keys) name: '[REDACTED]',
    },
    inputDefinitions: definition.inputs,
    schema: definition.inputSchema,
    credentialDefinitions: credentialDefinitions,
  );

  return _preview(request);
}

Set<String> _credentialNames(SkillTemplateDefinition definition) {
  final source = [
    definition.request.url,
    ...definition.request.headers.values,
    ...definition.request.query.values,
    ?definition.request.body,
  ].join('\n');

  return {
    for (final match in RegExp(
      r'credential\.([A-Za-z0-9_]+)',
    ).allMatches(source))
      match.group(1)!,
  };
}

SkillTemplateRequestPreview _preview(UrlRequest request) {
  final uri = Uri.tryParse(request.url);
  return SkillTemplateRequestPreview(
    method: request.method.value,
    url: request.url,
    headers: request.headers,
    query: uri?.queryParameters ?? const {},
    body: request.body,
  );
}
