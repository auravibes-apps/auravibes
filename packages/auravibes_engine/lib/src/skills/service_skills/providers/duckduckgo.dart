import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final duckDuckGoSkill = AppSkillDefinition(
  identifier: 'duckduckgo',
  slug: 'duckduckgo',
  title: 'DuckDuckGo Search',
  description: 'Search DuckDuckGo web results without an API key.',
  content: '''
Use DuckDuckGo for key-free web search results. This integration returns the
raw no-script search response and may fail if DuckDuckGo changes markup or
blocks automated traffic.
''',
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search DuckDuckGo web results for a query.',
      inputJsonSchema: _searchInputSchema,
      urlTemplate: declarativeTemplate(
        url: 'https://html.duckduckgo.com/html/',
        inputSchema: _searchInputSchema,
        headers: {
          'accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'accept-language': 'en,en-US;q=0.9',
          'cache-control': 'max-age=0',
          'content-type': 'application/x-www-form-urlencoded',
          'referer': 'https://html.duckduckgo.com/',
          'user-agent': 'Mozilla/5.0 (AuraVibes)',
        },
        body:
            'q={{ input.query | url_encode }}'
            '${"&"}kl={{ input.region | default: "us-en" | url_encode }}&b=',
        bodyFormat: .form,
      ),
    ),
  ],
);

const Map<String, Object> _searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'maxResults': {'type': 'integer', 'minimum': 1, 'maximum': 20},
    'region': {'type': 'string', 'default': 'us-en'},
  },
  'required': ['query'],
  'additionalProperties': false,
};
