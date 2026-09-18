import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final codexSkill = AppSkillDefinition(
  identifier: 'codex',
  slug: 'codex',
  title: 'OpenAI Codex',
  description: 'Use Codex subscription web search.',
  content: '''
Use Codex when the user wants current web information through their Codex or
ChatGPT account. Return the answer and cite sources when available.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['openai-codex'],
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Answer a question using Codex subscription web search.',
      inputJsonSchema: _codexWebSearchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://chatgpt.com/backend-api/codex/responses',
        inputSchema: _codexWebSearchInputSchema,
        headers: {
          'authorization': 'Bearer {{ credential.apiKey }}',
          'ChatGPT-Account-Id': '{{ credential.accountId }}',
          'OpenAI-Beta': 'responses=experimental',
          'accept': 'text/event-stream',
          'content-type': 'application/json',
          'originator': 'auravibes',
          'user-agent': 'AuraVibes',
        },
        body: _webSearchBody,
        bodyFormat: .json,
        credentialDefinitions: _credentialDefinitions,
      ),
    ),
  ],
);

const Map<String, Object> _codexWebSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string', 'default': 'gpt-5.5'},
    'searchContextSize': {
      'type': 'string',
      'enum': ['low', 'medium', 'high'],
      'description': 'Amount of web context to request.',
    },
    'webSearchMode': {
      'type': 'string',
      'enum': ['cached', 'indexed', 'live'],
      'description': 'Search freshness mode.',
    },
    'allowedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
      'description': 'Optional domains to restrict results to.',
    },
    'blockedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
      'description': 'Optional domains to exclude from results.',
    },
    'country': {
      'type': 'string',
      'description': 'Optional approximate user country code.',
    },
    'region': {
      'type': 'string',
      'description': 'Optional approximate user region.',
    },
    'city': {
      'type': 'string',
      'description': 'Optional approximate user city.',
    },
    'timezone': {
      'type': 'string',
      'description': 'Optional approximate user timezone.',
    },
    'includeImages': {
      'type': 'boolean',
      'description': 'Whether image search content may be included.',
    },
  },
  'required': ['question'],
  'additionalProperties': false,
};

const _credentialDefinitions = {
  'apiKey': SkillCredentialAttributeDefinition(description: 'API key.'),
  'accountId': SkillCredentialAttributeDefinition(
    description: 'Optional ChatGPT account id.',
    optional: true,
    secret: false,
  ),
};

const _webSearchBody = '''
{
  "model":{{ input.model | json }},"stream":true,"store":false,
  "input":[{"type":"message","role":"user","content":[{"type":"input_text","text":{{ input.question | json }}}]}],
  "tools":[{"type":"web_search","search_context_size":{% if input.searchContextSize != nil %}{{ input.searchContextSize | json }}{% else %}"high"{% endif %},
    "external_web_access":{% if input.webSearchMode == "cached" %}false{% else %}true{% endif %}
    {% if input.webSearchMode == "indexed" %},"index_gated_web_access":true{% endif %}
    {% if input.allowedDomains != nil or input.blockedDomains != nil %},"filters":{
      {% if input.allowedDomains != nil %}"allowed_domains":{{ input.allowedDomains | json }}{% endif %}
      {% if input.blockedDomains != nil %}{% if input.allowedDomains != nil %},{% endif %}"blocked_domains":{{ input.blockedDomains | json }}{% endif %}
    }{% endif %}
    {% if input.country != nil or input.region != nil or input.city != nil or input.timezone != nil %},"user_location":{"type":"approximate"
      {% if input.country != nil %},"country":{{ input.country | json }}{% endif %}
      {% if input.region != nil %},"region":{{ input.region | json }}{% endif %}
      {% if input.city != nil %},"city":{{ input.city | json }}{% endif %}
      {% if input.timezone != nil %},"timezone":{{ input.timezone | json }}{% endif %}}
    {% endif %},"search_content_types":["text"{% if input.includeImages %},"image"{% endif %}] }],
  "tool_choice":{"type":"web_search"},
  "instructions":"Answer the question with current web information and cite sources."
}
''';
