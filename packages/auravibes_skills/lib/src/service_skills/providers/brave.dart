import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_url_template.dart';
import 'package:auravibes_skills/src/models/skill_template_input_definition.dart';
import 'package:auravibes_skills/src/models/skill_url_template.dart';
import 'package:auravibes_skills/src/service_skills/providers/shared.dart';

final braveSkill = AppSkillDefinition(
  identifier: 'brave',
  slug: 'brave',
  title: 'Brave Search',
  description: 'Find public web, news, image, and video results.',
  content: '''
Use Brave when you need current public web results, news, images, videos,
or compact context for grounding an answer. Prefer it for broad web discovery.
''',
  requiresCredential: true,
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Search the public web for pages matching a query.',
      inputJsonSchema: _inputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: 'https://api.search.brave.com/res/v1/web/search',
          headers: _headers,
          query: _query(includeCount: true),
        ),
        inputs: _inputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'llm_context',
      title: 'LLM context',
      description: 'Get compact web context for grounding an answer.',
      inputJsonSchema: _inputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: 'https://api.search.brave.com/res/v1/llm/context',
          headers: _headers,
          query: _query(),
        ),
        inputs: _inputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'news_search',
      title: 'News search',
      description: 'Search current news results for a query.',
      inputJsonSchema: _inputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: 'https://api.search.brave.com/res/v1/news/search',
          headers: _headers,
          query: _query(includeCount: true),
        ),
        inputs: _inputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'image_search',
      title: 'Image search',
      description: 'Search public image results for a query.',
      inputJsonSchema: _inputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: 'https://api.search.brave.com/res/v1/images/search',
          headers: _headers,
          query: _query(includeCount: true),
        ),
        inputs: _inputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'video_search',
      title: 'Video search',
      description: 'Search public video results for a query.',
      inputJsonSchema: _inputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: 'https://api.search.brave.com/res/v1/videos/search',
          headers: _headers,
          query: _query(includeCount: true),
        ),
        inputs: _inputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
  ],
);

const Map<String, Object> _inputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'maxResults': {'type': 'integer', 'minimum': 1},
    'country': {'type': 'string'},
    'searchLang': {'type': 'string'},
    'uiLang': {'type': 'string'},
    'safeSearch': {'type': 'string'},
    'freshness': {'type': 'string'},
    'spellcheck': {'type': 'boolean'},
    'resultFilter': {'type': 'string'},
    'goggles': {'type': 'string'},
    'offset': {'type': 'integer', 'minimum': 0},
    'locLat': {'type': 'string'},
    'locLong': {'type': 'string'},
    'locTimezone': {'type': 'string'},
    'locCity': {'type': 'string'},
    'locState': {'type': 'string'},
    'locCountry': {'type': 'string'},
    'locPostalCode': {'type': 'string'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const _headers = {
  'X-Subscription-Token': '{{ credential.apiKey }}',
  'X-Loc-Lat': '{{ input.locLat }}',
  'X-Loc-Long': '{{ input.locLong }}',
  'X-Loc-Timezone': '{{ input.locTimezone }}',
  'X-Loc-City': '{{ input.locCity }}',
  'X-Loc-State': '{{ input.locState }}',
  'X-Loc-Country': '{{ input.locCountry }}',
  'X-Loc-Postal-Code': '{{ input.locPostalCode }}',
};

const Map<String, SkillTemplateInputDefinition> _inputs = {
  ...queryInputs,
  'country': SkillTemplateInputDefinition(
    description: 'Country code.',
    optional: true,
  ),
  'searchLang': SkillTemplateInputDefinition(
    description: 'Search language.',
    optional: true,
  ),
  'uiLang': SkillTemplateInputDefinition(
    description: 'UI language.',
    optional: true,
  ),
  'safeSearch': SkillTemplateInputDefinition(
    description: 'Safe search mode.',
    optional: true,
  ),
  'freshness': SkillTemplateInputDefinition(
    description: 'Freshness filter.',
    optional: true,
  ),
  'spellcheck': SkillTemplateInputDefinition(
    description: 'Whether to spellcheck.',
    type: 'boolean',
    optional: true,
  ),
  'resultFilter': SkillTemplateInputDefinition(
    description: 'Result type filter.',
    optional: true,
  ),
  'goggles': SkillTemplateInputDefinition(
    description: 'Goggles identifier.',
    optional: true,
  ),
  'offset': SkillTemplateInputDefinition(
    description: 'Result offset.',
    type: 'integer',
    optional: true,
  ),
  'locLat': SkillTemplateInputDefinition(
    description: 'Location latitude.',
    optional: true,
  ),
  'locLong': SkillTemplateInputDefinition(
    description: 'Location longitude.',
    optional: true,
  ),
  'locTimezone': SkillTemplateInputDefinition(
    description: 'Location timezone.',
    optional: true,
  ),
  'locCity': SkillTemplateInputDefinition(
    description: 'Location city.',
    optional: true,
  ),
  'locState': SkillTemplateInputDefinition(
    description: 'Location state.',
    optional: true,
  ),
  'locCountry': SkillTemplateInputDefinition(
    description: 'Location country.',
    optional: true,
  ),
  'locPostalCode': SkillTemplateInputDefinition(
    description: 'Location postal code.',
    optional: true,
  ),
};

Map<String, String> _query({bool includeCount = false}) {
  return {
    'q': '{{ input.query }}',
    if (includeCount) 'count': '{{ input.maxResults }}',
    'country': '{{ input.country }}',
    'search_lang': '{{ input.searchLang }}',
    'ui_lang': '{{ input.uiLang }}',
    'safesearch': '{{ input.safeSearch }}',
    'freshness': '{{ input.freshness }}',
    'spellcheck': '{{ input.spellcheck }}',
    'result_filter': '{{ input.resultFilter }}',
    'goggles': '{{ input.goggles }}',
    'offset': '{{ input.offset }}',
  };
}
