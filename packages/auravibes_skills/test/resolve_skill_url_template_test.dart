import 'dart:convert';

import 'package:auravibes_skills/auravibes_skills.dart';
import 'package:test/test.dart';

void main() {
  group('ResolveSkillUrlTemplate', () {
    const resolver = ResolveSkillUrlTemplate();

    test('drops blank optional query and header values', () {
      final request = resolver(
        template: const SkillUrlTemplate(
          url: 'https://example.com/search?format=json',
          headers: {'authorization': '{{ credential.apiKey }}'},
          query: {'q': '{{ input.query }}', 'count': '{{ input.count }}'},
        ),
        inputs: {'query': 'flutter'},
        credentials: const {},
        inputDefinitions: const {
          'query': SkillTemplateInputDefinition(description: 'Query'),
          'count': SkillTemplateInputDefinition(
            description: 'Count',
            type: 'integer',
            optional: true,
          ),
        },
        credentialDefinitions: const {
          'apiKey': SkillCredentialAttributeDefinition(
            description: 'API key',
            optional: true,
          ),
        },
      );

      expect(request.url, 'https://example.com/search?format=json&q=flutter');
      expect(request.headers, isEmpty);
    });

    test('preserves typed JSON placeholders in body', () {
      final request = resolver(
        template: const SkillUrlTemplate(
          url: 'https://example.com/search',
          method: UrlRequestMethod.post,
          body: '{"query":"{input:query}","limit":"{input:limit}"}',
          bodyFormat: SkillUrlTemplateBodyFormat.json,
        ),
        inputs: {'query': 'dart', 'limit': 3},
        credentials: const {},
        inputDefinitions: const {
          'query': SkillTemplateInputDefinition(description: 'Query'),
          'limit': SkillTemplateInputDefinition(
            description: 'Limit',
            type: 'integer',
          ),
        },
      );

      expect(jsonDecode(request.body!), {'query': 'dart', 'limit': 3});
    });

    test('throws for missing required input', () {
      expect(
        () => resolver(
          template: const SkillUrlTemplate(
            url: 'https://example.com/',
            query: {'q': '{{ input.query }}'},
          ),
          inputs: const {},
          credentials: const {},
          inputDefinitions: const {
            'query': SkillTemplateInputDefinition(description: 'Query'),
          },
        ),
        throwsFormatException,
      );
    });
  });
}
