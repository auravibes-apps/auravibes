import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/services/mcp_service/mcp_legacy_sse_unavailable_exception.dart';
import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpManagerService.connectMcpWithAutoTransport', () {
    test('uses Streamable HTTP when initialize succeeds', () async {
      final server = await _LocalMcpHttpServer.start();
      final manager = McpManagerService();
      McpManagerClient? client;
      addTearDown(() async {
        await manager.disconnect(client);
        await server.close();
      });

      client = await manager.connectMcpWithAutoTransport(
        _connectionRequest(server.endpoint),
      );

      expect(client.resolvedTransport, isA<McpTransportTypeStreamableHttp>());
      expect(server.streamablePostCount, 1);
      expect(server.sseGetCount, 0);
    });

    test('falls back to valid legacy SSE handshake on native', () async {
      final server = await _LocalMcpHttpServer.start(streamableStatus: 405);
      final manager = McpManagerService();
      McpManagerClient? client;
      addTearDown(() async {
        await manager.disconnect(client);
        await server.close();
      });

      client = await manager.connectMcpWithAutoTransport(
        _connectionRequest(
          server.endpoint,
          authenticationType: const McpAuthenticationType.bearerToken(
            bearerToken: 'configured-token',
          ),
        ),
      );
      await server.waitForInitializedNotification();

      expect(client.resolvedTransport, isA<McpTransportTypeSSE>());
      expect(server.streamablePostCount, 1);
      expect(server.sseGetCount, 1);
      expect(server.streamableAuthorization, 'Bearer configured-token');
      expect(server.sseAuthorization, 'Bearer configured-token');
      expect(server.sseMessageAuthorization, 'Bearer configured-token');
    });

    test('does not fall back for a JSON-RPC error response', () async {
      final server = await _LocalMcpHttpServer.start(
        streamableStatus: 400,
        useJsonRpcError: true,
      );
      final manager = McpManagerService();
      addTearDown(server.close);

      await expectLater(
        manager.connectMcpWithAutoTransport(
          _connectionRequest(server.endpoint),
        ),
        throwsA(anything),
      );

      expect(server.sseGetCount, 0);
    });

    test('does not fall back for authorization failures', () async {
      final server = await _LocalMcpHttpServer.start(streamableStatus: 401);
      final manager = McpManagerService();
      addTearDown(server.close);

      await expectLater(
        manager.connectMcpWithAutoTransport(
          _connectionRequest(server.endpoint),
        ),
        throwsA(anything),
      );

      expect(server.sseGetCount, 0);
    });

    test('surfaces invalid SSE endpoint handshake failure', () async {
      final server = await _LocalMcpHttpServer.start(
        streamableStatus: 405,
        sseEndpoint: false,
      );
      final manager = McpManagerService();
      addTearDown(server.close);

      await expectLater(
        manager.connectMcpWithAutoTransport(
          _connectionRequest(server.endpoint),
        ),
        throwsA(anything),
      );

      expect(server.sseGetCount, 1);
    });

    test('reports legacy SSE unavailable when platform disallows it', () async {
      final server = await _LocalMcpHttpServer.start(streamableStatus: 405);
      final manager = McpManagerService(legacySseSupported: false);
      addTearDown(server.close);

      await expectLater(
        manager.connectMcpWithAutoTransport(
          _connectionRequest(server.endpoint),
        ),
        throwsA(isA<McpLegacySseUnavailableException>()),
      );

      expect(server.sseGetCount, 0);
    });
  });
}

McpConnectionRequest _connectionRequest(
  Uri endpoint, {
  McpAuthenticationType authenticationType = const McpAuthenticationTypeNone(),
}) => (
  name: 'Test MCP',
  url: endpoint.toString(),
  useHttp2: false,
  authenticationType: authenticationType,
  serviceConnectionId: null,
  description: null,
);

final class _LocalMcpHttpServer {
  new(
    this._server, {
    required this.streamableStatus,
    required this.sseStatus,
    required this.sseEndpoint,
    required this.useJsonRpcError,
  });

  final int streamableStatus;
  final int sseStatus;
  final bool sseEndpoint;
  final bool useJsonRpcError;
  int streamablePostCount = 0;
  int sseGetCount = 0;
  String? streamableAuthorization;
  String? sseAuthorization;
  String? sseMessageAuthorization;

