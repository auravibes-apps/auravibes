import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final parallelSkill = AppSkillDefinition(
  identifier: 'parallel',
  slug: 'parallel',
  title: 'Parallel',
  description: 'Search, extract, and run research tasks.',
  content: '''
Use Parallel for fast web search, URL extraction, or larger research tasks.
Prefer tasks when the request needs deeper synthesis.
''',
  requiresCredential: true,
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search for web results and excerpts.',
      inputJsonSchema: _searchInputSchema,
      requiresCredential: true,
      urlTemplate: _template(
        'https://api.parallel.ai/v1/search',
        _searchBody,
        _searchInputSchema,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'extract',
      title: 'Extract',
      description: 'Extract content from a URL.',
      inputJsonSchema: _extractInputSchema,
      requiresCredential: true,
      urlTemplate: _template(
        'https://api.parallel.ai/v1/extract',
        _extractBody,
        _extractInputSchema,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'tasks',
      title: 'Tasks',
      description: 'Run a deeper research task.',
      inputJsonSchema: answerInputSchema,
      requiresCredential: true,
      urlTemplate: _template(
        'https://api.parallel.ai/v1/tasks',
        '{"input":{{ input.question | json }}}',
        answerInputSchema,
      ),
    ),
  ],
);

AppSkillUrlTemplate _template(
  String url,
  String body,
  Map<String, Object> inputSchema,
) {
  return AppSkillUrlTemplate(
    template: .new(
      url: url,
      method: .post,
      headers: {
        'x-api-key': '{{ credential.apiKey }}',
        'content-type': 'application/json',
      },
      body: body,
    ),
    inputs: SkillTemplateInputDefinition.fromJsonSchema(inputSchema),
    credentialDefinitions: apiKeyCredentialDefinitions,
  );
}

const Map<String, Object> _searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'searchQueries': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'mode': {'type': 'string'},
    'sessionId': {'type': 'string'},
    'clientModel': {'type': 'string'},
    'includeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'afterDate': {'type': 'string'},
    'maxAgeSeconds': {'type': 'integer', 'minimum': 0},
    'timeoutSeconds': {'type': 'integer', 'minimum': 1},
    'disableCacheFallback': {'type': 'boolean'},
    'maxCharsPerResult': {'type': 'integer', 'minimum': 1},
    'location': {'type': 'string'},
    'maxResults': {'type': 'integer', 'minimum': 1},
    'maxCharsTotal': {'type': 'integer', 'minimum': 1},
    'objective': {'type': 'string'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> _extractInputSchema = {
  'type': 'object',
  'properties': {
    'urls': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'maxChars': {'type': 'integer', 'minimum': 1},
    'maxCharsTotal': {'type': 'integer', 'minimum': 1},
    'timeoutSeconds': {'type': 'integer', 'minimum': 1},
  },
  'required': ['urls'],
  'additionalProperties': false,
};

const _searchBody = '''
{
  "search_queries": {% if input.searchQueries %}{{ input.searchQueries | json }}{% else %}[{{ input.query | json }}]{% endif %},
  "max_chars_total": {% if input.maxCharsTotal != nil %}{{ input.maxCharsTotal | json }}{% else %}6000{% endif %}
  {% if input.mode != nil %},"mode":{{ input.mode | json }}{% endif %}
  {% if input.sessionId != nil %},"session_id":{{ input.sessionId | json }}{% endif %}
  {% if input.clientModel != nil %},"client_model":{{ input.clientModel | json }}{% endif %}
  {% if input.includeDomains != nil %},"include_domains":{{ input.includeDomains | json }}{% endif %}
  {% if input.excludeDomains != nil %},"exclude_domains":{{ input.excludeDomains | json }}{% endif %}
  {% if input.afterDate != nil %},"after_date":{{ input.afterDate | json }}{% endif %}
  {% if input.maxAgeSeconds != nil %},"max_age_seconds":{{ input.maxAgeSeconds | json }}{% endif %}
  {% if input.timeoutSeconds != nil %},"timeout_seconds":{{ input.timeoutSeconds | json }}{% endif %}
  {% if input.disableCacheFallback != nil %},"disable_cache_fallback":{{ input.disableCacheFallback | json }}{% endif %}
  {% if input.maxCharsPerResult != nil %},"max_chars_per_result":{{ input.maxCharsPerResult | json }}{% endif %}
  {% if input.location != nil %},"location":{{ input.location | json }}{% endif %}
  {% if input.maxResults != nil %},"max_results":{{ input.maxResults | json }}{% endif %}
  {% if input.objective != nil %},"objective":{{ input.objective | json }}{% endif %}
}
''';

const _extractBody = '''
{"urls":{{ input.urls | json }}
{% if input.maxChars != nil %},"max_chars":{{ input.maxChars | json }}{% endif %}
{% if input.maxCharsTotal != nil %},"max_chars_total":{{ input.maxCharsTotal | json }}{% endif %}
{% if input.timeoutSeconds != nil %},"timeout_seconds":{{ input.timeoutSeconds | json }}{% endif %}}
''';
