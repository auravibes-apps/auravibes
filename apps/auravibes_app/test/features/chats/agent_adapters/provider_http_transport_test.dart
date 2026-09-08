import 'dart:async';

import 'package:auravibes_app/features/chats/agent_adapters/provider_http_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  for (final owned in [true, false]) {
    for (final outcome in [
      'complete',
      'stream error',
      'cancel',
      'send error',
      'timeout',
    ]) {
      test('$outcome closes only owned client (owned: $owned)', () async {
        final failure = StateError('transport failed');
        final client = _Client((request) async {
          if (outcome == 'send error') throw failure;
          if (outcome == 'timeout') {
            return await Completer<http.StreamedResponse>().future;
          }

          return http.StreamedResponse(
            outcome == 'stream error'
                ? Stream<List<int>>.error(failure)
                : Stream<List<int>>.fromIterable([
                    [1],
                    [2],
                  ]),
            201,
          );
        });

        await http.runWithClient(
          () async {
            final result = sendProviderRequest(
              http.Request('POST', Uri.parse('https://example.test')),
              requestTimeout: const Duration(milliseconds: 10),
              httpClient: owned ? null : client,
            );
            if (outcome == 'send error' || outcome == 'timeout') {
              await expectLater(
                result,
                throwsA(
                  outcome == 'timeout'
                      ? isA<TimeoutException>()
                      : same(failure),
                ),
              );
            } else {
              final response = await result;
              expect(response.statusCode, 201);
              expect(client.closes, 0);
              if (outcome == 'stream error') {
                await expectLater(
                  response.body.drain<void>(),
                  throwsA(same(failure)),
                );
              } else if (outcome == 'cancel') {
                expect(await response.body.take(1).toList(), [
                  [1],
                ]);
              } else {
                expect(await response.body.toList(), [
                  [1],
                  [2],
                ]);
              }
            }
            expect(client.closes, owned ? 1 : 0);
          },
          () {
            return client;
          },
        );
      });
    }
  }
}

final class _Client(
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler,
) extends http.BaseClient {
  int closes = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);

  @override
  void close() => closes++;
}
