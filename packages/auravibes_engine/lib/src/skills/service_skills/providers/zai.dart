import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const zaiSkill = AppSkillDefinition(
  identifier: 'zai',
  slug: 'zai',
  title: 'Z.ai',
  description: 'Search the web and use Z.ai chat web tools.',
  content: '''
Use Z.ai for direct web result lookup or model-assisted web answers. Prefer it
when the workspace already has Z.ai model credentials.
''',
  requiresCredential: true,
  compatibleModelProviderIds: [
    'zai',
    'zai-coding-plan',
    'zhipuai',
    'zhipuai-coding-plan',
  ],
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Search the web for structured results.',
      inputJsonSchema: _webSearchInputSchema,
      requiresCredential: true,
      callback: _directWebSearch,
    ),
    AppSkillToolDefinition(
      slug: 'chat_web_search',
      title: 'Chat web search',
      description: 'Answer a question with Z.ai web-enabled chat.',
      inputJsonSchema: _chatWebSearchInputSchema,
      requiresCredential: true,
      callback: _chatWebSearch,
    ),
  ],
);

const Map<String, Object> _webSearchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'searchEngine': {'type': 'string'},
    'count': {'type': 'integer', 'minimum': 1},
    'searchDomainFilter': {'type': 'string'},
    'searchRecencyFilter': {'type': 'string'},
    'requestId': {'type': 'string'},
    'userId': {'type': 'string'},
    'acceptLanguage': {'type': 'string'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const Map<String, Object> _chatWebSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _directWebSearch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final headers = <String, String>{'authorization': 'Bearer ${apiKey(input)}'};
  if (stringInput(input, 'acceptLanguage') case final language
      when language.isNotEmpty) {
    headers['accept-language'] = language;
  }
  final body = <String, Object?>{'search_query': textInput(input, 'query')};
  putIfPresent(body, 'search_engine', stringInput(input, 'searchEngine'));
  putIfPresent(body, 'count', positiveIntInput(input, 'count'));
  putIfPresent(
    body,
    'search_domain_filter',
    stringInput(input, 'searchDomainFilter'),
  );
  putIfPresent(
    body,
    'search_recency_filter',
    stringInput(input, 'searchRecencyFilter'),
  );
  putIfPresent(body, 'request_id', stringInput(input, 'requestId'));
  putIfPresent(body, 'user_id', stringInput(input, 'userId'));

  return postJson(
    context,
    'https://api.z.ai/api/paas/v4/web_search',
    headers,
    body,
  );
}

CancelableOperation<Object?> _chatWebSearch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return postJson(
    context,
    'https://api.z.ai/api/paas/v4/chat/completions',
    {'authorization': 'Bearer ${apiKey(input)}'},
    {
      'model': stringInput(input, 'model', defaultValue: 'glm-4.5'),
      'tools': [
        {'type': 'web_search'},
      ],
      'messages': [
        {'role': 'user', 'content': textInput(input, 'question')},
      ],
    },
  );
}
