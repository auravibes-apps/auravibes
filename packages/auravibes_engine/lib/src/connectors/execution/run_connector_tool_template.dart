import 'package:async/async.dart';
import 'package:auravibes_engine/src/connectors/execution/resolve_connector_request_template.dart';
import 'package:auravibes_engine/src/connectors/execution/connector_http_client.dart';
import 'package:auravibes_engine/src/connectors/execution/connector_response_decoder.dart';
import 'package:auravibes_engine/src/connectors/models/connector_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_request_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_input_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_request_template.dart';
import 'package:auravibes_engine/src/connectors/models/url_response.dart';

/// Executes a versioned declarative Connector tool definition.
class const ConnectorToolTemplateExecutor(
  final ResolveConnectorRequestTemplate _resolver,
  final ConnectorHttpClient _httpClient,
) {
  // ignore: unnecessary-nullable, explicit null selects legacy/fallback execution inputs.
  CancelableOperation<UrlResponse> call({
    required Map<String, dynamic> inputs,
    required Map<String, String> credentials,
    ConnectorToolRequestDefinition? definition,
    ConnectorRequestTemplate? template,
    Map<String, ConnectorToolInputDefinition>? inputDefinitions,
    Map<String, dynamic>? schema,
    Map<String, ConnectorCredentialAttributeDefinition> credentialDefinitions =
        const {},
  }) {
    final resolvedDefinition = definition;
    final resolvedTemplate = resolvedDefinition?.request ?? template;
    final resolvedInputDefinitions =
        resolvedDefinition?.inputs ?? inputDefinitions;
    if (resolvedTemplate == null || resolvedInputDefinitions == null) {
      throw ArgumentError('A connector tool template definition is required.');
    }
    final resolvedCredentialDefinitions = {
      ...credentialDefinitions,
      ...?resolvedDefinition?.credentialDefinitions,
    };
    final request = _resolver(
      template: resolvedTemplate,
      inputs: inputs,
      credentials: credentials,
      inputDefinitions: resolvedInputDefinitions,
      schema: schema ?? resolvedDefinition?.inputSchema,
      credentialDefinitions: resolvedCredentialDefinitions,
    );
    final secrets = credentials.entries
        .where(
          (entry) => resolvedCredentialDefinitions[entry.key]?.secret != false,
        )
        .map((entry) => entry.value)
        .toList();

    return _httpClient(request).then(
      (response) =>
          const ConnectorResponseDecoder().call(response, secrets: secrets),
    );
  }
}
