import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final openAiSkill = AppSkillDefinition(
  identifier: 'openai',
  slug: 'openai',
  title: 'OpenAI',
  description: 'Use OpenAI web-grounded response tools.',
  content: '''
Use OpenAI when you need a model-generated answer grounded by current web
information. This skill uses OpenAI API credentials.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['openai'],
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Answer a question using OpenAI web grounding.',
      inputJsonSchema: _webSearchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.openai.com/v1/responses',
        inputSchema: _webSearchInputSchema,
        headers: {
          'authorization': 'Bearer {{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: _webSearchBody,
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _webSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string', 'default': 'gpt-4.1'},
    'searchContextSize': {
      'type': 'string',
      'enum': ['low', 'medium', 'high'],
    },
    'allowedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'blockedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'country': {'type': 'string'},
    'region': {'type': 'string'},
    'city': {'type': 'string'},
    'timezone': {'type': 'string'},
    'includeImages': {'type': 'boolean'},
    'maxOutputTokens': {'type': 'integer', 'minimum': 1},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const _webSearchBody = '''
{
  "model": {{ input.model | json }},
  "tools": [{
    "type": "web_search"
    {% if input.searchContextSize != nil %},"search_context_size":{{ input.searchContextSize | json }}{% endif %}
    {% if input.allowedDomains != nil or input.blockedDomains != nil %},"filters":{
      {% if input.allowedDomains != nil %}"allowed_domains":{{ input.allowedDomains | json }}{% endif %}
      {% if input.blockedDomains != nil %}{% if input.allowedDomains != nil %},{% endif %}"blocked_domains":{{ input.blockedDomains | json }}{% endif %}
    }{% endif %}
    {% if input.country != nil or input.region != nil or input.city != nil or input.timezone != nil %},"user_location":{
      "type":"approximate"
      {% if input.country != nil %},"country":{{ input.country | json }}{% endif %}
      {% if input.region != nil %},"region":{{ input.region | json }}{% endif %}
      {% if input.city != nil %},"city":{{ input.city | json }}{% endif %}
      {% if input.timezone != nil %},"timezone":{{ input.timezone | json }}{% endif %}
    }{% endif %}
  }],
  "search_content_types": ["text"{% if input.includeImages %},"image"{% endif %}],
  "input": {{ input.question | json }}
  {% if input.maxOutputTokens != nil %},"max_output_tokens":{{ input.maxOutputTokens | json }}{% endif %}
}
''';
