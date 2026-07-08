import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const geminiSkill = AppSkillDefinition(
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
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'google_search_grounded_answer',
      title: 'Grounded answer',
      description: 'Answer a question with Google search grounding.',
      inputJsonSchema: _groundedAnswerInputSchema,
      requiresCredential: true,
      callback: _groundedAnswer,
    ),
  ],
);

const Map<String, Object> _groundedAnswerInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'model': {'type': 'string'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

CancelableOperation<Object?> _groundedAnswer(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final model = Uri.encodeComponent(
    stringInput(input, 'model', defaultValue: 'gemini-2.5-flash'),
  );
  return postJson(
    context,
    'https://generativelanguage.googleapis.com/v1beta/models/'
    '$model:generateContent',
    {'x-goog-api-key': apiKey(input)},
    {
      'contents': [
        {
          'parts': [
            {'text': textInput(input, 'question')},
          ],
        },
      ],
      'tools': [
        {'google_search': <String, Object?>{}},
      ],
    },
  );
}
