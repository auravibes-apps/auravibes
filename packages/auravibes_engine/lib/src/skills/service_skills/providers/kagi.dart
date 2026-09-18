import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final kagiSkill = AppSkillDefinition(
  identifier: 'kagi',
  slug: 'kagi',
  title: 'Kagi',
  description: 'Search, answer, enrich, and summarize web content.',
  content: '''
Use Kagi for high-quality search results, concise grounded answers,
enrichment, and summarization.
  ''',
  requiresCredential: true,
  kind: .template,
  tools: [
    const AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search the web with Kagi.',
      inputJsonSchema: searchInputSchema,
      requiresCredential: true,
      urlTemplate: .new(
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
      urlTemplate: declarativeTemplate(
        url: 'https://kagi.com/api/v0/fastgpt',
        inputSchema: _fastGptInputSchema,
        headers: {
          'authorization': 'Bot {{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: '''
{"query":{{ input.question | json }},"web_search":{{ input.webSearch | json }}
{% if input.cache != nil %},"cache":{{ input.cache | json }}{% endif %}}
''',
        bodyFormat: .json,
      ),
    ),
    const AppSkillToolDefinition(
      slug: 'enrich',
      title: 'Enrich',
      description: 'Find enriched web information for a query.',
      inputJsonSchema: searchInputSchema,
      requiresCredential: true,
      urlTemplate: .new(
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
      urlTemplate: declarativeTemplate(
        url: 'https://kagi.com/api/v0/summarize',
        inputSchema: _summarizeInputSchema,
        headers: {
          'authorization': 'Bot {{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: '''
{
{% if input.url != nil %}"url":{{ input.url | json }}{% endif %}
{% if input.text != nil %}{% if input.url != nil %},{% endif %}"text":{{ input.text | json }}{% endif %}
{% if input.engine != nil %},{% endif %}{% if input.engine != nil %}"engine":{{ input.engine | json }}{% endif %}
{% if input.summaryType != nil %},{% endif %}{% if input.summaryType != nil %}"summary_type":{{ input.summaryType | json }}{% endif %}
{% if input.targetLanguage != nil %},{% endif %}{% if input.targetLanguage != nil %}"target_language":{{ input.targetLanguage | json }}{% endif %}
{% if input.cache != nil %},{% endif %}{% if input.cache != nil %}"cache":{{ input.cache | json }}{% endif %}}
''',
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _fastGptInputSchema = {
  'type': 'object',
  'properties': {
    'question': {'type': 'string'},
    'cache': {'type': 'boolean'},
    'webSearch': {'type': 'boolean', 'default': true},
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
  'anyOf': [
    {
      'required': ['url'],
    },
    {
      'required': ['text'],
    },
  ],
  'additionalProperties': false,
};
