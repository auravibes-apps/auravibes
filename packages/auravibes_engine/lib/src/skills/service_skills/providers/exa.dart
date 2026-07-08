import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const exaSkill = AppSkillDefinition(
  identifier: 'exa',
  slug: 'exa',
  title: 'Exa',
  description: 'Search the web, fetch content, and answer grounded questions.',
  content: '''
Use Exa for AI-oriented web discovery, page contents, and grounded answers.
Prefer it when semantic relevance matters more than a classic result page.
''',
  requiresCredential: true,
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Find relevant web pages for a query.',
      inputJsonSchema: _searchInputSchema,
      requiresCredential: true,
      callback: _search,
    ),
    AppSkillToolDefinition(
      slug: 'contents',
      title: 'Contents',
      description: 'Fetch clean content for a URL.',
      inputJsonSchema: _contentsInputSchema,
      requiresCredential: true,
      callback: _contents,
    ),
    AppSkillToolDefinition(
      slug: 'answer',
      title: 'Answer',
      description: 'Answer a question with web grounding.',
      inputJsonSchema: _answerInputSchema,
      requiresCredential: true,
      callback: _answer,
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

CancelableOperation<Object?> _search(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{'query': textInput(input, 'query')};
  putIfPresent(body, 'type', stringInput(input, 'type'));
  putIfPresent(body, 'numResults', positiveIntInput(input, 'numResults'));
  _putCommonFilters(body, input);
  _putContents(body, input);

  return _post(context, input, 'https://api.exa.ai/search', body);
}

CancelableOperation<Object?> _contents(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{};
  putIfPresent(body, 'urls', stringListInput(input, 'urls'));
  _putContents(body, input);

  return _post(context, input, 'https://api.exa.ai/contents', body);
}

CancelableOperation<Object?> _answer(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{'query': textInput(input, 'question')};
  _putCommonFilters(body, input);

  return _post(context, input, 'https://api.exa.ai/answer', body);
}

CancelableOperation<Object?> _post(
  SkillHttpClient context,
  Map<String, dynamic> input,
  String url,
  Map<String, Object?> body,
) {
  return postJson(context, url, {'x-api-key': apiKey(input)}, body);
}

void _putCommonFilters(Map<String, Object?> body, Map<String, dynamic> input) {
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
  putIfPresent(
    body,
    'startPublishedDate',
    stringInput(input, 'startPublishedDate'),
  );
  putIfPresent(
    body,
    'endPublishedDate',
    stringInput(input, 'endPublishedDate'),
  );
  putIfPresent(body, 'category', stringInput(input, 'category'));
}

void _putContents(Map<String, Object?> body, Map<String, dynamic> input) {
  final contents = <String, Object?>{};
  putIfPresent(contents, 'text', boolInput(input, 'includeText'));
  putIfPresent(contents, 'highlights', boolInput(input, 'includeHighlights'));
  putIfPresent(contents, 'summary', boolInput(input, 'includeSummary'));
  putIfPresent(
    contents,
    'livecrawlTimeout',
    positiveIntInput(input, 'livecrawlTimeout'),
  );
  putIfPresent(contents, 'maxAgeHours', positiveIntInput(input, 'maxAgeHours'));
  putIfPresent(body, 'contents', contents);
}
