import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final firecrawlSkill = AppSkillDefinition(
  identifier: 'firecrawl',
  slug: 'firecrawl',
  title: 'Firecrawl',
  description: 'Search, scrape, crawl, map, and extract web content.',
  content: '''
Use Firecrawl when page content matters: scraping pages, crawling sites,
discovering URLs, or extracting structured data from public pages.
''',
  requiresCredential: true,
  kind: .template,
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
    _tool(
      'crawl',
      'Crawl',
      'Crawl a website.',
      fetchInputSchema,
      _crawlTemplate,
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
    'authorization': 'Bearer {{ credential.apiKey }}',
    'content-type': 'application/json',
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
    'authorization': 'Bearer {{ credential.apiKey }}',
    'content-type': 'application/json',
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

final AppSkillUrlTemplate _crawlTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/crawl',
  inputSchema: fetchInputSchema,
  headers: {
    'authorization': 'Bearer {{ credential.apiKey }}',
    'content-type': 'application/json',
  },
  body: '{"url":{{ input.url | json }}}',
  bodyFormat: .json,
);

final AppSkillUrlTemplate _mapTemplate = declarativeTemplate(
  url: 'https://api.firecrawl.dev/v2/map',
  inputSchema: _mapInputSchema,
  headers: {
    'authorization': 'Bearer {{ credential.apiKey }}',
    'content-type': 'application/json',
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
    'authorization': 'Bearer {{ credential.apiKey }}',
    'content-type': 'application/json',
  },
  body: '''
{"urls":{{ input.urls | json }}
{% if input.prompt != nil %},"prompt":{{ input.prompt | json }}{% endif %}
{% if input.schema != nil %},"schema":{{ input.schema | json }}{% endif %}}
''',
  bodyFormat: .json,
);
