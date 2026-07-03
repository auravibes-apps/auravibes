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

  group('SkillUrlTemplate', () {
    test('parses and serializes full JSON template', () {
      final template = SkillUrlTemplate.fromJsonString(
        jsonEncode({
          'url': 'https://example.com/{input:path}',
          'method': 'POST',
          'headers': {'authorization': 'Bearer {credential:apiKey}'},
          'query': {'q': '{input:query}'},
          'body': '{"value":"{input:value}"}',
          'bodyFormat': 'infer',
          'timeoutSeconds': '45',
          'format': 'html',
        }),
      );

      expect(template.url, 'https://example.com/{{ input.path }}');
      expect(template.method, UrlRequestMethod.post);
      expect(template.headers, {
        'authorization': 'Bearer {{ credential.apiKey }}',
      });
      expect(template.query, {'q': '{{ input.query }}'});
      expect(template.body, '{"value":{{ input.value | json }}}');
      expect(template.resolvedBodyFormat, SkillUrlTemplateBodyFormat.json);
      expect(template.timeout, const Duration(seconds: 45));
      expect(template.format, UrlResponseFormat.html);

      expect(template.toJson(), {
        'url': 'https://example.com/{{ input.path }}',
        'method': 'POST',
        'query': {'q': '{{ input.query }}'},
        'headers': {'authorization': 'Bearer {{ credential.apiKey }}'},
        'body': '{"value":{{ input.value | json }}}',
        'bodyFormat': 'json',
        'timeoutSeconds': 45,
        'format': 'html',
      });
      expect(jsonDecode(template.toJsonString()), template.toJson());
    });

    test('defaults and rejects invalid JSON template values', () {
      final template = SkillUrlTemplate.fromJsonString(
        jsonEncode({'url': 'https://example.com', 'body': 'plain text'}),
      );

      expect(template.method, UrlRequestMethod.get);
      expect(template.headers, isEmpty);
      expect(template.query, isEmpty);
      expect(template.timeout, const Duration(seconds: 30));
      expect(template.format, UrlResponseFormat.defaultFormat);
      expect(template.resolvedBodyFormat, SkillUrlTemplateBodyFormat.text);
      expect(template.toJson(), {
        'url': 'https://example.com',
        'method': 'GET',
        'body': 'plain text',
        'bodyFormat': 'text',
      });

      expect(
        () => SkillUrlTemplate.fromJsonString('[]'),
        throwsFormatException,
      );
      expect(
        () => SkillUrlTemplate.fromJsonString(jsonEncode({'url': ''})),
        throwsFormatException,
      );
      expect(
        () => SkillUrlTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'method': 'trace'}),
        ),
        throwsFormatException,
      );
      expect(
        () => SkillUrlTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'headers': []}),
        ),
        throwsFormatException,
      );
      expect(
        () => SkillUrlTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'timeoutSeconds': 0}),
        ),
        throwsFormatException,
      );
      expect(
        () => SkillUrlTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'bodyFormat': 'xml'}),
        ),
        throwsFormatException,
      );
    });
  });

  group('template definition models', () {
    test('parse input and credential definition maps', () {
      final inputs = SkillTemplateInputDefinition.parseMap(
        jsonEncode({
          'query': {'description': 'Search query'},
          'limit': {
            'description': 'Limit',
            'type': 'integer',
            'optional': true,
          },
        }),
      );

      expect(inputs['query']!.description, 'Search query');
      expect(inputs['query']!.type, 'string');
      expect(inputs['query']!.optional, isFalse);
      expect(inputs['limit']!.description, 'Limit');
      expect(inputs['limit']!.type, 'integer');
      expect(inputs['limit']!.optional, isTrue);

      final credentials = SkillCredentialAttributeDefinition.parseMap(
        jsonEncode({
          'apiKey': {'description': 'API key'},
          'baseUrl': {
            'description': 'Instance URL',
            'optional': true,
            'secret': false,
          },
        }),
      );

      expect(credentials['apiKey']!.description, 'API key');
      expect(credentials['apiKey']!.optional, isFalse);
      expect(credentials['apiKey']!.secret, isTrue);
      expect(credentials['baseUrl']!.description, 'Instance URL');
      expect(credentials['baseUrl']!.optional, isTrue);
      expect(credentials['baseUrl']!.secret, isFalse);
    });

    test('reject malformed definition maps', () {
      expect(
        () => SkillTemplateInputDefinition.parseMap('[]'),
        throwsFormatException,
      );
      expect(
        () => SkillTemplateInputDefinition.parseMap(jsonEncode({'q': 'bad'})),
        throwsFormatException,
      );
      expect(
        () => SkillCredentialAttributeDefinition.parseMap('[]'),
        throwsFormatException,
      );
      expect(
        () => SkillCredentialAttributeDefinition.parseMap(
          jsonEncode({'apiKey': 'bad'}),
        ),
        throwsFormatException,
      );
    });
  });

  group('UrlResponseFormat', () {
    test('parses labels and exposes accept headers', () {
      expect(UrlResponseFormat.fromString(''), UrlResponseFormat.defaultFormat);
      expect(
        UrlResponseFormat.fromString('markdown'),
        UrlResponseFormat.markdown,
      );
      expect(UrlResponseFormat.fromString('TEXT'), UrlResponseFormat.text);
      expect(UrlResponseFormat.fromString(' html '), UrlResponseFormat.html);
      expect(
        UrlResponseFormat.markdown.acceptHeader,
        contains('text/markdown'),
      );
      expect(UrlResponseFormat.text.acceptHeader, contains('text/plain'));
      expect(UrlResponseFormat.html.acceptHeader, contains('text/html'));
      expect(
        () => UrlResponseFormat.fromString('json'),
        throwsFormatException,
      );
    });
  });
}
