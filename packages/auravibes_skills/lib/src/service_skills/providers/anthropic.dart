import 'package:async/async.dart';
import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_callback.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/service_skills/providers/shared.dart';

const anthropicSkill = AppSkillDefinition(
  identifier: 'anthropic',
  slug: 'anthropic',
  title: 'Anthropic',
  description: 'Use Claude web access tools for grounded answers.',
  content: '''
Use Anthropic when Claude should answer with current web information or inspect
a public URL. Prefer it when the conversation already uses Anthropic models.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['anthropic'],
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Answer a question using Claude web search.',
      inputJsonSchema: _webSearchInputSchema,
      requiresCredential: true,
      callback: _webSearch,
    ),
    AppSkillToolDefinition(
      slug: 'web_fetch',
      title: 'Web fetch',
      description: 'Ask Claude to inspect and summarize a public URL.',
      inputJsonSchema: _webFetchInputSchema,
      requiresCredential: true,
      callback: _webFetch,
    ),
  ],
);

const Map<String, Object> _webSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string'},
    'maxUses': {'type': 'integer', 'minimum': 1},
    'allowedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'blockedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'responseInclusion': {'type': 'string'},
    'country': {'type': 'string'},
    'region': {'type': 'string'},
    'city': {'type': 'string'},
    'timezone': {'type': 'string'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const Map<String, Object> _webFetchInputSchema = {
  'type': 'object',
  'properties': {
    'url': {'type': 'string'},
    'model': {'type': 'string'},
  },
  'required': ['url'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _webSearch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return _message(context, input, textInput(input, 'question'));
}

CancelableOperation<Object?> _webFetch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return _message(
    context,
    input,
    'Fetch and summarize: ${textInput(input, 'url')}',
  );
}

CancelableOperation<Object?> _message(
  SkillHttpClient context,
  Map<String, dynamic> input,
  String text,
) {
  return postJson(
    context,
    'https://api.anthropic.com/v1/messages',
    {
      'x-api-key': apiKey(input),
      'anthropic-version': '2023-06-01',
    },
    {
      'model': stringInput(
        input,
        'model',
        defaultValue: 'claude-sonnet-4-20250514',
      ),
      'max_tokens': 1024,
      'tools': [_webSearchTool(input)],
      'messages': [
        {'role': 'user', 'content': text},
      ],
    },
  );
}

Map<String, Object?> _webSearchTool(Map<String, dynamic> input) {
  final tool = <String, Object?>{
    'type': 'web_search_20260318',
    'name': 'web_search',
  };
  putIfPresent(tool, 'max_uses', positiveIntInput(input, 'maxUses'));
  putIfPresent(
    tool,
    'allowed_domains',
    stringListInput(input, 'allowedDomains'),
  );
  putIfPresent(
    tool,
    'blocked_domains',
    stringListInput(input, 'blockedDomains'),
  );
  putIfPresent(
    tool,
    'response_inclusion',
    stringInput(input, 'responseInclusion'),
  );
  putIfPresent(tool, 'user_location', approximateLocation(input));

  return tool;
}
