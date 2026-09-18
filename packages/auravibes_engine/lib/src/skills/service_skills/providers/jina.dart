import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final jinaSkill = AppSkillDefinition(
  identifier: 'jina',
  slug: 'jina',
  title: 'Jina',
  description: 'Read pages, search web content, and rerank documents.',
  content: '''
Use Jina for clean page reads, web-searchable content, and reranking candidate
documents against a query.
  ''',
  requiresCredential: true,
  kind: .template,
  tools: [
    const AppSkillToolDefinition(
      slug: 'reader_fetch',
      title: 'Reader fetch',
      description: 'Fetch clean readable content from a URL.',
      inputJsonSchema: fetchInputSchema,
      urlTemplate: .new(
        template: SkillUrlTemplate(url: 'https://r.jina.ai/{{ input.url }}'),
        inputs: urlInputs,
      ),
    ),
    const AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search clean web content for a query.',
      inputJsonSchema: searchInputSchema,
      requiresCredential: true,
      urlTemplate: .new(
        template: SkillUrlTemplate(
          url: 'https://s.jina.ai/',
          headers: {'authorization': 'Bearer {{ credential.apiKey }}'},
          query: {'q': '{{ input.query }}'},
        ),
        inputs: queryInputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'rerank',
      title: 'Rerank',
      description: 'Rerank candidate documents against a query.',
      inputJsonSchema: _rerankInputSchema,
      requiresCredential: true,
      urlTemplate: declarativeTemplate(
        url: 'https://api.jina.ai/v1/rerank',
        inputSchema: _rerankInputSchema,
        headers: {
          'authorization': 'Bearer {{ credential.apiKey }}',
          'content-type': 'application/json',
        },
        body: '''
{"query":{{ input.query | json }},"documents":{{ input.documents | json }}
{% if input.model != nil %},"model":{{ input.model | json }}{% endif %}
{% if input.topN != nil %},"top_n":{{ input.topN | json }}{% endif %}}
''',
        bodyFormat: .json,
      ),
    ),
  ],
);

const Map<String, Object> _rerankInputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'documents': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'model': {'type': 'string'},
    'topN': {'type': 'integer', 'minimum': 1},
  },
  'required': ['query', 'documents'],
  'additionalProperties': false,
};
