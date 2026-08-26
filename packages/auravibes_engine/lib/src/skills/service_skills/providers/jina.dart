import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_callback.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const jinaSkill = AppSkillDefinition(
  identifier: 'jina',
  slug: 'jina',
  title: 'Jina',
  description: 'Read pages, search web content, and rerank documents.',
  content: '''
Use Jina for clean page reads, web-searchable content, and reranking candidate
documents against a query.
''',
  requiresCredential: true,
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'reader_fetch',
      title: 'Reader fetch',
      description: 'Fetch clean readable content from a URL.',
      inputJsonSchema: fetchInputSchema,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(url: 'https://r.jina.ai/{{ input.url }}'),
        inputs: urlInputs,
      ),
    ),
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search clean web content for a query.',
      inputJsonSchema: searchInputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
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
      callback: _rerank,
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

CancelableOperation<Object?> _rerank(
  Map<String, dynamic> input,
  SkillHttpClient context,
) {
  final body = <String, Object?>{
    'query': textInput(input, 'query'),
    'documents': stringListInput(input, 'documents') ?? const [],
  };
  putIfPresent(body, 'model', stringInput(input, 'model'));
  putIfPresent(body, 'top_n', positiveIntInput(input, 'topN'));

  return postJson(context, 'https://api.jina.ai/v1/rerank', {
    'authorization': 'Bearer ${apiKey(input)}',
  }, body);
}
