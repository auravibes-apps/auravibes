import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final xAiSkill = AppSkillDefinition(
  identifier: 'xai',
  slug: 'xai',
  title: 'xAI',
  description: 'Use xAI tools for web and X search.',
  content: '''
Use xAI when you need web-grounded answers or results from X. Prefer X search
for public posts and account-related queries.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['xai'],
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Answer a question using xAI web search.',
      inputJsonSchema: _webSearchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.x.ai/v1/responses',
        inputSchema: _webSearchInputSchema,
        headers: {
          'authorization': 'Bearer {{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: _webSearchBody,
        bodyFormat: .json,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'x_search',
      title: 'X search',
      description: 'Search public X posts for a query.',
      inputJsonSchema: _xSearchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.x.ai/v1/responses',
        inputSchema: _xSearchInputSchema,
        headers: {
          'authorization': 'Bearer {{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: _xSearchBody,
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _webSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string', 'default': 'grok-4'},
    'allowedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'enableImageUnderstanding': {'type': 'boolean'},
    'enableImageSearch': {'type': 'boolean'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const Map<String, Object> _xSearchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'model': {'type': 'string'},
    'allowedXHandles': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludedXHandles': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'fromDate': {'type': 'string'},
    'toDate': {'type': 'string'},
    'enableVideoUnderstanding': {'type': 'boolean'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const _webSearchBody = '''
{"model":{{ input.model | json }},"tools":[{"type":"web_search"
{% if input.allowedDomains != nil %},"allowed_domains":{{ input.allowedDomains | json }}{% endif %}
{% if input.excludedDomains != nil %},"excluded_domains":{{ input.excludedDomains | json }}{% endif %}
{% if input.enableImageUnderstanding != nil %},"enable_image_understanding":{{ input.enableImageUnderstanding | json }}{% endif %}
{% if input.enableImageSearch != nil %},"enable_image_search":{{ input.enableImageSearch | json }}{% endif %}}],"input":{{ input.question | json }}}
''';

const _xSearchBody = '''
{"model":{{ input.model | json }},"tools":[{"type":"x_search"
{% if input.allowedXHandles != nil %},"allowed_x_handles":{{ input.allowedXHandles | json }}{% endif %}
{% if input.excludedXHandles != nil %},"excluded_x_handles":{{ input.excludedXHandles | json }}{% endif %}
{% if input.fromDate != nil %},"from_date":{{ input.fromDate | json }}{% endif %}
{% if input.toDate != nil %},"to_date":{{ input.toDate | json }}{% endif %}
{% if input.enableVideoUnderstanding != nil %},"enable_video_understanding":{{ input.enableVideoUnderstanding | json }}{% endif %}}],"input":{{ input.query | json }}}
''';
