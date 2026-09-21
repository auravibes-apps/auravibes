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
  resources: const [
    AppSkillResourceDefinition(
      slug: 'reader_url_and_document_modes',
      title: 'Reader URL and document modes',
      description: 'Pass original URLs and use Reader for known pages or PDFs.',
      content: '''
`reader_fetch` expects the original target URL. The template adds the Reader
prefix, so do not pass a prebuilt Reader URL.

```json
{"url":"<page-or-pdf-url>"}
```

Reader returns cleaned Markdown and can read PDFs. Use it for a known page;
use `search` when the URL is not known yet, then pass the selected URL to
`reader_fetch` unchanged.

```json
{"query":"Flutter plugin compatibility breaking changes"}
```
''',
    ),
    AppSkillResourceDefinition(
      slug: 'rerank_document_contract',
      title: 'Rerank document contract',
      description:
          'Give Jina comparable strings and use topN as a result count.',
      content: '''
`rerank.documents` must contain passages as strings, not URLs or result
objects. Include a source label in each string if the winning passage needs
traceability.

```json
{
  "query":"requirements for offline synchronization",
  "documents":[
    "Source A: offline writes queue locally and replay after reconnect.",
    "Source B: synchronization requires a live connection before writes."
  ],
  "topN":1
}
```

`topN` is the maximum number of passages returned, not a relevance threshold;
keep it no larger than the document count. Split long pages into comparable
passages before calling `rerank`.
''',
    ),
  ],
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
