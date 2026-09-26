import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/services/chatbot/chat_completions_plugin.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;

void main() {
  test('resolves only model actions', () {
    final plugin = AppChatCompletionsPlugin(
      name: 'resolve-test',
      baseUrl: 'https://example.test',
      apiKey: 'key',
      codec: .new(
        errorLabel: 'ResolveTest',
        customize: (modelName, config) =>
            (model: modelName, extraBody: const <String, dynamic>{}),
      ),
    );

    expect(plugin.resolve(.model, 'm'), isA<Model<dynamic>>());
    expect(plugin.resolve(.tool, 'm'), isNull);
  });
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
            codec: .new(
              errorLabel: 'UriTest',
              customize: (modelName, config) =>
                  (model: modelName, extraBody: const <String, dynamic>{}),
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
            role: .user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
      );

      expect(response.text, 'ok.');
      expect(capturedUri, Uri.parse(testCase.expected));
    });
  }

  test('rejects a response with an oversized content length', () async {
    final client = _FakeClient(
      (_) async => http.StreamedResponse(
        const Stream.empty(),
        200,
        contentLength: 4 * 1024 * 1024 + 1,
      ),
    );
    final ai = _genkitWithClient(client);

    final response = await ai.generate<Object?, Object?>(
      model: modelRef<Object?>('transport-test/m'),
      messages: const [],
    );

    expect(response.finishReason, FinishReason.failed);
    expect(response.finishMessage, contains('safe processing limit'));
  });

  test('applies an overall response deadline', () async {
    final client = _FakeClient(
      (_) async => http.StreamedResponse(
        .periodic(const Duration(milliseconds: 1), (_) => const [32]),
        200,
      ),
    );
    final ai = _genkitWithClient(
      client,
      requestTimeout: const Duration(milliseconds: 30),
    );

    final response = await ai.generate<Object?, Object?>(
      model: modelRef<Object?>('transport-test/m'),
      messages: const [],
    );

    expect(response.finishReason, FinishReason.failed);
    expect(response.finishMessage, contains('Provider request timed out'));
  });

  test('retries selected server errors once and caps Retry-After', () async {
    var attempts = 0;
    final retryDelays = <Duration>[];
    final client = _FakeClient((_) async {
      attempts++;
      if (attempts == 1) {
        return _jsonResponse(
          {
            'error': {'message': 'temporarily unavailable'},
          },
          statusCode: 503,
          headers: {'content-type': 'application/json', 'retry-after': '120'},
        );
      }

      return _jsonResponse({
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': 'ok.'},
          },
        ],
      });
    });
    final ai = _genkitWithClient(
      client,
      retryWait: (delay) {
        retryDelays.add(delay);

        return Future<void>.value();
      },
    );

    final response = await ai.generate<Object?, Object?>(
      model: modelRef<Object?>('transport-test/m'),
      messages: const [],
    );

    expect(response.text, 'ok.');
    expect(attempts, 2);
    expect(retryDelays, [const Duration(seconds: 60)]);
  });

  test('retries transport failures before output once', () async {
    var attempts = 0;
    final client = _FakeClient((_) async {
      attempts++;
      if (attempts == 1) throw http.ClientException('connection reset');

      return _jsonResponse({
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': 'ok.'},
          },
        ],
      });
    });
    final ai = _genkitWithClient(
      client,
      retryWait: (_) => Future<void>.value(),
    );

    final response = await ai.generate<Object?, Object?>(
      model: modelRef<Object?>('transport-test/m'),
      messages: const [],
    );

    expect(response.text, 'ok.');
    expect(attempts, 2);
  });

  test(
    'forwards rate-limit Retry-After without retrying in provider plugin',
    () async {
      var attempts = 0;
      final client = _FakeClient((_) async {
        attempts++;

        return _jsonResponse(
          {
            'error': {'message': 'rate limited'},
          },
          statusCode: 429,
          headers: {'content-type': 'application/json', 'retry-after': '120'},
        );
      });
      final ai = _genkitWithClient(
        client,
        retryWait: (_) => Future<void>.value(),
      );

      final response = await ai.generate<Object?, Object?>(
        model: modelRef<Object?>('transport-test/m'),
        messages: const [],
      );

      expect(response.finishReason, FinishReason.failed);
      expect(
        response.cause,
        isA<AgentRateLimitRetryException>()
            .having(
              (error) => error.retryAfter,
              'retryAfter',
              const Duration(seconds: 120),
            )
            .having(
              (error) => error.providerException.details,
              'provider details',
              'rate limited',
            ),
      );
      expect(attempts, 1);
    },
  );

  test('does not retry after streaming output is emitted', () async {
    var attempts = 0;
    final client = _FakeClient((_) async {
      attempts++;
      final body = Stream<List<int>>.multi((controller) {
        controller
          ..add(
            utf8.encode(
              'data: {"choices":[{"delta":{"content":"partial"}, '
              '"finish_reason":null}]}\n',
            ),
          )
          ..addError(http.ClientException('stream reset'));
        unawaited(controller.close());
      });

      return http.StreamedResponse(body, 200);
    });
    final ai = _genkitWithClient(
      client,
      retryWait: (_) => Future<void>.value(),
    );
    final chunks = <Object?>[];

    final response = await ai.generate<Object?, Object?>(
      model: modelRef<Object?>('transport-test/m'),
      messages: const [],
      onChunk: chunks.add,
    );

    expect(response.finishReason, FinishReason.failed);
    expect(chunks, hasLength(1));
    expect(attempts, 1);
  });

  test('cancellation during retry wait prevents another request', () async {
    final cancellation = CancellationController();
    final retryStarted = Completer<void>();
    var attempts = 0;
    var requestSupportsAbort = false;
    final client = _FakeClient((request) async {
      attempts++;
      requestSupportsAbort = request is http.Abortable;

      return _jsonResponse(
        {
          'error': {'message': 'temporarily unavailable'},
        },
        statusCode: 503,
        headers: {'content-type': 'application/json', 'retry-after': '1'},
      );
    });
    final ai = _genkitWithClient(
      client,
      retryWait: (_) {
        retryStarted.complete();

        return Completer<void>().future;
      },
    );

    final generation = ai.generate<Object?, Object?>(
      model: modelRef<Object?>('transport-test/m'),
      messages: const [],
      cancel: cancellation.token,
    );
    await retryStarted.future;
    cancellation.cancel();
    final response = await generation;

    expect(response.finishReason, FinishReason.aborted);
    expect(requestSupportsAbort, isTrue);
    expect(attempts, 1);
  });
}

Genkit _genkitWithClient(
  http.Client client, {
  Duration requestTimeout = const Duration(seconds: 30),
  Future<void> Function(Duration)? retryWait,
}) => Genkit(
  plugins: [
    AppChatCompletionsPlugin(
      name: 'transport-test',
      baseUrl: 'https://example.test',
      apiKey: 'key',
      codec: .new(
        errorLabel: 'TransportTest',
        customize: (modelName, config) =>
            (model: modelName, extraBody: const <String, dynamic>{}),
      ),
      models: const [ChatCompletionsModelDefinition(name: 'm')],
      httpClient: client,
      requestTimeout: requestTimeout,
      retryWait: retryWait,
    ),
  ],
);

http.StreamedResponse _jsonResponse(
  Map<String, Object?> body, {
  int statusCode = 200,
  Map<String, String> headers = const {'content-type': 'application/json'},
}) {
  return http.StreamedResponse(
    .value(utf8.encode(jsonEncode(body))),
    statusCode,
    headers: headers,
  );
}

final class _FakeClient(
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler,
) extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}