  final HttpServer _server;
  final Completer<HttpResponse> _sseResponse = Completer<HttpResponse>();
  final Completer<void> _initializedNotification = Completer<void>();

  Uri get endpoint => Uri(
    scheme: 'http',
    host: _server.address.address,
    port: _server.port,
    path: '/mcp',
  );

  static Future<_LocalMcpHttpServer> start({
    int streamableStatus = 200,
    int sseStatus = 200,
    bool sseEndpoint = true,
    bool useJsonRpcError = false,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final local = _LocalMcpHttpServer(
      server,
      streamableStatus: streamableStatus,
      sseStatus: sseStatus,
      sseEndpoint: sseEndpoint,
      useJsonRpcError: useJsonRpcError,
    );
    final _ = server.listen((request) => unawaited(local._handle(request)));

    return local;
  }

  Future<void> close() async {
    final _ = await _server.close(force: true);
  }

  Future<void> waitForInitializedNotification() =>
      _initializedNotification.future.timeout(const Duration(seconds: 2));

  Future<void> _handle(HttpRequest request) async {
    if (request.method == 'GET' && request.uri.path == '/mcp') {
      await _handleSseGet(request);

      return;
    }
    if (request.method == 'POST' && request.uri.path == '/mcp') {
      await _handleStreamablePost(request);

      return;
    }
    if (request.method == 'POST' && request.uri.path == '/messages') {
      await _handleSsePost(request);

      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    final _ = await request.response.close();
  }

  Future<void> _handleStreamablePost(HttpRequest request) async {
    streamablePostCount++;
    streamableAuthorization = request.headers.value(
      HttpHeaders.authorizationHeader,
    );
    final message = await _readMessage(request);
    final response = request.response..statusCode = streamableStatus;
    if (streamableStatus != HttpStatus.ok) {
      if (useJsonRpcError) {
        response.headers.contentType = .json;
        response.write(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': message['id'],
            'error': {'code': -32600, 'message': 'Invalid request'},
          }),
        );
      } else {
        response.write('Streamable HTTP rejected');
      }
      final _ = await response.close();

      return;
    }

    response.headers.contentType = .json;
    response.write(jsonEncode(_initializeResult(message)));
    final _ = await response.close();
  }

  Future<void> _handleSseGet(HttpRequest request) async {
    sseGetCount++;
    sseAuthorization = request.headers.value(HttpHeaders.authorizationHeader);
    final response = request.response;
    if (sseStatus != HttpStatus.ok) {
      response
        ..statusCode = sseStatus
        ..write('SSE unavailable');
      final _ = await response.close();

      return;
    }

    response.headers.set(HttpHeaders.contentTypeHeader, 'text/event-stream');
    response.bufferOutput = false;
    if (!sseEndpoint) {
      final _ = await response.close();

      return;
    }
    response.write('event: endpoint\ndata: /messages\n\n');
    final _ = await response.flush();
    _sseResponse.complete(response);
    final _ = await response.done;
  }

  Future<void> _handleSsePost(HttpRequest request) async {
    sseMessageAuthorization = request.headers.value(
      HttpHeaders.authorizationHeader,
    );
    final message = await _readMessage(request);
    if (message['method'] == 'initialize') {
      final response = await _sseResponse.future;
      response.write(
        'event: message\ndata: ${jsonEncode(_initializeResult(message))}\n\n',
      );
      final _ = await response.flush();
    }
    request.response.statusCode = HttpStatus.accepted;
    final _ = await request.response.close();
    if (message['method'] == 'notifications/initialized' &&
        !_initializedNotification.isCompleted) {
      _initializedNotification.complete();
    }
  }

  Future<Map<String, Object?>> _readMessage(HttpRequest request) async {
    final body = await utf8.decodeStream(request.cast<List<int>>());
    final decoded = jsonDecode(body);
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Invalid MCP JSON-RPC request.');
    }

    return Map<String, Object?>.from(decoded);
  }
}

Map<String, Object?> _initializeResult(Map<String, Object?> request) => {
  'jsonrpc': '2.0',
  'id': request['id'],
  'result': {
    'protocolVersion': _objectMap(request['params'])['protocolVersion'],
    'capabilities': <String, Object?>{},
    'serverInfo': {'name': 'test-server', 'version': '1.0'},
  },
};

Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Invalid MCP initialize parameters.');
  }

  return Map<String, Object?>.from(value);
}
