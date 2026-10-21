import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  group('connector tool template validation', () {
    test('omits explicit null values for optional inputs', () {
      const definitions = {
        'region': ConnectorToolInputDefinition(
          description: 'Region',
          optional: true,
        ),
      };

      expect(
        normalizeConnectorToolInputs({'region': null}, definitions),
        isEmpty,
      );
    });

    test('omits explicit null values for optional nested inputs', () {
      const definitions = {
        'filters': ConnectorToolInputDefinition(
          description: 'Filters',
          type: 'object',
          additionalProperties: false,
          properties: {
            'region': ConnectorToolInputDefinition(
              description: 'Region',
              optional: true,
            ),
          },
        ),
      };

      expect(
        normalizeConnectorToolInputs({
          'filters': {'region': null},
        }, definitions),
        {'filters': <String, Object?>{}},
      );
    });

    test('preserves validation classification and canonical JSON', () {
      void validateBody(String body, {String? bodyFormat}) {
        validateConnectorToolRequestDefinition(
          ConnectorToolRequestDefinition.fromLegacyJson(
            templateJson: jsonEncode({
              'url': 'https://example.com',
              'body': body,
              'bodyFormat': ?bodyFormat,
            }),
            inputsJson: jsonEncode({
              'filters': {'description': 'Filters', 'type': 'array'},
              'location': {
                'description': 'Optional location',
                'optional': true,
              },
            }),
          ),
        );
      }

      expect(
        () => validateBody('{"filters":{{filters}}}'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported Liquid reference'),
          ),
        ),
      );
      expect(
        () => validateBody('{"filters":{input:filters}}'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => validateBody('{"filters":"{input:missing}"}'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Unknown input placeholder: missing'),
          ),
        ),
      );
      expect(
        () => validateBody('{"filters":"{{ input.filters }}"}'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('must use the json filter'),
          ),
        ),
      );
      expect(
        () => validateBody(
          [
            '{"q":"cats",',
            '{% if input.location %}',
            '"location":{{ input.location | json }}',
            '{% endif %}',
            '}',
          ].join(),
          bodyFormat: 'json',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Rendered JSON body is invalid'),
          ),
        ),
      );
      expect(
        () => validateConnectorToolRequestDefinition(
          ConnectorToolRequestDefinition.fromLegacyJson(
            templateJson: jsonEncode({
              'url': 'https://example.com/{{ input.connectionId }}',
            }),
            inputsJson: jsonEncode({
              'connectionId': {'description': 'Connection id'},
            }),
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('connectionId is reserved'),
          ),
        ),
      );
      expect(
        ConnectorRequestTemplate.fromJsonString(
          jsonEncode({
            'url': 'https://example.com/{input:query}',
            'body': '{"query":"{input:query}"}',
          }),
        ).toJsonString(),
        [
          '{"url":"https://example.com/{{ input.query }}","method":"GET",',
          r'"body":"{\"query\":{{ input.query | json }}}",',
          '"bodyFormat":"json"}',
        ].join(),
      );
    });
  });

  group('ResolveConnectorRequestTemplate', () {
    const resolver = ResolveConnectorRequestTemplate();

    test('drops blank optional query and header values', () {
      final request = resolver(
        template: const ConnectorRequestTemplate(
          url: 'https://example.com/search?format=json',
          headers: {'authorization': '{{ credential.apiKey }}'},
          query: {'q': '{{ input.query }}', 'count': '{{ input.count }}'},
        ),
        inputs: {'query': 'flutter'},
        credentials: const {},
        inputDefinitions: const {
          'query': ConnectorToolInputDefinition(description: 'Query'),
          'count': ConnectorToolInputDefinition(
            description: 'Count',
            type: 'integer',
            optional: true,
          ),
        },
        credentialDefinitions: const {
          'apiKey': ConnectorCredentialAttributeDefinition(
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
        template: const ConnectorRequestTemplate(
          url: 'https://example.com/search',
          method: .post,
          body: '{"query":"{input:query}","limit":"{input:limit}"}',
          bodyFormat: .json,
        ),
        inputs: {'query': 'dart', 'limit': 3},
        credentials: const {},
        inputDefinitions: const {
          'query': ConnectorToolInputDefinition(description: 'Query'),
          'limit': ConnectorToolInputDefinition(
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
          template: const ConnectorRequestTemplate(
            url: 'https://example.com/',
            query: {'q': '{{ input.query }}'},
          ),
          inputs: const {},
          credentials: const {},
          inputDefinitions: const {
            'query': ConnectorToolInputDefinition(description: 'Query'),
          },
        ),
        throwsFormatException,
      );
    });

    test('keeps repeated and concurrent renders isolated', () async {
      UrlRequest resolve(String query) => resolver(
        template: const ConnectorRequestTemplate(
          url: 'https://example.com/',
          query: {'q': '{{ input.query }}'},
        ),
        inputs: {'query': query},
        credentials: const {},
        inputDefinitions: const {
          'query': ConnectorToolInputDefinition(description: 'Query'),
        },
      );

      expect(resolve('first').url, 'https://example.com/?q=first');
      final requests = await Future.wait([
        Future(() => resolve('second')),
        Future(() => resolve('third')),
      ]);

      expect(requests.map((request) => request.url), [
        'https://example.com/?q=second',
        'https://example.com/?q=third',
      ]);
      expect(resolve('last').url, 'https://example.com/?q=last');
    });

    test('renders form bodies with URL encoding and defaults', () {
      final request = resolver(
        template: const ConnectorRequestTemplate(
          url: 'https://example.com/search',
          method: .post,
          body:
              'q={{ input.query | url_encode }}'
              '${"&"}region={{ input.region | url_encode }}',
          bodyFormat: .form,
        ),
        inputs: {'query': 'a & b'},
        credentials: const {},
        inputDefinitions: const {
          'query': ConnectorToolInputDefinition(description: 'Query'),
          'region': ConnectorToolInputDefinition(
            description: 'Region',
            optional: true,
            defaultValue: 'us-en',
          ),
        },
      );

      expect(request.body, contains('a+%26+b'));
      expect(request.body, contains('region=us-en'));
      expect(request.format, UrlResponseFormat.defaultFormat);
    });

    test('rejects unknown and invalid typed inputs', () {
      const definitions = {
        'limit': ConnectorToolInputDefinition(
          description: 'Limit',
          type: 'integer',
          minimum: 1,
          maximum: 10,
        ),
        'options': ConnectorToolInputDefinition(
          description: 'Options',
          type: 'object',
          properties: {
            'mode': ConnectorToolInputDefinition(
              description: 'Mode',
              enumValues: ['fast', 'deep'],
            ),
          },
        ),
      };

      expect(
        () => normalizeConnectorToolInputs({
          'limit': 2,
          'unknown': true,
        }, definitions),
        throwsFormatException,
      );
      expect(
        () => normalizeConnectorToolInputs({'limit': 11}, definitions),
        throwsFormatException,
      );
      expect(
        () => normalizeConnectorToolInputs({
          'limit': 2,
          'options': {'unexpected': true},
        }, definitions),
        throwsFormatException,
      );
    });
  });

  group('ConnectorRequestTemplate', () {
    test('parses and serializes full JSON template', () {
      final template = ConnectorRequestTemplate.fromJsonString(
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
      expect(template.resolvedBodyFormat, ConnectorRequestBodyFormat.json);
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
      final template = ConnectorRequestTemplate.fromJsonString(
        jsonEncode({'url': 'https://example.com', 'body': 'plain text'}),
      );

      expect(template.method, UrlRequestMethod.get);
      expect(template.headers, isEmpty);
      expect(template.query, isEmpty);
      expect(template.timeout, const Duration(seconds: 30));
      expect(template.format, UrlResponseFormat.defaultFormat);
      expect(template.resolvedBodyFormat, ConnectorRequestBodyFormat.text);
      expect(template.toJson(), {
        'url': 'https://example.com',
        'method': 'GET',
        'body': 'plain text',
        'bodyFormat': 'text',
      });

      expect(
        () => ConnectorRequestTemplate.fromJsonString('[]'),
        throwsFormatException,
      );
      expect(
        () => ConnectorRequestTemplate.fromJsonString(jsonEncode({'url': ''})),
        throwsFormatException,
      );
      expect(
        () => ConnectorRequestTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'method': 'trace'}),
        ),
        throwsFormatException,
      );
      expect(
        () => ConnectorRequestTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'headers': <String>[]}),
        ),
        throwsFormatException,
      );
      expect(
        () => ConnectorRequestTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'timeoutSeconds': 0}),
        ),
        throwsFormatException,
      );
      expect(
        () => ConnectorRequestTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'body': <String>[]}),
        ),
        throwsFormatException,
      );
      expect(
        () => ConnectorRequestTemplate.fromJsonString(
          jsonEncode({
            'url': 'https://example.com',
            'headers': {'x-count': 1},
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => ConnectorRequestTemplate.fromJsonString(
          jsonEncode({
            'url': 'https://example.com',
            'query': {'q': <String>[]},
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => ConnectorRequestTemplate.fromJsonString(
          jsonEncode({'url': 'https://example.com', 'bodyFormat': 'xml'}),
        ),
        throwsFormatException,
      );
    });
  });

  group('template definition models', () {
    test('parse input and credential definition maps', () {
      final inputs = ConnectorToolInputDefinition.parseMap(
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

      final credentials = ConnectorCredentialAttributeDefinition.parseMap(
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
        () => ConnectorToolInputDefinition.parseMap('[]'),
        throwsFormatException,
      );
      expect(
        () => ConnectorToolInputDefinition.parseMap(jsonEncode({'q': 'bad'})),
        throwsFormatException,
      );
      expect(
        () => ConnectorCredentialAttributeDefinition.parseMap('[]'),
        throwsFormatException,
      );
      expect(
        () => ConnectorCredentialAttributeDefinition.parseMap(
          jsonEncode({'apiKey': 'bad'}),
        ),
        throwsFormatException,
      );
    });

    test('round-trips a strict versioned manifest', () {
      final definition = ConnectorToolRequestDefinition.fromJsonMap({
        'version': 1,
        'inputSchema': {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
          'required': ['query'],
          'additionalProperties': false,
        },
        'request': {'url': 'https://example.com/search', 'method': 'GET'},
        'credentialSchema': {
          'apiKey': {'description': 'API key'},
        },
      });

      validateConnectorToolRequestDefinition(definition);
      final manifest = Map<String, Object?>.from(
        jsonDecode(definition.toJsonString()) as Map,
      );
      expect(manifest['version'], 1);
      expect(definition.inputs['query']!.optional, isFalse);
      expect(
        () => ConnectorToolRequestDefinition.fromJsonMap({
          ...manifest,
          'unexpected': true,
        }),
        throwsFormatException,
      );
    });

    test('renders a redacted request preview without sending it', () {
      const definition = ConnectorToolRequestDefinition(
        request: ConnectorRequestTemplate(
          url: 'https://example.com/search',
          headers: {'authorization': 'Bearer {{ credential.apiKey }}'},
          query: {'token': '{{ credential.apiKey }}'},
          body: '''
{"query":{{ input.query | json }},
"token":{{ credential.apiKey | json }}}
''',
          bodyFormat: .json,
        ),
        inputs: {'query': ConnectorToolInputDefinition(description: 'Query')},
        credentialDefinitions: {
          'apiKey': ConnectorCredentialAttributeDefinition(
            description: 'API key',
          ),
        },
      );

      final preview = renderConnectorToolRequestPreview(
        definition: definition,
        inputs: const {'query': 'cats'},
      );

      expect(preview.method, 'GET');
      expect(preview.headers['authorization'], 'Bearer [REDACTED]');
      expect(preview.query['token'], '[REDACTED]');
      expect(preview.body, contains('[REDACTED]'));
      expect(preview.body, isNot(contains('api-secret')));
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
      expect(() => UrlResponseFormat.fromString('json'), throwsFormatException);
    });
  });
}
