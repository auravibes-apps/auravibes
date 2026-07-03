import 'package:async/async.dart';
import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_callback.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/service_skills/providers/shared.dart';

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
  nativeTools: [
    _tool(
      'search',
      'Search',
      'Search web content.',
      _searchInputSchema,
      _search,
    ),
    _tool(
      'scrape',
      'Scrape',
      'Scrape page content from a URL.',
      _scrapeInputSchema,
      _scrape,
    ),
    _tool(
      'crawl',
      'Crawl',
      'Crawl a website.',
      fetchInputSchema,
      _crawl,
    ),
    _tool(
      'map',
      'Map',
      'Map URLs from a website.',
      _mapInputSchema,
      _map,
    ),
    _tool(
      'extract',
      'Extract',
      'Extract structured data from a URL.',
      _extractInputSchema,
      _extract,
    ),
  ],
);

AppSkillToolDefinition _tool(
  String slug,
  String title,
  String description,
  Map<String, Object> schema,
  AppSkillToolCallback callback,
) {
  return AppSkillToolDefinition(
    slug: slug,
    title: title,
    description: description,
    inputJsonSchema: schema,
    requiresCredential: true,
    callback: callback,
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

CancelableOperation<Object?> _search(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{'query': textInput(input, 'query')};
  putIfPresent(body, 'limit', positiveIntInput(input, 'limit'));
  putIfPresent(body, 'sources', stringListInput(input, 'sources'));
  putIfPresent(body, 'categories', stringListInput(input, 'categories'));
  putIfPresent(
    body,
    'includeDomains',
    stringListInput(input, 'includeDomains'),
  );
  putIfPresent(
    body,
    'excludeDomains',
    stringListInput(input, 'excludeDomains'),
  );
  putIfPresent(body, 'tbs', stringInput(input, 'tbs'));
  putIfPresent(body, 'location', stringInput(input, 'location'));
  putIfPresent(body, 'country', stringInput(input, 'country'));
  putIfPresent(body, 'timeout', positiveIntInput(input, 'timeout'));
  putIfPresent(
    body,
    'ignoreInvalidURLs',
    boolInput(input, 'ignoreInvalidURLs'),
  );
  return _post(context, input, 'search', body);
}

CancelableOperation<Object?> _scrape(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'url': textInput(input, 'url'),
    'formats': stringListInput(input, 'formats') ?? const ['markdown'],
  };
  putIfPresent(body, 'onlyMainContent', boolInput(input, 'onlyMainContent'));
  putIfPresent(body, 'includeTags', stringListInput(input, 'includeTags'));
  putIfPresent(body, 'excludeTags', stringListInput(input, 'excludeTags'));
  putIfPresent(body, 'timeout', positiveIntInput(input, 'timeout'));
  return _post(context, input, 'scrape', body);
}

CancelableOperation<Object?> _crawl(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return _post(context, input, 'crawl', {'url': textInput(input, 'url')});
}

CancelableOperation<Object?> _map(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{'url': textInput(input, 'url')};
  putIfPresent(body, 'limit', positiveIntInput(input, 'limit'));
  putIfPresent(
    body,
    'includeSubdomains',
    boolInput(input, 'includeSubdomains'),
  );
  putIfPresent(body, 'ignoreSitemap', boolInput(input, 'ignoreSitemap'));
  putIfPresent(body, 'sitemapOnly', boolInput(input, 'sitemapOnly'));
  return _post(context, input, 'map', body);
}

CancelableOperation<Object?> _extract(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'urls': stringListInput(input, 'urls') ?? const [],
  };
  putIfPresent(body, 'prompt', stringInput(input, 'prompt'));
  putIfPresent(body, 'schema', input['schema']);
  return _post(context, input, 'extract', body);
}

CancelableOperation<Object?> _post(
  SkillHttpClient context,
  Map<String, dynamic> input,
  String tool,
  Map<String, Object?> body,
) {
  return postJson(
    context,
    'https://api.firecrawl.dev/v2/$tool',
    {'authorization': 'Bearer ${apiKey(input)}'},
    body,
  );
}
