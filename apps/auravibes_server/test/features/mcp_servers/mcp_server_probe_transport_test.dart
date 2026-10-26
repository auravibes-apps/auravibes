import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_server/src/features/mcp_servers/mcp_server_probe.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('keeps Streamable HTTP as first choice', () async {
    final fixture = await _ProbeFixture.start();
    addTearDown(fixture.close);

    final result = await _probe(fixture).call(
      uri: fixture.endpoint,
      transport: 'streamableHttp',
      useHttp2: false,
    );

    expect(result.health, McpServerHealth.healthy);
    expect(result.serverName, 'probe-fixture');
    expect(result.tools.map((tool) => tool.name), ['probe_tool']);
    expect(fixture.sseGetCount, 0);
    expect(fixture.methods, [
      'initialize',
      'notifications/initialized',
      'tools/list',
    ]);
  });

  for (final status in [400, 404, 405]) {
    test('falls back to SSE after Streamable HTTP $status', () async {
      final fixture = await _ProbeFixture.start(streamableStatus: status);
      addTearDown(fixture.close);

      final result = await _probe(fixture).call(
        uri: fixture.endpoint,
        transport: 'streamableHttp',
        useHttp2: false,
        bearerToken: 'cloud-bearer',
        httpHeaders: const {'X-MCP-Key': 'cloud-header'},
      );

      expect(result.health, McpServerHealth.healthy);
      expect(result.tools.map((tool) => tool.name), ['probe_tool']);
      expect(fixture.sseGetCount, 1);
      expect(fixture.methods, [
        'initialize',
        'initialize',
        'notifications/initialized',
        'tools/list',
      ]);
      expect(fixture.methods, isNot(contains('tools/call')));
      expect(
        fixture.receivedHeaders,
        everyElement({
          'Authorization': 'Bearer cloud-bearer',
          'X-MCP-Key': 'cloud-header',
        }),
      );
    });
  }

  test('fences every Streamable HTTP and SSE request dispatch', () async {
    final fixture = await _ProbeFixture.start(streamableStatus: 405);
    addTearDown(fixture.close);
    var lookups = 0;
    var dispatches = 0;
    final probe = McpServerProbe(
      lookup: (_) async {
        lookups++;
        return [InternetAddress('8.8.8.8')];
      },
      httpClientFactory: fixture.createClient,
    );
    final addresses = await probe.resolveAddresses(fixture.endpoint);
    final result = await probe(
      uri: fixture.endpoint,
      transport: 'streamableHttp',
      useHttp2: false,
      resolvedAddresses: addresses,
      dispatchFence: <T>(Future<T> Function() start) async {
        dispatches++;
        return start();
      },
    );

    expect(result.health, McpServerHealth.healthy);
    expect(lookups, 1);
    expect(dispatches, 5);
    expect(fixture.methods, [
      'initialize',
      'initialize',
      'notifications/initialized',
      'tools/list',
    ]);
  });

  test('does not fall back for a recognized JSON-RPC error', () async {
    final fixture = await _ProbeFixture.start(
      streamableStatus: 400,
      jsonRpcError: true,
    );
    addTearDown(fixture.close);

    await expectLater(
      _probe(fixture).call(
        uri: fixture.endpoint,
        transport: 'streamableHttp',
        useHttp2: false,
      ),
      throwsA(isA<HttpException>()),
    );

    expect(fixture.sseGetCount, 0);
    expect(fixture.methods, ['initialize']);
  });

  test('does not fall back for authorization failures', () async {
    final fixture = await _ProbeFixture.start(streamableStatus: 401);
    addTearDown(fixture.close);

    await expectLater(
      _probe(fixture).call(
        uri: fixture.endpoint,
        transport: 'streamableHttp',
        useHttp2: false,
      ),
      throwsA(isA<HttpException>()),
    );

    expect(fixture.sseGetCount, 0);
  });

  test('does not fall back after a network failure', () async {
    var clientsCreated = 0;
    final probe = McpServerProbe(
      lookup: (_) async => [InternetAddress('8.8.8.8')],
      httpClientFactory: (_, _) {
        clientsCreated++;
        throw const SocketException('offline');
      },
    );

    await expectLater(
      probe.call(
        uri: Uri.parse('http://example.com/mcp'),
        transport: 'streamableHttp',
        useHttp2: false,
      ),
      throwsA(isA<SocketException>()),
    );

    expect(clientsCreated, 1);
  });

  test(
    'rejects an invalid SSE handshake after compatibility response',
    () async {
      final fixture = await _ProbeFixture.start(
        streamableStatus: 405,
        invalidSseHandshake: true,
      );
      addTearDown(fixture.close);

      await expectLater(
        _probe(fixture).call(
          uri: fixture.endpoint,
          transport: 'streamableHttp',
          useHttp2: false,
        ),
        throwsA(isA<HttpException>()),
      );

      expect(fixture.sseGetCount, 1);
    },
  );
}

McpServerProbe _probe(_ProbeFixture fixture) => McpServerProbe(
  lookup: (_) async => [InternetAddress('8.8.8.8')],
  httpClientFactory: fixture.createClient,
);

