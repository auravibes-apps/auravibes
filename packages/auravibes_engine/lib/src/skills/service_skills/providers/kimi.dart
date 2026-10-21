import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';
import 'package:auravibes_engine/src/skills/service_skills/service_skill_preset.dart';

final kimiSkill = ServiceSkillPreset(
  identifier: 'kimi',
  slug: 'kimi',
  title: 'Kimi / Moonshot',
  description: 'Use Kimi chat with built-in web search.',
  content: '''
Use Kimi when a Moonshot/Kimi model should answer with web help. Prefer it when
the workspace already has Moonshot model credentials.
''',
  compatibleModelProviderIds: [
    'moonshotai',
    'moonshotai-cn',
    'kimi-for-coding',
  ],
  tools: [
    ConnectorToolDefinition(
      slug: 'web_search_chat',
      title: 'Web search chat',
      description: 'Answer a question with Kimi web-enabled chat.',
      inputJsonSchema: _webSearchChatInputSchema,
      requiresConnection: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.moonshot.ai/v1/chat/completions',
        inputSchema: _webSearchChatInputSchema,
        headers: {
          'authorization': 'Bearer {{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: _webSearchChatBody,
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _webSearchChatInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string', 'default': 'kimi-k2.6'},
    'temperature': {'type': 'number'},
    'maxTokens': {'type': 'integer', 'minimum': 1},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const _webSearchChatBody = r'''
{
  "model": {{ input.model | json }},
  "thinking": {"type":"disabled"},
  "tools": [{"type":"builtin_function","function":{"name":"$web_search"}}],
  "messages": [{"role":"user","content":{{ input.question | json }}}]
  {% if input.temperature != nil %},"temperature":{{ input.temperature | json }}{% endif %}
  {% if input.maxTokens != nil %},"max_tokens":{{ input.maxTokens | json }}{% endif %}
}
''';
