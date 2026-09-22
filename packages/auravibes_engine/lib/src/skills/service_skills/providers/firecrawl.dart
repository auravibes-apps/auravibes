import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const _authorizationHeader = 'Bearer {{ credential.apiKey }}';
const _contentTypeHeader = 'content-type';
const _jsonContentType = 'application/json';

final firecrawlSkill = AppSkillDefinition(
  identifier: 'firecrawl',
  slug: 'firecrawl',
  title: 'Firecrawl',
  description: 'Search, scrape, crawl, map, and extract web content.',
  content: '''
Use Firecrawl when page content matters: scraping pages, crawling sites,
discovering URLs, or extracting structured data from public pages. Crawls are
asynchronous: create a crawl job, poll its status, and cancel it when needed.
''',
  requiresCredential: true,
  kind: .template,
  resources: const [
    AppSkillResourceDefinition(
      slug: 'search_map_and_scrape_controls',
      title: 'Search, map, and scrape controls',
      description:
          'Use Firecrawl source filters, URL maps, and content formats.',
      content: '''
Firecrawl search has provider-specific filter values:

```json
{"query":"Flutter 3.47 migration guide","limit":5,"sources":["web"],"categories":["research"]}
```

Use `sources` with `web`, `news`, or `images`; use `categories` with `github`,
`research`, or `pdf`. `tbs` accepts values such as `qdr:d`, `qdr:w`, or
`qdr:m` for recency. `includeDomains` is safer than relying on query wording
when results must come from a known site.

`map` with `sitemapOnly: true` returns a URL inventory without page content.
Set `includeSubdomains: true` only when related subdomains are in scope;
`ignoreSitemap: true` forces discovery beyond the site's sitemap.

```json
{"url":"<site-url>","limit":50,"sitemapOnly":true,"includeSubdomains":false}
```

For `scrape`, `formats: ["markdown"]` is the compact readable form and
`formats: ["links"]` adds a link inventory. Set `onlyMainContent: true` to
drop navigation and other page chrome.

```json
{"url":"<page-url>","formats":["markdown","links"],"onlyMainContent":true}
```
''',
    ),
    AppSkillResourceDefinition(
      slug: 'extract_schema_contract',
      title: 'Extract schema contract',
      description: 'Use Firecrawl extraction for small normalized records.',
      content: '''
`extract` takes `urls`, not a single `url`. Its `schema` is the output
contract; `prompt` supplies normalization rules that a type declaration cannot
express.

```json
{
  "urls": ["<product-page-1>", "<product-page-2>"],
  "prompt": "Extract one record per page. Normalize prices to numbers and use null when absent.",
  "schema": {
    "type": "object",
    "properties": {
      "name": {"type": "string"},
      "price": {"type": "number"},
      "availability": {"type": "string"}
    },
    "required": ["name"]
  }
}
```

Keep schemas small and make only truly necessary fields `required`. Use
`scrape` with `formats: ["markdown"]` when the user needs page text; do not
use `extract` as a substitute for full-page content.
''',
    ),
  ],
  tools: [
    _tool(
      'search',
      'Search',
      'Search web content.',
      _searchInputSchema,
      _searchTemplate,
    ),
    _tool(
      'scrape',
      'Scrape',
      'Scrape page content from a URL.',
      _scrapeInputSchema,
      _scrapeTemplate,
    ),
    _jobTool(
      'crawl_job_create',
      'Create crawl job',
      'Start an asynchronous crawl and return its job id.',
      fetchInputSchema,
      _crawlJobCreateTemplate,
      .create,
    ),
    _jobTool(
      'crawl_job_status',
      'Get crawl job status',
      'Poll Firecrawl crawl progress by job id.',
      jobIdInputSchema,
      _crawlJobStatusTemplate,
      .status,
    ),
    _jobTool(
      'crawl_job_cancel',
      'Cancel crawl job',
      'Cancel a running Firecrawl crawl by job id.',
      jobIdInputSchema,
      _crawlJobCancelTemplate,
      .cancel,
    ),
    _jobTool(
      'crawl_job_output',
      'Get crawl job output',
      'Fetch completed Firecrawl crawl output by job id.',
      jobIdInputSchema,
      _crawlJobStatusTemplate,
      .output,
    ),
    _tool(
      'map',
      'Map',
      'Map URLs from a website.',
      _mapInputSchema,
      _mapTemplate,
    ),
    _tool(
      'extract',
      'Extract',
      'Extract structured data from a URL.',
      _extractInputSchema,
      _extractTemplate,
    ),
  ],
);

AppSkillToolDefinition _tool(
  String slug,
  String title,
  String description,
  Map<String, Object> schema,
  AppSkillUrlTemplate template,
) {
  return AppSkillToolDefinition(
    slug: slug,
    title: title,
    description: description,
    inputJsonSchema: schema,
    requiresCredential: true,
    urlTemplate: template,
  );
}

AppSkillToolDefinition _jobTool(
  String slug,
  String title,
  String description,
  Map<String, Object> schema,
  AppSkillUrlTemplate template,
  AppSkillJobOperation operation,
) {
  return AppSkillToolDefinition(
    slug: slug,
    title: title,
    description: description,
    inputJsonSchema: schema,
    requiresCredential: true,
    jobOperation: operation,
    urlTemplate: template,
  );
}

