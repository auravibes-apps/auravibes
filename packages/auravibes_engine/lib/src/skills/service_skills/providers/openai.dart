import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const openAiSkill = AppSkillDefinition(
  identifier: 'openai',
  slug: 'openai',
  title: 'OpenAI',
  description: 'Use OpenAI web-grounded response tools.',
  content: '''
Use OpenAI when you need a model-generated answer grounded by current web
information. This skill uses OpenAI API credentials.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['openai'],
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Answer a question using OpenAI web grounding.',
      inputJsonSchema: _webSearchInputSchema,
      requiresCredential: true,
      callback: _webSearch,
    ),
  ],
);

const Map<String, Object> _webSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string'},
    'searchContextSize': {
      'type': 'string',
      'enum': ['low', 'medium', 'high'],
    },
    'allowedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'blockedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'country': {'type': 'string'},
    'region': {'type': 'string'},
    'city': {'type': 'string'},
    'timezone': {'type': 'string'},
    'includeImages': {'type': 'boolean'},
    'maxOutputTokens': {'type': 'integer', 'minimum': 1},
  },
  'required': ['question'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _webSearch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final filters = <String, Object>{};
  putIfPresent(
    filters,
    'allowed_domains',
    stringListInput(input, 'allowedDomains'),
  );
  putIfPresent(
    filters,
    'blocked_domains',
    stringListInput(input, 'blockedDomains'),
  );
  final tool = <String, Object?>{'type': 'web_search'};
  putIfPresent(
    tool,
    'search_context_size',
    stringInput(input, 'searchContextSize'),
  );
  putIfPresent(tool, 'filters', filters);
  putIfPresent(tool, 'user_location', approximateLocation(input));
  tool['search_content_types'] = [
    'text',
    if (input['includeImages'] == true) 'image',
  ];
  final body = <String, Object?>{
    'model': stringInput(input, 'model', defaultValue: 'gpt-4.1'),
    'tools': [tool],
    'input': textInput(input, 'question'),
  };
  putIfPresent(
    body,
    'max_output_tokens',
    positiveIntInput(input, 'maxOutputTokens'),
  );

  return postJson(
    context,
    'https://api.openai.com/v1/responses',
    {'authorization': 'Bearer ${apiKey(input)}'},
    body,
  );
}
