import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const _authorizationHeader = 'Bearer {{ credential.apiKey }}';
const _contentTypeHeader = 'content-type';
const _jsonContentType = 'application/json';

final perplexitySkill = AppSkillDefinition(
  identifier: 'perplexity',
  slug: 'perplexity',
  title: 'Perplexity',
  description: 'Search, answer, and run Perplexity agent workflows.',
  content: '''
Use Perplexity for source-backed answers, ranked web results, or agentic web
research. Prefer Sonar for concise answers and agent for broader workflows.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['perplexity', 'perplexity-agent'],
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search the web for ranked results.',
      inputJsonSchema: _searchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.perplexity.ai/search',
        inputSchema: _searchInputSchema,
        headers: {
          'authorization': _authorizationHeader,
          _contentTypeHeader: _jsonContentType,
        },
        body: _searchBody,
        bodyFormat: .json,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'sonar_answer',
      title: 'Sonar answer',
      description: 'Answer a question with web citations.',
      inputJsonSchema: _sonarInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.perplexity.ai/v1/sonar',
        inputSchema: _sonarInputSchema,
        headers: {
          'authorization': _authorizationHeader,
          _contentTypeHeader: _jsonContentType,
        },
        body: _sonarBody,
        bodyFormat: .json,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'agent',
      title: 'Agent',
      description: 'Run a Perplexity agent workflow for a question.',
      inputJsonSchema: _agentInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.perplexity.ai/v1/agent',
        inputSchema: _agentInputSchema,
        headers: {
          'authorization': _authorizationHeader,
          _contentTypeHeader: _jsonContentType,
        },
        body: _agentBody,
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'maxResults': {'type': 'integer', 'minimum': 1},
    'country': {'type': 'string'},
    'language': {'type': 'string'},
    'includeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'searchContextSize': {'type': 'string'},
    'maxTokens': {'type': 'integer', 'minimum': 1},
    'maxTokensPerPage': {'type': 'integer', 'minimum': 1},
    'startDate': {'type': 'string'},
    'endDate': {'type': 'string'},
    'searchRecencyFilter': {'type': 'string'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> _sonarInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string', 'default': 'sonar'},
    'searchMode': {'type': 'string'},
    'returnImages': {'type': 'boolean'},
    'returnRelatedQuestions': {'type': 'boolean'},
    'disableSearch': {'type': 'boolean'},
    'enableSearchClassifier': {'type': 'boolean'},
    'searchContextSize': {'type': 'string'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const Map<String, Object> _agentInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'maxSteps': {'type': 'integer', 'minimum': 1, 'default': 10},
    'tools': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['question'],
  'additionalProperties': false,
};

const _searchBody = '''
{"query":{{ input.query | json }}
{% if input.maxResults != nil %},"max_results":{{ input.maxResults | json }}{% endif %}
{% if input.country != nil %},"country":{{ input.country | json }}{% endif %}
{% if input.language != nil %},"search_language_filter":{{ input.language | json }}{% endif %}
{% if input.includeDomains != nil %},"search_domain_filter":{{ input.includeDomains | json }}{% endif %}
{% if input.excludeDomains != nil %},"exclude_domains":{{ input.excludeDomains | json }}{% endif %}
{% if input.searchContextSize != nil %},"search_context_size":{{ input.searchContextSize | json }}{% endif %}
{% if input.maxTokens != nil %},"max_tokens":{{ input.maxTokens | json }}{% endif %}
{% if input.maxTokensPerPage != nil %},"max_tokens_per_page":{{ input.maxTokensPerPage | json }}{% endif %}
{% if input.startDate != nil %},"start_date":{{ input.startDate | json }}{% endif %}
{% if input.endDate != nil %},"end_date":{{ input.endDate | json }}{% endif %}
{% if input.searchRecencyFilter != nil %},"search_recency_filter":{{ input.searchRecencyFilter | json }}{% endif %}}
''';

const _sonarBody = '''
{"model":{{ input.model | json }},"messages":[{"role":"user","content":{{ input.question | json }}}]
{% if input.searchMode != nil %},"search_mode":{{ input.searchMode | json }}{% endif %}
{% if input.returnImages != nil %},"return_images":{{ input.returnImages | json }}{% endif %}
{% if input.returnRelatedQuestions != nil %},"return_related_questions":{{ input.returnRelatedQuestions | json }}{% endif %}
{% if input.disableSearch != nil %},"disable_search":{{ input.disableSearch | json }}{% endif %}
{% if input.enableSearchClassifier != nil %},"enable_search_classifier":{{ input.enableSearchClassifier | json }}{% endif %}
{% if input.searchContextSize != nil %},"web_search_options":{"search_context_size":{{ input.searchContextSize | json }}}{% endif %}}
''';

const _agentBody = '''
{"messages":[{"role":"user","content":{{ input.question | json }}}],
"tools":[{"type":"web_search"}],
"max_steps":{{ input.maxSteps | json }}}
''';
