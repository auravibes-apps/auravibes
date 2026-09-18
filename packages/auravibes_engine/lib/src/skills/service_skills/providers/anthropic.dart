import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final anthropicSkill = AppSkillDefinition(
  identifier: 'anthropic',
  slug: 'anthropic',
  title: 'Anthropic',
  description: 'Use Claude web access tools for grounded answers.',
  content: '''
Use Anthropic when Claude should answer with current web information or inspect
a public URL. Prefer it when the conversation already uses Anthropic models.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['anthropic'],
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Answer a question using Claude web search.',
      inputJsonSchema: _webSearchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.anthropic.com/v1/messages',
        inputSchema: _webSearchInputSchema,
        headers: {
          'x-api-key': '{{ credential.apiKey }}',
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: _webSearchBody,
        bodyFormat: .json,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'web_fetch',
      title: 'Web fetch',
      description: 'Ask Claude to inspect and summarize a public URL.',
      inputJsonSchema: _webFetchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.anthropic.com/v1/messages',
        inputSchema: _webFetchInputSchema,
        headers: {
          'x-api-key': '{{ credential.apiKey }}',
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: _webFetchBody,
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _webSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string', 'default': 'claude-sonnet-4-20250514'},
    'maxUses': {'type': 'integer', 'minimum': 1},
    'allowedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'blockedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'responseInclusion': {'type': 'string'},
    'country': {'type': 'string'},
    'region': {'type': 'string'},
    'city': {'type': 'string'},
    'timezone': {'type': 'string'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const Map<String, Object> _webFetchInputSchema = {
  'type': 'object',
  'properties': {
    'url': {'type': 'string'},
    'model': {'type': 'string', 'default': 'claude-sonnet-4-20250514'},
  },
  'required': ['url'],
  'additionalProperties': false,
};

const _webSearchBody = '''
{
  "model": {{ input.model | json }},
  "max_tokens": 1024,
  "tools": [{
    "type": "web_search_20260318",
    "name": "web_search"
    {% if input.maxUses != nil %},"max_uses":{{ input.maxUses | json }}{% endif %}
    {% if input.allowedDomains != nil %},"allowed_domains":{{ input.allowedDomains | json }}{% endif %}
    {% if input.blockedDomains != nil %},"blocked_domains":{{ input.blockedDomains | json }}{% endif %}
    {% if input.responseInclusion != nil %},"response_inclusion":{{ input.responseInclusion | json }}{% endif %}
    {% if input.country != nil or input.region != nil or input.city != nil or input.timezone != nil %},"user_location":{
      "type":"approximate"
      {% if input.country != nil %},"country":{{ input.country | json }}{% endif %}
      {% if input.region != nil %},"region":{{ input.region | json }}{% endif %}
      {% if input.city != nil %},"city":{{ input.city | json }}{% endif %}
      {% if input.timezone != nil %},"timezone":{{ input.timezone | json }}{% endif %}
    }{% endif %}
  }],
  "messages": [{"role":"user","content":{{ input.question | json }}}]
}
''';

const _webFetchBody = '''
{
  "model": {{ input.model | json }},
  "max_tokens": 1024,
  "tools": [{"type":"web_search_20260318","name":"web_search"}],
  "messages": [{"role":"user","content":{{ input.url | prepend: "Fetch and summarize: " | json }}}]
}
''';
