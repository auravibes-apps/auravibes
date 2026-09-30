import 'dart:convert';

import 'package:auravibes_app/services/mcp_service/mcp_streamable_http_response_capture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('captures eligible rejection and replays response body', () async {
    const body = 'legacy endpoint';
    final capture = McpStreamableHttpResponseCapture(
      innerClient: MockClient((_) async => http.Response(body, 405)),
    );
    addTearDown(capture.close);

    final response = await capture.send(_initializeRequest());

    expect(capture.shouldFallbackToLegacySse, isTrue);
    expect(response.statusCode, 405);
    expect(await response.stream.bytesToString(), body);
  });

  test('does not capture valid JSON-RPC errors', () async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': 12,
      'error': {'code': -32600, 'message': 'Invalid request'},
    });
    final capture = McpStreamableHttpResponseCapture(
      innerClient: MockClient((_) async => http.Response(body, 400)),
    );
    addTearDown(capture.close);

    final response = await capture.send(_initializeRequest());

    expect(capture.shouldFallbackToLegacySse, isFalse);
    expect(await response.stream.bytesToString(), body);
  });

  test('ignores authorization and non-initialize failures', () async {
    final capture = McpStreamableHttpResponseCapture(
      innerClient: MockClient((_) async => http.Response('rejected', 401)),
    );
    addTearDown(capture.close);

    final authResponse = await capture.send(_initializeRequest());
    expect(capture.shouldFallbackToLegacySse, isFalse);
    await authResponse.stream.drain<void>();

    final otherRequest = http.Request('POST', .https('example.com', '/mcp'))
      ..body = jsonEncode({'jsonrpc': '2.0', 'method': 'tools/list'});
    final otherResponse = await capture.send(otherRequest);
    expect(capture.shouldFallbackToLegacySse, isFalse);
    await otherResponse.stream.drain<void>();
  });

  test('does not mark network errors as compatibility responses', () async {
    final capture = McpStreamableHttpResponseCapture(
      innerClient: MockClient((_) async => throw StateError('offline')),
    );
    addTearDown(capture.close);

    await expectLater(
      capture.send(_initializeRequest()),
      throwsA(isA<StateError>()),
    );

    expect(capture.shouldFallbackToLegacySse, isFalse);
  });
}

http.Request _initializeRequest() =>
    http.Request('POST', .https('example.com', '/mcp'))
      ..body = jsonEncode({
        'jsonrpc': '2.0',
        'id': 12,
        'method': 'initialize',
        'params': <String, Object?>{},
      });
