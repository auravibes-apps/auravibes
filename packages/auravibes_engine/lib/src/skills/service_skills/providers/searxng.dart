import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_request_template.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_input_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/service_skill_preset.dart';

const Map<String, Object> _inputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'categories': {'type': 'string'},
    'engines': {'type': 'string'},
    'language': {'type': 'string'},
    'pageno': {'type': 'integer', 'minimum': 1},
    'timeRange': {'type': 'string'},
    'safesearch': {'type': 'integer', 'minimum': 0, 'maximum': 2},
    'autocomplete': {'type': 'string'},
    'imageProxy': {'type': 'boolean'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const _credentialDefinitions = {
  'baseUrl': ConnectorCredentialAttributeDefinition(
    description: 'SearXNG instance base URL.',
  ),
};

const searXngSkill = ServiceSkillPreset(
  identifier: 'searxng',
  slug: 'searxng',
  title: 'SearXNG',
  description: 'Search through a configured SearXNG metasearch instance.',
  content: '''
Use SearXNG when the user has a trusted metasearch instance and wants results
aggregated from that instance. The instance is selected from configured
workspace credentials.
  ''',
  tools: [
    ConnectorToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search a configured SearXNG instance.',
      inputJsonSchema: _inputSchema,
      requiresConnection: true,
      urlTemplate: .new(
        template: ConnectorRequestTemplate(
          url: '{{ credential.baseUrl }}/search',
          query: {
            'q': '{{ input.query }}',
            'format': 'json',
            'categories': '{{ input.categories }}',
            'engines': '{{ input.engines }}',
            'language': '{{ input.language }}',
            'pageno': '{{ input.pageno }}',
            'time_range': '{{ input.timeRange }}',
            'safesearch': '{{ input.safesearch }}',
            'autocomplete': '{{ input.autocomplete }}',
            'image_proxy': '{{ input.imageProxy }}',
          },
        ),
        inputs: {
          'query': ConnectorToolInputDefinition(description: 'Search query.'),
          'categories': ConnectorToolInputDefinition(
            description: 'Optional SearXNG categories.',
            optional: true,
          ),
          'engines': ConnectorToolInputDefinition(
            description: 'Optional SearXNG engines.',
            optional: true,
          ),
          'language': ConnectorToolInputDefinition(
            description: 'Optional result language.',
            optional: true,
          ),
          'pageno': ConnectorToolInputDefinition(
            description: 'Optional page number.',
            type: 'integer',
            optional: true,
          ),
          'timeRange': ConnectorToolInputDefinition(
            description: 'Optional time range.',
            optional: true,
          ),
          'safesearch': ConnectorToolInputDefinition(
            description: 'Optional safesearch level.',
            type: 'integer',
            optional: true,
          ),
          'autocomplete': ConnectorToolInputDefinition(
            description: 'Optional autocomplete backend.',
            optional: true,
          ),
          'imageProxy': ConnectorToolInputDefinition(
            description: 'Whether to proxy image URLs.',
            type: 'boolean',
            optional: true,
          ),
        },
        credentialDefinitions: _credentialDefinitions,
      ),
    ),
  ],
);
