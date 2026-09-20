import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const _apiKeyHeader = 'x-api-key';
const _apiKeyTemplate = '{{ credential.apiKey }}';
const _contentTypeHeader = 'content-type';
const _jsonContentType = 'application/json';

final exaSkill = AppSkillDefinition(
  identifier: 'exa',
  slug: 'exa',
  title: 'Exa',
  description: 'Search the web, fetch content, and answer grounded questions.',
  content: '''
Use Exa for AI-oriented web discovery, page contents, and grounded answers.
Prefer it when semantic relevance matters more than a classic result page.
''',
  requiresCredential: true,
  kind: .template,
  resources: const [
    AppSkillResourceDefinition(
      slug: 'search_modes_and_freshness',
      title: 'Search modes and freshness',
      description: 'Choose Exa search modes, categories, and cache age.',
      content: '''
Exa `type` selects retrieval behavior; it is not free-form text:

- `instant` minimizes latency; `fast` fits interactive lookup.
- `auto` is the balanced default; `deep` and `deep-reasoning` suit research.
- `category: "publication"` favors papers; `category: "news"` favors news.

```json
{"query":"Flutter state management comparison","type":"fast","numResults":5}
```

```json
{"query":"offline-first database research","type":"deep","category":"publication","numResults":10}
```

Use `includeDomains` for host, path, or wildcard filtering instead of putting
`site:` syntax in the query. Published-date filters use ISO 8601 timestamps.
For `company` and `people` categories, do not combine `excludeDomains` or
published-date filters; Exa rejects those combinations.
''',
    ),
    AppSkillResourceDefinition(
      slug: 'contents_cache_and_fields',
      title: 'Contents cache and fields',
      description:
          'Choose Exa text, highlights, summaries, and content freshness.',
      content: '''
Select the smallest content shape that answers the question:

```json
{"urls":["<page-url-1>","<page-url-2>"],"includeHighlights":true}
```

Use `includeHighlights` for relevant snippets across pages and `includeText`
when exact wording or full-page details matter. Use `includeSummary` only for
orientation before deciding whether full text is needed.

```json
{"urls":["<page-url>"],"includeText":true,"maxAgeHours":0}
```

`contents.urls` is the supported input in AuraVibes; pass a non-empty list of
URLs, not result objects. `maxAgeHours: 0` asks for fresh content, a positive
value allows cached content up to that age, and omitting it uses normal cache
fallback behavior. `livecrawlTimeout` is milliseconds.
''',
    ),
  ],
  tools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Find relevant web pages for a query.',
      inputJsonSchema: _searchInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.exa.ai/search',
        inputSchema: _searchInputSchema,
        headers: {
          _apiKeyHeader: _apiKeyTemplate,
          _contentTypeHeader: _jsonContentType,
        },
        body: _searchBody,
        bodyFormat: .json,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'contents',
      title: 'Contents',
      description: 'Fetch clean content for a URL.',
      inputJsonSchema: _contentsInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.exa.ai/contents',
        inputSchema: _contentsInputSchema,
        headers: {
          _apiKeyHeader: _apiKeyTemplate,
          _contentTypeHeader: _jsonContentType,
        },
        body: _contentsBody,
        bodyFormat: .json,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'answer',
      title: 'Answer',
      description: 'Answer a question with web grounding.',
      inputJsonSchema: _answerInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.exa.ai/answer',
        inputSchema: _answerInputSchema,
        headers: {
          _apiKeyHeader: _apiKeyTemplate,
          _contentTypeHeader: _jsonContentType,
        },
        body: _answerBody,
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'type': {'type': 'string'},
    'numResults': {'type': 'integer', 'minimum': 1},
    'includeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'startPublishedDate': {'type': 'string'},
    'endPublishedDate': {'type': 'string'},
    'category': {'type': 'string'},
    'includeText': {'type': 'boolean'},
    'includeHighlights': {'type': 'boolean'},
    'includeSummary': {'type': 'boolean'},
    'livecrawlTimeout': {'type': 'integer', 'minimum': 1},
    'maxAgeHours': {'type': 'integer', 'minimum': 0},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> _contentsInputSchema = {
  'type': 'object',
  'properties': {
    'urls': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'includeText': {'type': 'boolean'},
    'includeHighlights': {'type': 'boolean'},
    'includeSummary': {'type': 'boolean'},
    'livecrawlTimeout': {'type': 'integer', 'minimum': 1},
    'maxAgeHours': {'type': 'integer', 'minimum': 0},
  },
  'required': ['urls'],
  'additionalProperties': false,
};

const Map<String, Object> _answerInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'includeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'startPublishedDate': {'type': 'string'},
    'endPublishedDate': {'type': 'string'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const _searchBody = '''
{"query":{{ input.query | json }}
{% if input.type != nil %},"type":{{ input.type | json }}{% endif %}
{% if input.numResults != nil %},"numResults":{{ input.numResults | json }}{% endif %}
{% if input.includeDomains != nil %},"includeDomains":{{ input.includeDomains | json }}{% endif %}
{% if input.excludeDomains != nil %},"excludeDomains":{{ input.excludeDomains | json }}{% endif %}
{% if input.startPublishedDate != nil %},"startPublishedDate":{{ input.startPublishedDate | json }}{% endif %}
{% if input.endPublishedDate != nil %},"endPublishedDate":{{ input.endPublishedDate | json }}{% endif %}
{% if input.category != nil %},"category":{{ input.category | json }}{% endif %}
{% if input.includeText != nil or input.includeHighlights != nil or input.includeSummary != nil or input.livecrawlTimeout != nil or input.maxAgeHours != nil %},"contents":{
  {% if input.includeText != nil %}"text":{{ input.includeText | json }}{% endif %}
  {% if input.includeHighlights != nil %}{% if input.includeText != nil %},{% endif %}"highlights":{{ input.includeHighlights | json }}{% endif %}
  {% if input.includeSummary != nil %}{% if input.includeText != nil or input.includeHighlights != nil %},{% endif %}"summary":{{ input.includeSummary | json }}{% endif %}
  {% if input.livecrawlTimeout != nil %}{% if input.includeText != nil or input.includeHighlights != nil or input.includeSummary != nil %},{% endif %}"livecrawlTimeout":{{ input.livecrawlTimeout | json }}{% endif %}
  {% if input.maxAgeHours != nil %}{% if input.includeText != nil or input.includeHighlights != nil or input.includeSummary != nil or input.livecrawlTimeout != nil %},{% endif %}"maxAgeHours":{{ input.maxAgeHours | json }}{% endif %}
}{% endif %}}
''';

const _contentsBody = '''
{"urls":{{ input.urls | json }}
{% if input.includeText != nil or input.includeHighlights != nil or input.includeSummary != nil or input.livecrawlTimeout != nil or input.maxAgeHours != nil %},"contents":{
  {% if input.includeText != nil %}"text":{{ input.includeText | json }}{% endif %}
  {% if input.includeHighlights != nil %}{% if input.includeText != nil %},{% endif %}"highlights":{{ input.includeHighlights | json }}{% endif %}
  {% if input.includeSummary != nil %}{% if input.includeText != nil or input.includeHighlights != nil %},{% endif %}"summary":{{ input.includeSummary | json }}{% endif %}
  {% if input.livecrawlTimeout != nil %}{% if input.includeText != nil or input.includeHighlights != nil or input.includeSummary != nil %},{% endif %}"livecrawlTimeout":{{ input.livecrawlTimeout | json }}{% endif %}
  {% if input.maxAgeHours != nil %}{% if input.includeText != nil or input.includeHighlights != nil or input.includeSummary != nil or input.livecrawlTimeout != nil %},{% endif %}"maxAgeHours":{{ input.maxAgeHours | json }}{% endif %}
}{% endif %}}
''';

const _answerBody = '''
{"query":{{ input.question | json }}
{% if input.includeDomains != nil %},"includeDomains":{{ input.includeDomains | json }}{% endif %}
{% if input.excludeDomains != nil %},"excludeDomains":{{ input.excludeDomains | json }}{% endif %}
{% if input.startPublishedDate != nil %},"startPublishedDate":{{ input.startPublishedDate | json }}{% endif %}
{% if input.endPublishedDate != nil %},"endPublishedDate":{{ input.endPublishedDate | json }}{% endif %}}
''';
