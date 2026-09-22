import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final tavilySkill = AppSkillDefinition(
  identifier: 'tavily',
  slug: 'tavily',
  title: 'Tavily',
  description: 'Search, extract, crawl, map, and research web content.',
  content: '''
Use Tavily for agent-oriented web search, URL extraction, site mapping,
crawling, and research workflows. Research is asynchronous: create a research
job, then poll its status or fetch its output. Tavily does not document remote
job cancellation.
''',
  requiresCredential: true,
  kind: .template,
  resources: const [
    AppSkillResourceDefinition(
      slug: 'search_quality_controls',
      title: 'Search quality controls',
      description:
          'Tune Tavily depth, evidence chunks, result count, and answer mode.',
      content: '''
Tavily's recommended agent defaults are deliberate:

```json
{"query":"compare Postgres and SQLite for an offline-first app","searchDepth":"advanced","chunksPerSource":3,"maxResults":5,"includeAnswer":false}
```

Use `maxResults: 5` for a focused answer and 10 for broader research.
`chunksPerSource: 3` gives stronger evidence per source. Keep
`includeAnswer: false` when the agent must inspect and cite sources; enable it
only when a quick answer seed is useful.

For time-sensitive discovery, combine `topic: "news"` with `timeRange` such
as `day`, `week`, `month`, or `year`. Use `startDate` and `endDate` for an
explicit range. Use `includeDomains` for authoritative sources and
`excludeDomains` for known noise.
''',
    ),
  ],
  tools: [
    _tool(
      'search',
      'Search',
      'Search the web.',
      _searchInputSchema,
      'https://api.tavily.com/search',
      _searchBody,
    ),
    _tool(
      'extract',
      'Extract',
      'Extract content from URLs.',
      _extractInputSchema,
      'https://api.tavily.com/extract',
      _extractBody,
    ),
    _tool(
      'crawl',
      'Crawl',
      'Crawl a website.',
      fetchInputSchema,
      'https://api.tavily.com/crawl',
      '{"url":{{ input.url | json }}}',
    ),
    _tool(
      'map',
      'Map',
      'Map a website.',
      _mapInputSchema,
      'https://api.tavily.com/map',
      _mapBody,
    ),
    AppSkillToolDefinition(
      slug: 'research_job_create',
      title: 'Create research job',
      description: 'Start asynchronous research and return its job id.',
      inputJsonSchema: _researchJobCreateInputSchema,
      requiresCredential: true,
      jobOperation: .create,
      urlTemplate: declarativeTemplate(
        url: 'https://api.tavily.com/research',
        inputSchema: _researchJobCreateInputSchema,
        headers: _headers,
        body: _researchJobCreateBody,
        bodyFormat: .json,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'research_job_status',
      title: 'Get research job status',
      description: 'Poll Tavily research progress by job id.',
      inputJsonSchema: jobIdInputSchema,
      requiresCredential: true,
      jobOperation: .status,
      urlTemplate: _researchJobStatusTemplate,
    ),
    AppSkillToolDefinition(
      slug: 'research_job_output',
      title: 'Get research job output',
      description: 'Fetch completed Tavily research output by job id.',
      inputJsonSchema: jobIdInputSchema,
      requiresCredential: true,
      jobOperation: .output,
      urlTemplate: _researchJobStatusTemplate,
    ),
  ],
);

const _headers = {
  'authorization': 'Bearer {{ credential.apiKey }}',
  'content-type': 'application/json',
};

AppSkillToolDefinition _tool(
  String slug,
  String title,
  String description,
  Map<String, Object> schema,
  String url,
  String body,
) => AppSkillToolDefinition(
  slug: slug,
  title: title,
  description: description,
  inputJsonSchema: schema,
  requiresCredential: true,
  urlTemplate: declarativeTemplate(
    url: url,
    inputSchema: schema,
    headers: {
      'authorization': 'Bearer {{ credential.apiKey }}',
      'content-type': 'application/json',
    },
    body: body,
    bodyFormat: .json,
  ),
);

const Map<String, Object> _searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'searchDepth': {'type': 'string'},
    'chunksPerSource': {'type': 'integer', 'minimum': 1},
    'maxResults': {'type': 'integer', 'minimum': 1},
    'topic': {'type': 'string'},
    'timeRange': {'type': 'string'},
    'startDate': {'type': 'string'},
    'endDate': {'type': 'string'},
    'includeAnswer': {'type': 'boolean'},
    'includeRawContent': {'type': 'boolean'},
    'includeImages': {'type': 'boolean'},
    'includeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'country': {'type': 'string'},
    'autoParameters': {'type': 'boolean'},
    'exactMatch': {'type': 'boolean'},
    'includeUsage': {'type': 'boolean'},
    'safeSearch': {'type': 'boolean'},
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
    'includeRawContent': {'type': 'boolean'},
    'includeImages': {'type': 'boolean'},
    'includeFavicon': {'type': 'boolean'},
  },
  'required': ['urls'],
  'additionalProperties': false,
};

