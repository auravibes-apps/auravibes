import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/mcp_service/mcp_legacy_sse_unavailable_exception.dart';
import 'package:auravibes_app/services/mcp_service/mcp_web_sse_client_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'exchanges initialize and tools/list over SSE with configured headers',
    () async {
      final client = _SseMockClient();
      final transport = await McpWebSseClientTransport.create(
        serverUrl: 'https://example.com/mcp',
        headers: const {
          'Authorization': 'Bearer configured-token',
          'X-MCP-Key': 'configured-key',
        },
        client: client,
      );
      addTearDown(transport.close);

      final initialize = await _request(transport, 1, 'initialize');
      final tools = await _request(transport, 2, 'tools/list');

      expect(initialize['result'], isA<Map<Object?, Object?>>());
      expect(
        (tools['result']! as Map<Object?, Object?>)['tools'],
        hasLength(1),
      );
      expect(client.requests.map((request) => request.method), [
        'GET',
        'POST',
        'POST',
      ]);
      for (final request in client.requests) {
        expect(request.headers['Authorization'], 'Bearer configured-token');
        expect(request.headers['X-MCP-Key'], 'configured-key');
      }

      transport.close();
      await transport.onClose;
      await client.streamCancelled.future.timeout(const Duration(seconds: 1));
      expect(client.isClosed, isTrue);
    },
  );

  test('maps browser request failures to localized CORS guidance', () async {
    final client = MockClient((_) async {
      throw http.ClientException('Failed to fetch');
    });

    await expectLater(
      McpWebSseClientTransport.create(
        serverUrl: 'https://example.com/mcp',
        client: client,
      ),
      throwsA(
        isA<McpLegacySseUnavailableException>().having(
          (error) => error.localizationKey,
          'localizationKey',
          LocaleKeys.mcp_modal_legacy_sse_unavailable,
        ),
      ),
    );
  });

  test('rejects cross-origin SSE message endpoints', () async {
    final client = _SseMockClient(
      endpoint: 'https://attacker.example/messages',
    );

    await expectLater(
      McpWebSseClientTransport.create(
        serverUrl: 'https://example.com/mcp',
        client: client,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('does not accept a rejected SSE handshake', () async {
    final client = MockClient((_) async => http.Response('denied', 401));

    await expectLater(
      McpWebSseClientTransport.create(
        serverUrl: 'https://example.com/mcp',
        client: client,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Future<Map<String, Object?>> _request(
  McpWebSseClientTransport transport,
  int id,
  String method,
) async {
  final response = transport.onMessage
      .where(
        (message) => message is Map<Object?, Object?> && message['id'] == id,
      )
      .cast<Map<Object?, Object?>>()
      .first;
  transport.send({
    'jsonrpc': '2.0',
    'id': id,
    'method': method,
    'params': <String, Object?>{},
  });
  final result = await response.timeout(const Duration(seconds: 1));

  return Map<String, Object?>.from(result);
}

final class _SseMockClient extends http.BaseClient {
  factory({String endpoint = '/messages'}) {
    final streamCancelled = Completer<void>();

    return _SseMockClient.withStream(
      endpoint: endpoint,
      streamCancelled: streamCancelled,
    );
  }

  new withStream({required this.endpoint, required this.streamCancelled})
    : _events = StreamController<List<int>>(
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );

  final String endpoint;
  final Completer<void> streamCancelled;
  final List<http.Request> requests = [];
  bool isClosed = false;
  final StreamController<List<int>> _events;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final typedRequest = request as http.Request;
    requests.add(typedRequest);
    if (typedRequest.method == 'GET') {
      _events.add(_event('endpoint', endpoint));

      return http.StreamedResponse(
        _events.stream,
        200,
        headers: const {'content-type': 'text/event-stream'},
      );
    }

    final message = jsonDecode(typedRequest.body) as Map<String, dynamic>;
    final response = switch (message['method']) {
      'initialize' => {
        'jsonrpc': '2.0',
        'id': message['id'],
        'result': {
          'protocolVersion': '2025-06-18',
          'capabilities': <String, Object?>{},
          'serverInfo': {'name': 'web-sse', 'version': '1.0'},
        },
      },
      'tools/list' => {
        'jsonrpc': '2.0',
        'id': message['id'],
        'result': {
          'tools': [
            {
              'name': 'web_tool',
              'description': 'Web SSE tool',
              'inputSchema': {'type': 'object'},
            },
          ],
        },
      },
      _ => null,
    };
    if (response != null) _events.add(_event('message', jsonEncode(response)));

    return http.StreamedResponse(const Stream<List<int>>.empty(), 202);
  }

  @override
  void close() {
    isClosed = true;
    unawaited(_events.close());
  }

  List<int> _event(String type, String data) =>
      utf8.encode('event: $type\ndata: $data\n\n');
}
