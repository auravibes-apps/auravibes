import 'package:async/async.dart';
import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_callback.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/service_skills/providers/shared.dart';

const kimiSkill = AppSkillDefinition(
  identifier: 'kimi',
  slug: 'kimi',
  title: 'Kimi / Moonshot',
  description: 'Use Kimi chat with built-in web search.',
  content: '''
Use Kimi when a Moonshot/Kimi model should answer with web help. Prefer it when
the workspace already has Moonshot model credentials.
''',
  requiresCredential: true,
  compatibleModelProviderIds: [
    'moonshotai',
    'moonshotai-cn',
    'kimi-for-coding',
  ],
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'web_search_chat',
      title: 'Web search chat',
      description: 'Answer a question with Kimi web-enabled chat.',
      inputJsonSchema: _webSearchChatInputSchema,
      requiresCredential: true,
      callback: _webSearchChat,
    ),
  ],
);

const Map<String, Object> _webSearchChatInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string'},
    'temperature': {'type': 'number'},
    'maxTokens': {'type': 'integer', 'minimum': 1},
  },
  'required': ['question'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _webSearchChat(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'model': stringInput(input, 'model', defaultValue: 'kimi-k2.6'),
    'thinking': {'type': 'disabled'},
    'tools': [
      {
        'type': 'builtin_function',
        'function': {'name': r'$web_search'},
      },
    ],
    'messages': [
      {'role': 'user', 'content': textInput(input, 'question')},
    ],
  };
  putIfPresent(body, 'temperature', input['temperature']);
  putIfPresent(body, 'max_tokens', positiveIntInput(input, 'maxTokens'));

  return postJson(
    context,
    'https://api.moonshot.ai/v1/chat/completions',
    {'authorization': 'Bearer ${apiKey(input)}'},
    body,
  );
}
