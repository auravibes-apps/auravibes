import 'dart:convert';

import 'package:auravibes_app/features/chats/services/chatbot/app_open_ai_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_openai/genkit_openai.dart';
import 'package:http/http.dart' as http;

import 'support/provider_fault_client.dart';
import 'support/provider_fault_protocol.dart';

void main() {
  test(
    'retains upstream namespaces, metadata, options, and action routing',
    () {
      final upstream = _upstream();
      final wrapped = AppOpenAIPlugin(upstream: upstream);
      final original = _model(upstream);
      final model = _model(wrapped);

      expect(wrapped.name, upstream.name);
      expect(model.name, original.name);
      expect(model.metadata, original.metadata);
      expect(model.customOptions, same(original.customOptions));
      expect(wrapped.resolve(.tool, 'contract-model'), isNull);
    },
  );

  test(
    'preserves upstream encoded options and closes only its owned client',
    () async {
      final originalClient = _client();
      final wrappedClient = _client();
      final original = await _generate(_upstream(), originalClient);
      final wrapped = await _generate(
        AppOpenAIPlugin(upstream: _upstream()),
        wrappedClient,
      );

      expect(wrapped.text, original.text);
      expect(wrapped.finishReason, original.finishReason);
      expect(
        wrappedClient.requests.single.body,
        originalClient.requests.single.body,
      );
      final request = wrappedClient.requests.single;
      expect(request.url, originalClient.requests.single.url);
      expect(request.json['temperature'], 0.25);
      expect(request.json['top_p'], 0.75);
      expect(request.json['max_completion_tokens'], 20);
      expect(request.json['user'], 'fixture-user');
      expect(request.supportsAbort, isTrue);
      expect(wrappedClient.closeCount, 1);
      expect(originalClient.closeCount, 1);
    },
  );

  test('does not close an injected caller-owned client', () async {
    final client = _client();
    final result = await _generate(
      AppOpenAIPlugin(upstream: _upstream(), httpClient: client),
      client,
    );

    expect(result.text, 'ready');
    expect(client.requests.single.supportsAbort, isTrue);
    expect(client.closeCount, 0);
    client.close();
    expect(client.closeCount, 1);
  });

  test(
    'upstream transcription retains its multipart boundary and audio',
    () async {
      final client = ProviderFaultClient([
        (_) async => .new(
          .value(utf8.encode('{"text":"fixture transcript"}')),
          200,
          headers: const {'content-type': 'application/json'},
        ),
      ]);
      addTearDown(client.close);
      final ai = Genkit(
        plugins: [AppOpenAIPlugin(upstream: _upstream(), httpClient: client)],
        isDevEnv: false,
      );
      final response = await ai.generate<Object?, Object?>(
        model: modelRef<Object?>('openai/whisper-1'),
        messages: [
          Message(
            role: .user,
            content: [
              MediaPart(
                media: .new(
                  contentType: 'audio/wav',
                  url: 'data:audio/wav;base64,aGk=',
                ),
              ),
            ],
          ),
        ],
        cancel: CancellationController().token,
      );
      final request = client.requests.single;
      final contentType = request.headers['content-type'];

      expect(response.finishReason, FinishReason.stop);
      expect(response.text, 'fixture transcript');
      expect(request.url.path, '/v1/audio/transcriptions');
      expect(request.supportsAbort, isTrue);
      expect(contentType, startsWith('multipart/form-data; boundary='));
      if (contentType == null) fail('Expected a multipart content type');
      final boundary = contentType.split('boundary=').last;
      expect(request.body, startsWith('--$boundary\r\n'));
      expect(request.body, endsWith('--$boundary--\r\n'));
      expect(request.body, contains('name="model"\r\n\r\nwhisper-1'));
      expect(request.body, contains('\r\n\r\nhi\r\n'));
      expect(client.closeCount, 0);
    },
  );

  test('retains upstream failure cause and retry behavior', () async {
    ProviderFaultClient failingClient() => ProviderFaultClient([
      (_) async => .new(
        .value(
          utf8.encode('{"error":{"type":"server_error","message":"failed"}}'),
        ),
        500,
        headers: const {'content-type': 'application/json'},
      ),
    ]);
    final originalClient = failingClient();
    final wrappedClient = failingClient();
    final original = await _generate(_upstream(), originalClient);
    final wrapped = await _generate(
      AppOpenAIPlugin(upstream: _upstream()),
      wrappedClient,
    );

    expect(wrapped.finishReason, original.finishReason);
    expect(wrapped.error?.status, original.error?.status);
    expect(wrapped.cause.runtimeType, original.cause.runtimeType);
    expect(wrappedClient.requests, hasLength(1));
    expect(originalClient.requests, hasLength(1));
    expect(wrappedClient.closeCount, 1);
  });
}

GenkitPlugin _upstream() =>
    openAI(apiKey: 'fixture-key', baseUrl: 'https://provider.invalid/v1');

ProviderFaultClient _client() => ProviderFaultClient([
  (_) async => http.StreamedResponse(
    .value(ProviderFaultProtocol.chat.success('ready')),
    200,
    headers: const {'content-type': 'text/event-stream'},
  ),
]);

Future<GenerateResult<Object?>> _generate(
  GenkitPlugin plugin,
  ProviderFaultClient client,
) => http.runWithClient(
  () => Genkit(plugins: [plugin], isDevEnv: false)
      .generate<OpenAIChatOptions, Object?>(
        model: modelRef<OpenAIChatOptions>('openai/contract-model'),
        config: OpenAIChatOptions(
          temperature: 0.25,
          topP: 0.75,
          maxTokens: 20,
          user: 'fixture-user',
        ),
        prompt: 'Preserve the upstream request.',
        cancel: CancellationController().token,
      ),
  () => client,
);

Model<dynamic> _model(GenkitPlugin plugin) {
  final action = plugin.resolve(.model, 'contract-model');
  if (action is Model<dynamic>) return action;
  fail('Expected the contract model action');
}
