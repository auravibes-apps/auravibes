import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/url_request_method.dart';

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

const Map<String, Object> jobIdInputSchema = {
  'type': 'object',
  'properties': {
    'jobId': {'type': 'string'},
  },
  'required': ['jobId'],
  'additionalProperties': false,
};

const queryInputs = {
  'query': SkillTemplateInputDefinition(description: 'Search query.'),
  'maxResults': SkillTemplateInputDefinition(
    description: 'Maximum number of results.',
    type: 'integer',
    optional: true,
    minimum: 1,
  ),
};

const urlInputs = {
  'url': SkillTemplateInputDefinition(description: 'URL to fetch.'),
};

const apiKeyCredentialDefinitions = {
  'apiKey': SkillCredentialAttributeDefinition(description: 'API key.'),
};

// ignore: unnecessary-nullable, null body is valid for bodyless request templates.
AppSkillUrlTemplate declarativeTemplate({
  required String url,
  required Map<String, Object> inputSchema,
  UrlRequestMethod method = UrlRequestMethod.post,
  Map<String, String> headers = const {},
  Map<String, String> query = const {},
  String? body,
  SkillUrlTemplateBodyFormat bodyFormat = SkillUrlTemplateBodyFormat.infer,
  Map<String, SkillCredentialAttributeDefinition> credentialDefinitions =
      apiKeyCredentialDefinitions,
}) => AppSkillUrlTemplate(
  template: SkillUrlTemplate(
    url: url,
    method: method,
    headers: headers,
    query: query,
    body: body,
    bodyFormat: bodyFormat,
  ),
  inputs: SkillTemplateInputDefinition.fromJsonSchema(inputSchema),
  credentialDefinitions: credentialDefinitions,
);
