import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const tinyFishSkill = AppSkillDefinition(
  identifier: 'tinyfish',
  slug: 'tinyfish',
  title: 'TinyFish',
  description: 'Search the web and fetch clean page content.',
  content: '''
Use TinyFish for web search and page fetching. Prefer fetch when the user gives
specific URLs and wants extracted content.
''',
  requiresCredential: true,
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search the web for a query.',
      inputJsonSchema: _searchInputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
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
    AppSkillToolDefinition(
      slug: 'fetch',
      title: 'Fetch',
      description: 'Fetch clean content from a URL.',
      inputJsonSchema: _fetchInputSchema,
      requiresCredential: true,
      callback: _fetch,
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

const Map<String, SkillTemplateInputDefinition> _searchInputs = {
  ...queryInputs,
  'purpose': SkillTemplateInputDefinition(
    description: 'Search purpose.',
    optional: true,
  ),
  'location': SkillTemplateInputDefinition(
    description: 'Search location.',
    optional: true,
  ),
  'language': SkillTemplateInputDefinition(
    description: 'Search language.',
    optional: true,
  ),
  'afterDate': SkillTemplateInputDefinition(
    description: 'Start date.',
    optional: true,
  ),
  'beforeDate': SkillTemplateInputDefinition(
    description: 'End date.',
    optional: true,
  ),
  'recencyMinutes': SkillTemplateInputDefinition(
    description: 'Recency window in minutes.',
    type: 'integer',
    optional: true,
  ),
  'page': SkillTemplateInputDefinition(
    description: 'Result page.',
    type: 'integer',
    optional: true,
  ),
  'includeThumbnail': SkillTemplateInputDefinition(
    description: 'Whether to include thumbnails.',
    type: 'boolean',
    optional: true,
  ),
};

CancelableOperation<Object?> _fetch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'urls': stringListInput(input, 'urls') ?? const [],
    'format': stringInput(input, 'format', defaultValue: 'markdown'),
  };
  putIfPresent(body, 'links', boolInput(input, 'links'));
  putIfPresent(body, 'image_links', boolInput(input, 'imageLinks'));
  putIfPresent(body, 'ttl', positiveIntInput(input, 'ttl'));
  putIfPresent(
    body,
    'per_url_timeout_ms',
    positiveIntInput(input, 'perUrlTimeoutMs'),
  );

  return postJson(context, 'https://api.fetch.tinyfish.ai', {
    'X-API-Key': apiKey(input),
  }, body);
}
