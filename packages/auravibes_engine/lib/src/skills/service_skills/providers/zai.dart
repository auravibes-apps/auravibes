import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final zaiSkill = AppSkillDefinition(
  identifier: 'zai',
  slug: 'zai',
  title: 'Z.ai',
  description: 'Search the web and use Z.ai chat web tools.',
  content: '''
Use Z.ai for direct web result lookup or model-assisted web answers. Prefer it
when the workspace already has Z.ai model credentials.
''',
  requiresCredential: true,
  compatibleModelProviderIds: [
    'zai',
    'zai-coding-plan',
    'zhipuai',
    'zhipuai-coding-plan',
  ],
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Search the web for structured results.',
      inputJsonSchema: _webSearchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.z.ai/api/paas/v4/web_search',
        inputSchema: _webSearchInputSchema,
        headers: {
          'authorization': 'Bearer {{ credential.apiKey }}',
          'content-type': 'application/json',
          'accept-language': '{{ input.acceptLanguage }}',
        },
        body: '''
{"search_query":{{ input.query | json }}
{% if input.searchEngine != nil %},"search_engine":{{ input.searchEngine | json }}{% endif %}
{% if input.count != nil %},"count":{{ input.count | json }}{% endif %}
{% if input.searchDomainFilter != nil %},"search_domain_filter":{{ input.searchDomainFilter | json }}{% endif %}
{% if input.searchRecencyFilter != nil %},"search_recency_filter":{{ input.searchRecencyFilter | json }}{% endif %}
{% if input.requestId != nil %},"request_id":{{ input.requestId | json }}{% endif %}
{% if input.userId != nil %},"user_id":{{ input.userId | json }}{% endif %}}
''',
        bodyFormat: .json,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'chat_web_search',
      title: 'Chat web search',
      description: 'Answer a question with Z.ai web-enabled chat.',
      inputJsonSchema: _chatWebSearchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.z.ai/api/paas/v4/chat/completions',
        inputSchema: _chatWebSearchInputSchema,
        headers: {
          'authorization': 'Bearer {{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: '''
{"model":{{ input.model | json }},"tools":[{"type":"web_search"}],
"messages":[{"role":"user","content":{{ input.question | json }}}]}
''',
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _webSearchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'searchEngine': {'type': 'string'},
    'count': {'type': 'integer', 'minimum': 1},
    'searchDomainFilter': {'type': 'string'},
    'searchRecencyFilter': {'type': 'string'},
    'requestId': {'type': 'string'},
    'userId': {'type': 'string'},
    'acceptLanguage': {'type': 'string'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> _chatWebSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string', 'default': 'glm-4.5'},
  },
  'required': ['question'],
  'additionalProperties': false,
};
