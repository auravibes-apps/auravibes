import 'package:async/async.dart';
import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_callback.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_url_template.dart';
import 'package:auravibes_skills/src/models/skill_url_template.dart';
import 'package:auravibes_skills/src/service_skills/providers/shared.dart';

const kagiSkill = AppSkillDefinition(
  identifier: 'kagi',
  slug: 'kagi',
  title: 'Kagi',
  description: 'Search, answer, enrich, and summarize web content.',
  content: '''
Use Kagi for high-quality search results, concise grounded answers,
enrichment, and summarization.
''',
  requiresCredential: true,
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search the web with Kagi.',
      inputJsonSchema: searchInputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: 'https://kagi.com/api/v1/search',
          headers: {'authorization': 'Bot {{ credential.apiKey }}'},
          query: {'q': '{{ input.query }}'},
        ),
        inputs: queryInputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'fastgpt',
      title: 'FastGPT',
      description: 'Answer a question using Kagi references.',
      inputJsonSchema: _fastGptInputSchema,
      requiresCredential: true,
      callback: _fastGpt,
    ),
    AppSkillToolDefinition(
      slug: 'enrich',
      title: 'Enrich',
      description: 'Find enriched web information for a query.',
      inputJsonSchema: searchInputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: 'https://kagi.com/api/v0/enrich/web',
          headers: {'authorization': 'Bot {{ credential.apiKey }}'},
          query: {'q': '{{ input.query }}'},
        ),
        inputs: queryInputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'summarize',
      title: 'Summarize',
      description: 'Summarize content from a URL.',
      inputJsonSchema: _summarizeInputSchema,
      requiresCredential: true,
      callback: _summarize,
    ),
  ],
);

const Map<String, Object> _fastGptInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'cache': {'type': 'boolean'},
    'webSearch': {'type': 'boolean'},
  },
  'required': ['question'],
  'additionalProperties': false,
};

const Map<String, Object> _summarizeInputSchema = {
  'type': 'object',
  'properties': {
    'url': {'type': 'string'},
    'text': {'type': 'string'},
    'engine': {'type': 'string'},
    'summaryType': {'type': 'string'},
    'targetLanguage': {'type': 'string'},
    'cache': {'type': 'boolean'},
  },
  'additionalProperties': false,
};

CancelableOperation<Object?> _fastGpt(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'query': textInput(input, 'question'),
    'web_search': boolInput(input, 'webSearch') ?? true,
  };
  putIfPresent(body, 'cache', boolInput(input, 'cache'));

  return _post(context, input, 'https://kagi.com/api/v0/fastgpt', body);
}

CancelableOperation<Object?> _summarize(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{};
  putIfPresent(body, 'url', stringInput(input, 'url'));
  putIfPresent(body, 'text', stringInput(input, 'text'));
  putIfPresent(body, 'engine', stringInput(input, 'engine'));
  putIfPresent(body, 'summary_type', stringInput(input, 'summaryType'));
  putIfPresent(body, 'target_language', stringInput(input, 'targetLanguage'));
  putIfPresent(body, 'cache', boolInput(input, 'cache'));

  return _post(context, input, 'https://kagi.com/api/v0/summarize', body);
}

CancelableOperation<Object?> _post(
  SkillHttpClient context,
  Map<String, dynamic> input,
  String url,
  Map<String, Object?> body,
) {
  return postJson(context, url, {
    'authorization': 'Bot ${apiKey(input)}',
  }, body);
}