const Map<String, Object> _searchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'limit': {'type': 'integer', 'minimum': 1},
    'sources': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'categories': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'includeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludeDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'tbs': {'type': 'string'},
    'location': {'type': 'string'},
    'country': {'type': 'string'},
    'timeout': {'type': 'integer', 'minimum': 1},
    'ignoreInvalidURLs': {'type': 'boolean'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> _scrapeInputSchema = {
  'type': 'object',
  'properties': {
    'url': {'type': 'string'},
    'formats': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'onlyMainContent': {'type': 'boolean'},
    'includeTags': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludeTags': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'timeout': {'type': 'integer', 'minimum': 1},
  },
  'required': ['url'],
  'additionalProperties': false,
};

const Map<String, Object> _mapInputSchema = {
  'type': 'object',
  'properties': {
    'url': {'type': 'string'},
    'limit': {'type': 'integer', 'minimum': 1},
    'includeSubdomains': {'type': 'boolean'},
    'ignoreSitemap': {'type': 'boolean'},
    'sitemapOnly': {'type': 'boolean'},
  },
  'required': ['url'],
  'additionalProperties': false,
};

const Map<String, Object> _extractInputSchema = {
  'type': 'object',
  'properties': {
    'urls': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'prompt': {'type': 'string'},
    'schema': {'type': 'object'},
  },
  'required': ['urls'],
  'additionalProperties': false,
};

final AppSkillUrlTemplate _searchTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/search',
  inputSchema: _searchInputSchema,
  headers: {
    'authorization': _authorizationHeader,
    _contentTypeHeader: _jsonContentType,
  },
  body: '''
{"query":{{ input.query | json }}
{% if input.limit != nil %},"limit":{{ input.limit | json }}{% endif %}
{% if input.sources != nil %},"sources":{{ input.sources | json }}{% endif %}
{% if input.categories != nil %},"categories":{{ input.categories | json }}{% endif %}
{% if input.includeDomains != nil %},"includeDomains":{{ input.includeDomains | json }}{% endif %}
{% if input.excludeDomains != nil %},"excludeDomains":{{ input.excludeDomains | json }}{% endif %}
{% if input.tbs != nil %},"tbs":{{ input.tbs | json }}{% endif %}
{% if input.location != nil %},"location":{{ input.location | json }}{% endif %}
{% if input.country != nil %},"country":{{ input.country | json }}{% endif %}
{% if input.timeout != nil %},"timeout":{{ input.timeout | json }}{% endif %}
{% if input.ignoreInvalidURLs != nil %},"ignoreInvalidURLs":{{ input.ignoreInvalidURLs | json }}{% endif %}}
''',
  bodyFormat: .json,
);

final AppSkillUrlTemplate _scrapeTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/scrape',
  inputSchema: _scrapeInputSchema,
  headers: {
    'authorization': _authorizationHeader,
    _contentTypeHeader: _jsonContentType,
  },
  body: '''
{"url":{{ input.url | json }},"formats":{% if input.formats != nil %}{{ input.formats | json }}{% else %}["markdown"]{% endif %}
{% if input.onlyMainContent != nil %},"onlyMainContent":{{ input.onlyMainContent | json }}{% endif %}
{% if input.includeTags != nil %},"includeTags":{{ input.includeTags | json }}{% endif %}
{% if input.excludeTags != nil %},"excludeTags":{{ input.excludeTags | json }}{% endif %}
{% if input.timeout != nil %},"timeout":{{ input.timeout | json }}{% endif %}}
''',
  bodyFormat: .json,
);

final AppSkillUrlTemplate _crawlJobCreateTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/crawl',
  inputSchema: fetchInputSchema,
  headers: {
    'authorization': _authorizationHeader,
    _contentTypeHeader: _jsonContentType,
  },
  body: '{"url":{{ input.url | json }}}',
  bodyFormat: .json,
);

final AppSkillUrlTemplate _crawlJobStatusTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/crawl/{{ input.jobId | uri_encode }}',
  inputSchema: jobIdInputSchema,
  method: .get,
  headers: {
    'authorization': _authorizationHeader,
    _contentTypeHeader: _jsonContentType,
  },
);

final AppSkillUrlTemplate _crawlJobCancelTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/crawl/{{ input.jobId | uri_encode }}',
  inputSchema: jobIdInputSchema,
  method: .delete,
  headers: {
    'authorization': _authorizationHeader,
    _contentTypeHeader: _jsonContentType,
  },
);

final AppSkillUrlTemplate _mapTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/map',
  inputSchema: _mapInputSchema,
  headers: {
    'authorization': _authorizationHeader,
    _contentTypeHeader: _jsonContentType,
  },
  body: '''
{"url":{{ input.url | json }}
{% if input.limit != nil %},"limit":{{ input.limit | json }}{% endif %}
{% if input.includeSubdomains != nil %},"includeSubdomains":{{ input.includeSubdomains | json }}{% endif %}
{% if input.ignoreSitemap != nil %},"ignoreSitemap":{{ input.ignoreSitemap | json }}{% endif %}
{% if input.sitemapOnly != nil %},"sitemapOnly":{{ input.sitemapOnly | json }}{% endif %}}
''',
  bodyFormat: .json,
);

final AppSkillUrlTemplate _extractTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/extract',
  inputSchema: _extractInputSchema,
  headers: {
    'authorization': _authorizationHeader,
    _contentTypeHeader: _jsonContentType,
  },
  body: '''
{"urls":{{ input.urls | json }}
{% if input.prompt != nil %},"prompt":{{ input.prompt | json }}{% endif %}
{% if input.schema != nil %},"schema":{{ input.schema | json }}{% endif %}}
''',
  bodyFormat: .json,
);
