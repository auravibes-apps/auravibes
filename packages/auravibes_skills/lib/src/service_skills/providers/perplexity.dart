import 'package:async/async.dart';
import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_callback.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/service_skills/providers/shared.dart';

const perplexitySkill = AppSkillDefinition(
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
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search the web for ranked results.',
      inputJsonSchema: _searchInputSchema,
      requiresCredential: true,
      callback: _search,
    ),
    AppSkillToolDefinition(
      slug: 'sonar_answer',
      title: 'Sonar answer',
      description: 'Answer a question with web citations.',
      inputJsonSchema: _sonarInputSchema,
      requiresCredential: true,
      callback: _sonar,
    ),
    AppSkillToolDefinition(
      slug: 'agent',
      title: 'Agent',
      description: 'Run a Perplexity agent workflow for a question.',
      inputJsonSchema: _agentInputSchema,
      requiresCredential: true,
      callback: _agent,
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
    'model': {'type': 'string'},
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
    'maxSteps': {'type': 'integer', 'minimum': 1},
    'tools': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['question'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _search(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{'query': textInput(input, 'query')};
  putIfPresent(body, 'max_results', positiveIntInput(input, 'maxResults'));
  putIfPresent(body, 'country', stringInput(input, 'country'));
  putIfPresent(body, 'search_language_filter', stringInput(input, 'language'));
  putIfPresent(
    body,
    'search_domain_filter',
    stringListInput(input, 'includeDomains'),
  );
  putIfPresent(
    body,
    'exclude_domains',
    stringListInput(input, 'excludeDomains'),
  );
  putIfPresent(
    body,
    'search_context_size',
    stringInput(input, 'searchContextSize'),
  );
  putIfPresent(body, 'max_tokens', positiveIntInput(input, 'maxTokens'));
  putIfPresent(
    body,
    'max_tokens_per_page',
    positiveIntInput(input, 'maxTokensPerPage'),
  );
  putIfPresent(body, 'start_date', stringInput(input, 'startDate'));
  putIfPresent(body, 'end_date', stringInput(input, 'endDate'));
  putIfPresent(
    body,
    'search_recency_filter',
    stringInput(input, 'searchRecencyFilter'),
  );

  return _post(context, input, 'https://api.perplexity.ai/search', body);
}

CancelableOperation<Object?> _sonar(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'model': stringInput(input, 'model', defaultValue: 'sonar'),
    'messages': [
      {'role': 'user', 'content': textInput(input, 'question')},
    ],
  };
  putIfPresent(body, 'search_mode', stringInput(input, 'searchMode'));
  putIfPresent(body, 'return_images', boolInput(input, 'returnImages'));
  putIfPresent(
    body,
    'return_related_questions',
    boolInput(input, 'returnRelatedQuestions'),
  );
  putIfPresent(body, 'disable_search', boolInput(input, 'disableSearch'));
  putIfPresent(
    body,
    'enable_search_classifier',
    boolInput(input, 'enableSearchClassifier'),
  );
  if (stringInput(input, 'searchContextSize') case final size
      when size.isNotEmpty) {
    body['web_search_options'] = {'search_context_size': size};
  }

  return _post(context, input, 'https://api.perplexity.ai/v1/sonar', body);
}

CancelableOperation<Object?> _agent(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final tools = stringListInput(input, 'tools') ?? const ['web_search'];
  return postJson(
    context,
    'https://api.perplexity.ai/v1/agent',
    {'authorization': 'Bearer ${apiKey(input)}'},
    {
      'messages': [
        {'role': 'user', 'content': textInput(input, 'question')},
      ],
      'tools': [
        for (final tool in tools) {'type': tool},
      ],
      'max_steps': positiveIntInput(input, 'maxSteps') ?? 10,
    },
  );
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
