import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  Future<UrlResponse> execute(
    String body, {
    Map<String, String> credentials = const {},
    bool sse = true,
    Map<String, ConnectorCredentialAttributeDefinition> credentialDefinitions =
        const {},
  }) =>
      ConnectorToolTemplateExecutor(
            const ResolveConnectorRequestTemplate(),
            (_) => CancelableOperation.fromFuture(
              Future.value(
                UrlResponse(
                  statusCode: 200,
                  body: body,
                  headers: {
                    'content-type': [
                      if (sse) 'text/event-stream' else 'text/plain',
                    ],
                  },
                  elapsed: const Duration(milliseconds: 3),
                ),
              ),
            ),
          )
          .call(
            inputs: const {},
            credentials: credentials,
            definition: ConnectorToolRequestDefinition(
              request: const ConnectorRequestTemplate(url: 'https://example.com'),
              inputs: const {},
              credentialDefinitions: credentialDefinitions,
            ),
          )
          .value;

  String event(String type, Map<String, Object?> data) =>
      'event: $type\ndata: ${jsonEncode(data)}\n\n';

  test('completed SSE keeps response metadata and final text', () async {
    final response = await execute(
      event('response.output_text.delta', {'delta': 'Hello'}) +
          event('response.completed', {
            'response': {'output_text': 'Hello world'},
          }),
    );
    expect(response.body, 'Hello world');
    expect(response.statusCode, 200);
    expect(response.elapsed, const Duration(milliseconds: 3));
    expect(response.headers['content-type'], ['text/event-stream']);
  });

  test('non-SSE response stays unchanged', () async {
    const body = '{"type":"error","message":"not an SSE response"}';
    expect((await execute(body, sse: false)).body, body);
  });

  test('redacts credentials from non-SSE response', () async {
    final response = await execute(
      'echoed secret-value',
      credentials: const {'apiKey': 'secret-value'},
      sse: false,
    );
    expect(response.body, 'echoed [REDACTED]');
  });

  test('redacts credentials from successful SSE response', () async {
    final response = await execute(
      event('response.output_text.delta', {'delta': 'echoed secret-value'}) +
          event('response.completed', {
            'response': {'output_text': 'echoed secret-value'},
          }),
      credentials: const {'apiKey': 'secret-value'},
    );
    expect(response.body, 'echoed [REDACTED]');
  });

  test('keeps explicitly non-secret credentials visible', () async {
    final response = await execute(
      'account account-id',
      credentials: const {'account': 'account-id'},
      credentialDefinitions: const {
        'account': ConnectorCredentialAttributeDefinition(
          description: 'Account identifier',
          secret: false,
        ),
      },
      sse: false,
    );
    expect(response.body, 'account account-id');
  });

  test('snapshots secret values before async response handling', () async {
    final response = Completer<UrlResponse>();
    final credentials = {'apiKey': 'old-secret'};
    final operation =
        ConnectorToolTemplateExecutor(
          const ResolveConnectorRequestTemplate(),
          (_) => CancelableOperation.fromFuture(response.future),
        ).call(
          inputs: const {},
          credentials: credentials,
          definition: const ConnectorToolRequestDefinition(
            request: ConnectorRequestTemplate(url: 'https://example.com'),
            inputs: {},
          ),
        );

    credentials['apiKey'] = 'rotated-secret';
    response.complete(
      const UrlResponse(
        statusCode: 200,
        body: 'echoed old-secret',
        headers: {
          'content-type': ['text/plain'],
        },
        elapsed: Duration(milliseconds: 3),
      ),
    );

    expect((await operation.value).body, 'echoed [REDACTED]');
  });

  for (final body in [
    'data: {"type":"response.failed"}\n\n',
    'event: response.incomplete\ndata: {}\n\n',
    'event: error\ndata: not JSON\n\n',
    'event: error\ndata:\n\n',
  ]) {
    test('rejects terminal SSE event: $body', () async {
      await expectLater(execute(body), throwsA(isA<ConnectorStreamFailure>()));
    });
  }

  for (final terminal in ['response.failed', 'response.incomplete', 'error']) {
    for (final partial in ['', 'Partial answer']) {
      test('$terminal rejects SSE with partial text "$partial"', () async {
        final body =
            (partial.isEmpty
                ? ''
                : event('response.output_text.delta', {'delta': partial})) +
            event(terminal, {
              'type': terminal,
              'response': {'output_text': 'must not become success'},
              'error': {'message': 'sensitive provider detail'},
            });
        await expectLater(
          execute(body),
          throwsA(
            isA<ConnectorStreamFailure>()
                .having((error) => error.terminalType, 'terminalType', terminal)
                .having((error) => error.partialText, 'partialText', partial)
                .having(
                  (error) => error.toString(),
                  'safe description',
                  isNot(contains('sensitive provider detail')),
                ),
          ),
        );
      });
    }
  }

  test(
    'data before terminal event does not enter partial diagnostics',
    () async {
      final delta = event('response.output_text.delta', {
        'delta': 'Partial answer',
      });
      final body =
          '${delta}data: '
          '{"response":{"output_text":"terminal payload"}}\n'
          'event: response.failed\n\n';
      await expectLater(
        execute(body),
        throwsA(
          isA<ConnectorStreamFailure>().having(
            (error) => error.partialText,
            'partialText',
            'Partial answer',
          ),
        ),
      );
    },
  );

  test('redacts and bounds terminal diagnostics', () async {
    final body =
        event('response.output_text.delta', {
          'delta':
              'secret-value Authorization: Bearer private-token ${'x' * 1000}',
        }) +
        event('response.failed', {'type': 'response.failed'});
    await expectLater(
      execute(body, credentials: {'key': 'secret-value'}),
      throwsA(
        isA<ConnectorStreamFailure>()
            .having(
              (error) => error.partialText.length,
              'length',
              lessThanOrEqualTo(500),
            )
            .having(
              (error) => error.partialText,
              'credential',
              isNot(contains('secret-value')),
            )
            .having(
              (error) => error.partialText,
              'bearer',
              isNot(contains('private-token')),
            )
            .having(
              (error) => error.toString(),
              'description',
              isNot(contains('xxx')),
            ),
      ),
    );
  });
}
