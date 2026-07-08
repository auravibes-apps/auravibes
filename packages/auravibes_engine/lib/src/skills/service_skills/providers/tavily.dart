import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final tavilySkill = AppSkillDefinition(
  identifier: 'tavily',
  slug: 'tavily',
  title: 'Tavily',
  description: 'Search, extract, crawl, map, and research web content.',
  content: '''
Use Tavily for agent-oriented web search, URL extraction, site mapping,
crawling, and research workflows.
''',
  requiresCredential: true,
  nativeTools: [
    _tool('search', 'Search', 'Search the web.', _searchInputSchema, _search),
    _tool(
      'extract',
      'Extract',
      'Extract content from URLs.',
      _extractInputSchema,
      _extract,
    ),
    _tool(
      'crawl',
      'Crawl',
      'Crawl a website.',
      fetchInputSchema,
      _crawl,
    ),
    _tool('map', 'Map', 'Map a website.', _mapInputSchema, _map),
    _tool(
      'research',
      'Research',
      'Research a query.',
      _researchInputSchema,
      _research,
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

const Map<String, Object> _researchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _search(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{'query': textInput(input, 'query')};
  putIfPresent(body, 'search_depth', stringInput(input, 'searchDepth'));
  putIfPresent(
    body,
    'chunks_per_source',
    positiveIntInput(input, 'chunksPerSource'),
  );
  putIfPresent(body, 'max_results', positiveIntInput(input, 'maxResults'));
  putIfPresent(body, 'topic', stringInput(input, 'topic'));
  putIfPresent(body, 'time_range', stringInput(input, 'timeRange'));
  putIfPresent(body, 'start_date', stringInput(input, 'startDate'));
  putIfPresent(body, 'end_date', stringInput(input, 'endDate'));
  putIfPresent(body, 'include_answer', boolInput(input, 'includeAnswer'));
  putIfPresent(
    body,
    'include_raw_content',
    boolInput(input, 'includeRawContent'),
  );
  putIfPresent(body, 'include_images', boolInput(input, 'includeImages'));
  putIfPresent(
    body,
    'include_domains',
    stringListInput(input, 'includeDomains'),
  );
  putIfPresent(
    body,
    'exclude_domains',
    stringListInput(input, 'excludeDomains'),
  );
  putIfPresent(body, 'country', stringInput(input, 'country'));
  putIfPresent(body, 'auto_parameters', boolInput(input, 'autoParameters'));
  putIfPresent(body, 'exact_match', boolInput(input, 'exactMatch'));
  putIfPresent(body, 'include_usage', boolInput(input, 'includeUsage'));
  putIfPresent(body, 'safe_search', boolInput(input, 'safeSearch'));
  return _post(context, input, 'https://api.tavily.com/search', body);
}

CancelableOperation<Object?> _extract(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'urls': stringListInput(input, 'urls') ?? const [],
  };
  putIfPresent(
    body,
    'include_raw_content',
    boolInput(input, 'includeRawContent'),
  );
  putIfPresent(body, 'include_images', boolInput(input, 'includeImages'));
  putIfPresent(body, 'include_favicon', boolInput(input, 'includeFavicon'));
  return _post(context, input, 'https://api.tavily.com/extract', body);
}

CancelableOperation<Object?> _map(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{'url': textInput(input, 'url')};
  putIfPresent(body, 'max_depth', positiveIntInput(input, 'maxDepth'));
  putIfPresent(body, 'max_breadth', positiveIntInput(input, 'maxBreadth'));
  putIfPresent(body, 'limit', positiveIntInput(input, 'limit'));
  putIfPresent(
    body,
    'include_domains',
    stringListInput(input, 'includeDomains'),
  );
  putIfPresent(
    body,
    'exclude_domains',
    stringListInput(input, 'excludeDomains'),
  );
  return _post(context, input, 'https://api.tavily.com/map', body);
}

CancelableOperation<Object?> _crawl(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return _post(context, input, 'https://api.tavily.com/crawl', {
    'url': textInput(input, 'url'),
  });
}

CancelableOperation<Object?> _research(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return _post(context, input, 'https://api.tavily.com/research', {
    'query': textInput(input, 'query'),
  });
}

CancelableOperation<Object?> _post(
  SkillHttpClient context,
  Map<String, dynamic> input,
  String url,
  Map<String, Object?> body,
) {
  return postJson(context, url, {
    'authorization': 'Bearer ${apiKey(input)}',
  }, body);
}