const Map<String, Object> _mapInputSchema = {
  'type': 'object',
  'properties': {
    'url': {'type': 'string'},
    'maxDepth': {'type': 'integer', 'minimum': 1},
    'maxBreadth': {'type': 'integer', 'minimum': 1},
    'limit': {'type': 'integer', 'minimum': 1},
    'includeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['url'],
  'additionalProperties': false,
};

const Map<String, Object> _researchJobCreateInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'model': {
      'type': 'string',
      'enum': ['mini', 'pro', 'auto'],
    },
    'outputSchema': {'type': 'object'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const _searchBody = '''
{"query":{{ input.query | json }}
{% if input.searchDepth != nil %},"search_depth":{{ input.searchDepth | json }}{% endif %}
{% if input.chunksPerSource != nil %},"chunks_per_source":{{ input.chunksPerSource | json }}{% endif %}
{% if input.maxResults != nil %},"max_results":{{ input.maxResults | json }}{% endif %}
{% if input.topic != nil %},"topic":{{ input.topic | json }}{% endif %}
{% if input.timeRange != nil %},"time_range":{{ input.timeRange | json }}{% endif %}
{% if input.startDate != nil %},"start_date":{{ input.startDate | json }}{% endif %}
{% if input.endDate != nil %},"end_date":{{ input.endDate | json }}{% endif %}
{% if input.includeAnswer != nil %},"include_answer":{{ input.includeAnswer | json }}{% endif %}
{% if input.includeRawContent != nil %},"include_raw_content":{{ input.includeRawContent | json }}{% endif %}
{% if input.includeImages != nil %},"include_images":{{ input.includeImages | json }}{% endif %}
{% if input.includeDomains != nil %},"include_domains":{{ input.includeDomains | json }}{% endif %}
{% if input.excludeDomains != nil %},"exclude_domains":{{ input.excludeDomains | json }}{% endif %}
{% if input.country != nil %},"country":{{ input.country | json }}{% endif %}
{% if input.autoParameters != nil %},"auto_parameters":{{ input.autoParameters | json }}{% endif %}
{% if input.exactMatch != nil %},"exact_match":{{ input.exactMatch | json }}{% endif %}
{% if input.includeUsage != nil %},"include_usage":{{ input.includeUsage | json }}{% endif %}
{% if input.safeSearch != nil %},"safe_search":{{ input.safeSearch | json }}{% endif %}}
''';

const _extractBody = '''
{"urls":{{ input.urls | json }}
{% if input.includeRawContent != nil %},"include_raw_content":{{ input.includeRawContent | json }}{% endif %}
{% if input.includeImages != nil %},"include_images":{{ input.includeImages | json }}{% endif %}
{% if input.includeFavicon != nil %},"include_favicon":{{ input.includeFavicon | json }}{% endif %}}
''';

const _mapBody = '''
{"url":{{ input.url | json }}
{% if input.maxDepth != nil %},"max_depth":{{ input.maxDepth | json }}{% endif %}
{% if input.maxBreadth != nil %},"max_breadth":{{ input.maxBreadth | json }}{% endif %}
{% if input.limit != nil %},"limit":{{ input.limit | json }}{% endif %}
{% if input.includeDomains != nil %},"include_domains":{{ input.includeDomains | json }}{% endif %}
{% if input.excludeDomains != nil %},"exclude_domains":{{ input.excludeDomains | json }}{% endif %}}
''';

const _researchJobCreateBody = '''
{"input":{{ input.query | json }}
{% if input.model != nil %},"model":{{ input.model | json }}{% endif %}
{% if input.outputSchema != nil %},"output_schema":{{ input.outputSchema | json }}{% endif %}}
''';

final AppSkillUrlTemplate _researchJobStatusTemplate = declarativeTemplate(
  url: 'https://api.tavily.com/research/{{ input.jobId | uri_encode }}',
  inputSchema: jobIdInputSchema,
  method: .get,
  headers: _headers,
);