final class _ProbeFixture {
  _ProbeFixture(
    this._server, {
    required this.streamableStatus,
    required this.jsonRpcError,
    required this.invalidSseHandshake,
  });

  final HttpServer _server;
  final int streamableStatus;
  final bool jsonRpcError;
  final bool invalidSseHandshake;
  final methods = <String>[];
  final receivedHeaders = <Map<String, String?>>[];
  HttpResponse? _sseResponse;
  var sseGetCount = 0;

  Uri get endpoint => Uri(
    scheme: 'http',
    host: 'example.com',
    port: _server.port,
    path: '/mcp',
  );

  static Future<_ProbeFixture> start({
    int streamableStatus = HttpStatus.ok,
    bool jsonRpcError = false,
    bool invalidSseHandshake = false,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _ProbeFixture(
      server,
      streamableStatus: streamableStatus,
      jsonRpcError: jsonRpcError,
      invalidSseHandshake: invalidSseHandshake,
    );
    final _ = server.listen((request) => unawaited(fixture._handle(request)));
    return fixture;
  }

  HttpClient createClient(Uri uri, InternetAddress _) {
    final client = HttpClient();
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (target, proxyHost, proxyPort) async {
      if (proxyHost != null ||
          proxyPort != null ||
          target.scheme != uri.scheme ||
          target.host != uri.host ||
          target.port != uri.port) {
        throw const SocketException('MCP request origin changed.');
      }
      return Socket.startConnect(InternetAddress.loopbackIPv4, _server.port);
    };
    return client;
  }

  Future<void> close() async {
    final _ = await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    receivedHeaders.add({
      'Authorization': request.headers.value(HttpHeaders.authorizationHeader),
      'X-MCP-Key': request.headers.value('X-MCP-Key'),
    });
    if (request.method == 'POST' && request.uri.path == '/mcp') {
      await _handleStreamable(request);
      return;
    }
    if (request.method == 'GET' && request.uri.path == '/mcp') {
      await _handleSseGet(request);
      return;
    }
    if (request.method == 'POST' && request.uri.path == '/messages') {
      await _handleSsePost(request);
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> _handleStreamable(HttpRequest request) async {
    final message = await _readMessage(request);
    methods.add(message['method']! as String);
    final response = request.response;
    if (message['method'] == 'initialize' &&
        streamableStatus != HttpStatus.ok) {
      response.statusCode = streamableStatus;
      if (jsonRpcError) {
        response.headers.contentType = ContentType.json;
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
      await response.close();
      return;
    }
    if (message['method'] == 'notifications/initialized') {
      response.statusCode = HttpStatus.accepted;
      await response.close();
      return;
    }
    response.headers.contentType = ContentType.json;
    if (message['method'] == 'initialize') {
      response.headers.set('Mcp-Session-Id', 'probe-session');
      response.write(jsonEncode(_initializeResult(message)));
    } else {
      response.write(jsonEncode(_toolsResult(message)));
    }
    await response.close();
  }

  Future<void> _handleSseGet(HttpRequest request) async {
    sseGetCount++;
    final response = request.response;
    if (invalidSseHandshake) {
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('not an event stream');
      await response.close();
      return;
    }
    response
      ..headers.set(HttpHeaders.contentTypeHeader, 'text/event-stream')
      ..bufferOutput = false
      ..write('event: endpoint\ndata: /messages\n\n');
    await response.flush();
    _sseResponse = response;
    await response.done;
  }

  Future<void> _handleSsePost(HttpRequest request) async {
    final message = await _readMessage(request);
    methods.add(message['method']! as String);
    if (message['method'] == 'initialize' ||
        message['method'] == 'tools/list') {
      final responseMessage = message['method'] == 'initialize'
          ? _initializeResult(message)
          : _toolsResult(message);
      final sseResponse = _sseResponse;
      if (sseResponse == null) {
        throw StateError('SSE stream not open.');
      }
      sseResponse.write(
        'event: message\ndata: ${jsonEncode(responseMessage)}\n\n',
      );
      await sseResponse.flush();
    }
    request.response.statusCode = HttpStatus.accepted;
    await request.response.close();
  }

  Future<Map<String, Object?>> _readMessage(HttpRequest request) async {
    final decoded = jsonDecode(await utf8.decodeStream(request));
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Invalid request.');
    }
    return Map<String, Object?>.from(decoded);
  }
}

Map<String, Object?> _initializeResult(Map<String, Object?> request) => {
  'jsonrpc': '2.0',
  'id': request['id'],
  'result': {
    'protocolVersion': '2025-06-18',
    'capabilities': <String, Object?>{},
    'serverInfo': {'name': 'probe-fixture', 'version': '1.0'},
  },
};

Map<String, Object?> _toolsResult(Map<String, Object?> request) => {
  'jsonrpc': '2.0',
  'id': request['id'],
  'result': {
    'tools': [
      {
        'name': 'probe_tool',
        'description': 'Probe fixture tool',
        'inputSchema': {'type': 'object'},
      },
    ],
  },
};
