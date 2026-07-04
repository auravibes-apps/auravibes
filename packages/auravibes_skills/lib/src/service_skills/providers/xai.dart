import 'package:async/async.dart';
import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_callback.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/service_skills/providers/shared.dart';

const xAiSkill = AppSkillDefinition(
  identifier: 'xai',
  slug: 'xai',
  title: 'xAI',
  description: 'Use xAI tools for web and X search.',
  content: '''
Use xAI when you need web-grounded answers or results from X. Prefer X search
for public posts and account-related queries.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['xai'],
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'web_search',
      title: 'Web search',
      description: 'Answer a question using xAI web search.',
      inputJsonSchema: _webSearchInputSchema,
      requiresCredential: true,
      callback: _webSearch,
    ),
    AppSkillToolDefinition(
      slug: 'x_search',
      title: 'X search',
      description: 'Search public X posts for a query.',
      inputJsonSchema: _xSearchInputSchema,
      requiresCredential: true,
      callback: _xSearch,
    ),
  ],
);

const Map<String, Object> _webSearchInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string'},
    'allowedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludedDomains': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'enableImageUnderstanding': {'type': 'boolean'},
    'enableImageSearch': {'type': 'boolean'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const Map<String, Object> _xSearchInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'model': {'type': 'string'},
    'allowedXHandles': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'excludedXHandles': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'fromDate': {'type': 'string'},
    'toDate': {'type': 'string'},
    'enableVideoUnderstanding': {'type': 'boolean'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _webSearch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return _responses(
    context,
    input,
    _webSearchTool(input),
    textInput(input, 'question'),
  );
}

CancelableOperation<Object?> _xSearch(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  return _responses(
    context,
    input,
    _xSearchTool(input),
    textInput(input, 'query'),
  );
}

CancelableOperation<Object?> _responses(
  SkillHttpClient context,
  Map<String, dynamic> input,
  Map<String, Object?> tool,
  String text,
) {
  return postJson(
    context,
    'https://api.x.ai/v1/responses',
    {'authorization': 'Bearer ${apiKey(input)}'},
    {
      'model': stringInput(input, 'model', defaultValue: 'grok-4'),
      'tools': [tool],
      'input': text,
    },
  );
}

Map<String, Object?> _webSearchTool(Map<String, dynamic> input) {
  final tool = <String, Object?>{'type': 'web_search'};
  putIfPresent(
    tool,
    'allowed_domains',
    stringListInput(input, 'allowedDomains'),
  );
  putIfPresent(
    tool,
    'excluded_domains',
    stringListInput(input, 'excludedDomains'),
  );
  putIfPresent(
    tool,
    'enable_image_understanding',
    boolInput(input, 'enableImageUnderstanding'),
  );
  putIfPresent(
    tool,
    'enable_image_search',
    boolInput(input, 'enableImageSearch'),
  );

  return tool;
}

Map<String, Object?> _xSearchTool(Map<String, dynamic> input) {
  final tool = <String, Object?>{'type': 'x_search'};
  putIfPresent(
    tool,
    'allowed_x_handles',
    stringListInput(input, 'allowedXHandles'),
  );
  putIfPresent(
    tool,
    'excluded_x_handles',
    stringListInput(input, 'excludedXHandles'),
  );
  putIfPresent(tool, 'from_date', stringInput(input, 'fromDate'));
  putIfPresent(tool, 'to_date', stringInput(input, 'toDate'));
  putIfPresent(
    tool,
    'enable_video_understanding',
    boolInput(input, 'enableVideoUnderstanding'),
  );

  return tool;
}
