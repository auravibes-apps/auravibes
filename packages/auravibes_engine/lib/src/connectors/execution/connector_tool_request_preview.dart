import 'package:auravibes_engine/src/connectors/execution/resolve_connector_request_template.dart';
import 'package:auravibes_engine/src/connectors/models/connector_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_request_definition.dart';
import 'package:auravibes_engine/src/connectors/models/url_request.dart';

class const ConnectorToolRequestPreview({
  required final String method,
  required final String url,
  required final Map<String, String> headers,
  required final Map<String, String> query,
  required final String? body,
});

ConnectorToolRequestPreview renderConnectorToolRequestPreview({
  required ConnectorToolRequestDefinition definition,
  required Map<String, dynamic> inputs,
}) {
  final credentialDefinitions = {
    ...definition.credentialDefinitions,
    for (final name in _credentialNames(definition))
      name:
          definition.credentialDefinitions[name] ??
          const ConnectorCredentialAttributeDefinition(description: 'Credential'),
  };
  final request = const ResolveConnectorRequestTemplate()(
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

Set<String> _credentialNames(ConnectorToolRequestDefinition definition) {
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

ConnectorToolRequestPreview _preview(UrlRequest request) {
  final uri = Uri.tryParse(request.url);
  return ConnectorToolRequestPreview(
    method: request.method.value,
    url: request.url,
    headers: request.headers,
    query: uri?.queryParameters ?? const {},
    body: request.body,
  );
}
