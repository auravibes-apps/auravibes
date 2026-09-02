import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/url_request_method.dart';
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
  nativeTools: [
    const AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search for web results and excerpts.',
      inputJsonSchema: _searchInputSchema,
      requiresCredential: true,
      callback: _search,
    ),
    const AppSkillToolDefinition(
      slug: 'extract',
      title: 'Extract',
      description: 'Extract content from a URL.',
      inputJsonSchema: _extractInputSchema,
      requiresCredential: true,
      callback: _extract,
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
        questionInputs,
      ),
    ),
  ],
);

AppSkillUrlTemplate _template(
  String url,
  String body,
  Map<String, SkillTemplateInputDefinition> inputs,
) {
  return AppSkillUrlTemplate(
    template: SkillUrlTemplate(
      url: url,
      method: UrlRequestMethod.post,
      headers: {
        'x-api-key': '{{ credential.apiKey }}',
        'content-type': 'application/json',
      },
      body: body,
    ),
    inputs: inputs,
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

CancelableOperation<Object?> _search(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final searchQueries = stringListInput(input, 'searchQueries');
  final body = <String, Object?>{
    'search_queries': searchQueries ?? [textInput(input, 'query')],
    'max_chars_total': positiveIntInput(input, 'maxCharsTotal') ?? 6000,
  };
  putIfPresent(body, 'mode', stringInput(input, 'mode'));
  putIfPresent(body, 'session_id', stringInput(input, 'sessionId'));
  putIfPresent(body, 'client_model', stringInput(input, 'clientModel'));
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
  putIfPresent(body, 'after_date', stringInput(input, 'afterDate'));
  putIfPresent(body, 'max_age_seconds', _maxAgeSecondsInput(input));
  putIfPresent(
    body,
    'timeout_seconds',
    positiveIntInput(input, 'timeoutSeconds'),
  );
  putIfPresent(
    body,
    'disable_cache_fallback',
    boolInput(input, 'disableCacheFallback'),
  );
  putIfPresent(
    body,
    'max_chars_per_result',
    positiveIntInput(input, 'maxCharsPerResult'),
  );
  putIfPresent(body, 'location', stringInput(input, 'location'));
  putIfPresent(body, 'max_results', positiveIntInput(input, 'maxResults'));
  putIfPresent(body, 'objective', stringInput(input, 'objective'));
  return _post(context, input, 'search', body);
}

int? _maxAgeSecondsInput(Map<String, dynamic> input) {
  final value = input['maxAgeSeconds'];
  return value is int && value >= 0 ? value : null;
}

CancelableOperation<Object?> _extract(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'urls': stringListInput(input, 'urls') ?? const [],
  };
  putIfPresent(body, 'max_chars', positiveIntInput(input, 'maxChars'));
  putIfPresent(
    body,
    'max_chars_total',
    positiveIntInput(input, 'maxCharsTotal'),
  );
  putIfPresent(
    body,
    'timeout_seconds',
    positiveIntInput(input, 'timeoutSeconds'),
  );
  return _post(context, input, 'extract', body);
}

CancelableOperation<Object?> _post(
  SkillHttpClient context,
  Map<String, dynamic> input,
  String tool,
  Map<String, Object?> body,
) {
  return postJson(context, 'https://api.parallel.ai/v1/$tool', {
    'x-api-key': apiKey(input),
  }, body);
}
