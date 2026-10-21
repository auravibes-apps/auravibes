import 'package:auravibes_engine/src/connectors/models/connector_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_request_template.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_input_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_request_template.dart';
import 'package:auravibes_engine/src/connectors/models/url_request_method.dart';

const Map<String, Object> searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'maxResults': {'type': 'integer', 'minimum': 1},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> fetchInputSchema = {
  'type': 'object',
  'properties': {
    'url': {'type': 'string'},
  },
  'required': ['url'],
  'additionalProperties': false,
};

const Map<String, Object> answerInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const queryInputs = {
  'query': ConnectorToolInputDefinition(description: 'Search query.'),
  'maxResults': ConnectorToolInputDefinition(
    description: 'Maximum number of results.',
    type: 'integer',
    optional: true,
    minimum: 1,
  ),
};

const urlInputs = {
  'url': ConnectorToolInputDefinition(description: 'URL to fetch.'),
};

const apiKeyCredentialDefinitions = {
  'apiKey': ConnectorCredentialAttributeDefinition(description: 'API key.'),
};

// ignore: unnecessary-nullable, null body is valid for bodyless request templates.
ConnectorToolRequestTemplate declarativeTemplate({
  required String url,
  required Map<String, Object> inputSchema,
  Map<String, String> headers = const {},
  Map<String, String> query = const {},
  String? body,
  ConnectorRequestBodyFormat bodyFormat = ConnectorRequestBodyFormat.infer,
  Map<String, ConnectorCredentialAttributeDefinition> credentialDefinitions =
      apiKeyCredentialDefinitions,
}) => ConnectorToolRequestTemplate(
  template: ConnectorRequestTemplate(
    url: url,
    method: UrlRequestMethod.post,
    headers: headers,
    query: query,
    body: body,
    bodyFormat: bodyFormat,
  ),
  inputs: ConnectorToolInputDefinition.fromJsonSchema(inputSchema),
  credentialDefinitions: credentialDefinitions,
);
