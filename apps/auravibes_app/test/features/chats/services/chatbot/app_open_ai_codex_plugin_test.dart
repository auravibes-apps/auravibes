import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/services/chatbot/app_open_ai_codex_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;

void main() {
  for (final streaming in [false, true]) {
    final mode = streaming ? 'streaming' : 'complete';
    test('aborts a Codex $mode request before response headers', () async {
      final cancellation = CancellationController();
      final requestSent = Completer<http.BaseRequest>();
      final abortObserved = Completer<void>();
      final response = Completer<http.StreamedResponse>();
      var attempts = 0;
      final client = _TrackingClient((request) async {
        attempts++;
        requestSent.complete(request);
        final abortTrigger = switch (request) {
          http.Abortable(:final abortTrigger) => abortTrigger,
          _ => null,
        };
        if (abortTrigger == null) return await response.future;

        await abortTrigger;
        abortObserved.complete();

        throw http.RequestAbortedException(request.url);
      });
      final ai = _genkitWithClient(client);
      final generation = _generate(ai, cancellation, streaming: streaming);

      final request = await requestSent.future;
      cancellation.cancel();
      final abortTrigger = switch (request) {
        http.Abortable(:final abortTrigger) => abortTrigger,
        _ => null,
      };
      if (abortTrigger == null) {
        response.complete(_completedResponse());
      } else {
        await abortObserved.future;
      }

      final result = await generation;

      expect(request, isA<http.AbortableRequest>());
      expect(result.finishReason, FinishReason.aborted);
      expect(result.error?.status, 'ABORTED');
      expect(result.cause, isA<http.RequestAbortedException>());
      expect(attempts, 1);
      expect(client.closeCount, 0);
    });
  }

  test(
    'cancellation during SSE stops chunks and closes the owned client',
    () async {
      final cancellation = CancellationController();
      final requestSent = Completer<http.BaseRequest>();
      final firstChunk = Completer<void>();
      final abortObserved = Completer<void>();
      final body = StreamController<List<int>>();
      var attempts = 0;
      final client = _TrackingClient((request) {
        attempts++;
        requestSent.complete(request);
        final abortTrigger = switch (request) {
          http.Abortable(:final abortTrigger) => abortTrigger,
          _ => null,
        };
        if (abortTrigger case final trigger?) {
          unawaited(_abortBody(body, trigger, request.url, abortObserved));
        }
        body.add(_sseEvent('response.output_text.delta', {'delta': 'first'}));

        return .value(http.StreamedResponse(body.stream, 200));
      });
      final ai = _genkitWithClient();
      final chunks = <Object?>[];
      final generation = http.runWithClient(
        () => ai.generate<Object?, Object?>(
          model: modelRef<Object?>('openai_codex/gpt-5.5'),
          messages: const [],
          cancel: cancellation.token,
          onChunk: (chunk) {
            chunks.add(chunk);
            if (!firstChunk.isCompleted) firstChunk.complete();
          },
        ),
        () => client,
      );

      await firstChunk.future;
      final request = await requestSent.future;
      cancellation.cancel();
      final abortTrigger = switch (request) {
        http.Abortable(:final abortTrigger) => abortTrigger,
        _ => null,
      };
      if (abortTrigger == null) {
        body
          ..add(_sseEvent('response.output_text.delta', {'delta': 'second'}))
          ..add(_sseEvent('response.completed', const {}));
        expect(await body.close(), isNull);
      } else {
        await abortObserved.future;
      }

      final result = await generation;

      expect(request, isA<http.AbortableRequest>());
      expect(result.finishReason, FinishReason.aborted);
      expect(result.error?.status, 'ABORTED');
      expect(result.cause, isA<http.RequestAbortedException>());
      expect(chunks, hasLength(1));
      expect(attempts, 1);
      expect(client.closeCount, 1);
    },
  );

  test('retries a Codex server error before streamed output', () async {
    var attempts = 0;
    final client = _TrackingClient((_) async {
      attempts++;
      if (attempts == 1) {
        return http.StreamedResponse(
          .value(
            utf8.encode(
              jsonEncode({
                'error': {'type': 'server_error'},
              }),
            ),
          ),
          500,
          headers: const {'content-type': 'application/json'},
        );
      }

      return http.StreamedResponse(
        .fromIterable([
          _sseEvent('response.output_text.delta', {'delta': 'ready'}),
          _sseEvent('response.completed', const {}),
        ]),
        200,
      );
    });
    final ai = _genkitWithClient(client);
    final chunks = <Object?>[];

    final result = await ai.generate<Object?, Object?>(
      model: modelRef<Object?>('openai_codex/gpt-5.5'),
      messages: const [],
      onChunk: chunks.add,
    );

    expect(result.text, 'ready');
    expect(result.finishReason, FinishReason.stop);
    expect(chunks, hasLength(1));
    expect(attempts, 2);
    expect(client.closeCount, 0);
  });
}

Genkit _genkitWithClient([http.Client? client]) => Genkit(
  plugins: [
    AppOpenAICodexPlugin(
      accessToken: 'token',
      models: const ['gpt-5.5'],
      baseUrl: 'https://example.test/responses',
      httpClient: client,
    ),
  ],
);

Future<GenerateResult<Object?>> _generate(
  Genkit ai,
  CancellationController cancellation, {
  required bool streaming,
}) {
  if (streaming) {
    final chunks = <Object?>[];

    return ai.generate<Object?, Object?>(
      model: modelRef<Object?>('openai_codex/gpt-5.5'),
      messages: const [],
      cancel: cancellation.token,
      onChunk: chunks.add,
    );
  }

  return ai.generate<Object?, Object?>(
    model: modelRef<Object?>('openai_codex/gpt-5.5'),
    messages: const [],
    cancel: cancellation.token,
  );
}

http.StreamedResponse _completedResponse() =>
    .new(.value(utf8.encode(jsonEncode({'status': 'completed'}))), 200);

List<int> _sseEvent(String type, Map<String, Object?> fields) =>
    utf8.encode('data: ${jsonEncode({'type': type, ...fields})}\n');

final class _TrackingClient(
  final Future<http.StreamedResponse> Function(http.BaseRequest) _send,
) extends http.BaseClient {
  int closeCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _send(request);

  @override
  void close() => closeCount++;
}

Future<void> _abortBody(
  StreamController<List<int>> body,
  Future<void> abortTrigger,
  Uri uri,
  Completer<void> abortObserved,
) async {
  await abortTrigger;
  abortObserved.complete();
  body.addError(http.RequestAbortedException(uri));
  expect(await body.close(), isNull);
}
