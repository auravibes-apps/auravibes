import 'dart:convert';

import 'package:auravibes_app/services/chatbot_service/chat_completions_plugin.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;

void main() {
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
    test('resolves ${testCase.base} to ${testCase.expected}', () async {
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
          AppChatCompletionsPlugin(
            name: 'uri-test',
            baseUrl: testCase.base,
            apiKey: 'key',
            codec: ChatCompletionsCodec(
              errorLabel: 'UriTest',
              customize: (modelName, config) => (
                model: modelName,
                extraBody: const <String, dynamic>{},
              ),
            ),
            models: const [ChatCompletionsModelDefinition(name: 'm')],
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
}

http.StreamedResponse _jsonResponse(Map<String, Object?> body) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    200,
    headers: {'content-type': 'application/json'},
  );
}

final class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}
