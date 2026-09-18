import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final geminiSkill = AppSkillDefinition(
  identifier: 'gemini',
  slug: 'gemini',
  title: 'Gemini / Google',
  description: 'Answer questions with Google-grounded Gemini responses.',
  content: '''
Use Gemini when a Google-grounded answer is useful. Prefer it for questions
where Google Search grounding or Google model credentials are already desired.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['google'],
  kind: .template,
  tools: [
    AppSkillToolDefinition(
      slug: 'google_search_grounded_answer',
      title: 'Grounded answer',
      description: 'Answer a question with Google search grounding.',
      inputJsonSchema: _groundedAnswerInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://generativelanguage.googleapis.com/v1beta/models/{{ input.model | uri_encode }}:generateContent',
        inputSchema: _groundedAnswerInputSchema,
        headers: {
          'x-goog-api-key': '{{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: '''
{"contents":[{"parts":[{"text":{{ input.question | json }}}]}],
"tools":[{"google_search":{}}]}
''',
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _groundedAnswerInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string', 'default': 'gemini-2.5-flash'},
  },
  'required': ['question'],
  'additionalProperties': false,
};
