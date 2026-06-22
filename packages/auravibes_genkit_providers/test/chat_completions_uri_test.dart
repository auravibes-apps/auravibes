// Required: Tests keep compact return flow.
// Required: Tests use protocol numeric fixtures.
// Required: Test fakes keep related fields near constructors.

import 'dart:convert';

import 'package:auravibes_genkit_providers/src/chat_completions_provider.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('chatCompletionsUri', () {
    for (final testCase in [
      (
        base: 'https://example.test/v1',
        expected: 'https://example.test/v1/chat/completions',
      ),
      (
        base: 'https://example.test/v1/',
        expected: 'https://example.test/v1/chat/completions',
      ),
      (
        base: 'https://example.test',
        expected: 'https://example.test/chat/completions',
      ),
    ]) {
      test('resolves ${testCase.base} -> ${testCase.expected}', () async {
        Uri? capturedUri;
        final client = _FakeClient((request) async {
          capturedUri = request.url;

          return _jsonResponse({
            'choices': [
              {
                'finish_reason': 'stop',
                'message': {'role': 'assistant', 'content': 'ok.'},
              },
            ],
          });
        });
        final ai = Genkit(
          plugins: [
            ChatCompletionsPlugin(
              name: 'uri-test',
              baseUrl: testCase.base,
              errorLabel: 'UriTest',
              customize: (modelName, config) => (
                model: modelName,
                extraBody: const <String, dynamic>{},
              ),
              apiKey: 'key',
              models: const [
                ChatCompletionsModelDefinition(name: 'm'),
              ],
              httpClient: client,
            ),
          ],
        );

        final response = await ai.generate<Object?, Object?>(
          model: modelRef<Object?>('uri-test/m'),
          messages: [
            Message(
              role: Role.user,
              content: [TextPart(text: 'Hi')],
            ),
          ],
        );

        expect(response.text, 'ok.');
        expect(capturedUri, Uri.parse(testCase.expected));
      });
    }
  });
}

http.StreamedResponse _jsonResponse(Map<String, Object?> body) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    200,
    headers: {'content-type': 'application/json'},
  );
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return handler(request);
  }
}
