import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_request_template.dart';
import 'package:auravibes_engine/src/connectors/models/connector_tool_input_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';
import 'package:auravibes_engine/src/skills/service_skills/service_skill_preset.dart';

final tinyFishSkill = ServiceSkillPreset(
  identifier: 'tinyfish',
  slug: 'tinyfish',
  title: 'TinyFish',
  description: 'Search the web and fetch clean page content.',
  content: '''
Use TinyFish for web search and page fetching. Prefer fetch when the user gives
specific URLs and wants extracted content.
  ''',
  tools: [
    const ConnectorToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search the web for a query.',
      inputJsonSchema: _searchInputSchema,
      requiresConnection: true,
      urlTemplate: .new(
        template: ConnectorRequestTemplate(
          url: 'https://api.search.tinyfish.ai',
          headers: {'X-API-Key': '{{ credential.apiKey }}'},
          query: {
            'query': '{{ input.query }}',
            'purpose': '{{ input.purpose }}',
            'location': '{{ input.location }}',
            'language': '{{ input.language }}',
            'after_date': '{{ input.afterDate }}',
            'before_date': '{{ input.beforeDate }}',
            'recency_minutes': '{{ input.recencyMinutes }}',
            'page': '{{ input.page }}',
            'include_thumbnail': '{{ input.includeThumbnail }}',
          },
        ),
        inputs: _searchInputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
    ConnectorToolDefinition(
      slug: 'fetch',
      title: 'Fetch',
      description: 'Fetch clean content from a URL.',
      inputJsonSchema: _fetchInputSchema,
      requiresConnection: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.fetch.tinyfish.ai',
        inputSchema: _fetchInputSchema,
        headers: {
          'X-API-Key': '{{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: '''
{"urls":{{ input.urls | json }},"format":{% if input.format != nil %}{{ input.format | json }}{% else %}"markdown"{% endif %}
{% if input.links != nil %},"links":{{ input.links | json }}{% endif %}
{% if input.imageLinks != nil %},"image_links":{{ input.imageLinks | json }}{% endif %}
{% if input.ttl != nil %},"ttl":{{ input.ttl | json }}{% endif %}
{% if input.perUrlTimeoutMs != nil %},"per_url_timeout_ms":{{ input.perUrlTimeoutMs | json }}{% endif %}}
''',
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'purpose': {'type': 'string'},
    'location': {'type': 'string'},
    'language': {'type': 'string'},
    'afterDate': {'type': 'string'},
    'beforeDate': {'type': 'string'},
    'recencyMinutes': {'type': 'integer', 'minimum': 1},
    'page': {'type': 'integer', 'minimum': 0},
    'includeThumbnail': {'type': 'boolean'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> _fetchInputSchema = {
  'type': 'object',
  'properties': {
    'urls': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'format': {'type': 'string'},
    'links': {'type': 'boolean'},
    'imageLinks': {'type': 'boolean'},
    'ttl': {'type': 'integer', 'minimum': 0},
    'perUrlTimeoutMs': {'type': 'integer', 'minimum': 1},
  },
  'required': ['urls'],
  'additionalProperties': false,
};

const Map<String, ConnectorToolInputDefinition> _searchInputs = {
  ...queryInputs,
  'purpose': ConnectorToolInputDefinition(
    description: 'Search purpose.',
    optional: true,
  ),
  'location': ConnectorToolInputDefinition(
    description: 'Search location.',
    optional: true,
  ),
  'language': ConnectorToolInputDefinition(
    description: 'Search language.',
    optional: true,
  ),
  'afterDate': ConnectorToolInputDefinition(
    description: 'Start date.',
    optional: true,
  ),
  'beforeDate': ConnectorToolInputDefinition(
    description: 'End date.',
    optional: true,
  ),
  'recencyMinutes': ConnectorToolInputDefinition(
    description: 'Recency window in minutes.',
    type: 'integer',
    optional: true,
  ),
  'page': ConnectorToolInputDefinition(
    description: 'Result page.',
    type: 'integer',
    optional: true,
  ),
  'includeThumbnail': ConnectorToolInputDefinition(
    description: 'Whether to include thumbnails.',
    type: 'boolean',
    optional: true,
  ),
};
