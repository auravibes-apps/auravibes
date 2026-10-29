import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

import '../../generated/protocol.dart';
import 'mcp_server_policy.dart';
import 'mcp_sse_session.dart';
import 'pinned_http_client.dart';

typedef McpAddressLookup = Future<List<InternetAddress>> Function(String host);

typedef McpProbeHttpClientFactory = HttpClient Function(
  Uri uri,
  InternetAddress address,
);

class McpServerProbe {
  new({
    McpAddressLookup? lookup,
    McpProbeHttpClientFactory? httpClientFactory,
  }) : _lookup = lookup ?? InternetAddress.lookup,
       _httpClientFactory = httpClientFactory ?? pinnedHttpClient;

  static const _timeout = Duration(seconds: 10);
  final McpAddressLookup _lookup;
  final McpProbeHttpClientFactory _httpClientFactory;

  Future<List<InternetAddress>> resolveAddresses(Uri uri) async {
    final addresses = await _lookup(uri.host).timeout(_timeout);
    McpServerPolicy.validateAddresses(addresses);

    return addresses;
  }

  Future<DiscoverMcpServerResult> call({
    required Uri uri,
    required String transport,
    required bool useHttp2,
    String? bearerToken,
    Map<String, String> httpHeaders = const {},
    List<InternetAddress>? resolvedAddresses,
    McpOutboundRequestFence? dispatchFence,
  }) async {
    if (!{'streamableHttp', 'sse'}.contains(transport)) {
      throw const FormatException('Unsupported MCP transport.');
    }
    if (useHttp2) {
      throw const FormatException('HTTP/2 MCP discovery is not supported.');
    }
    final addresses = resolvedAddresses ?? await resolveAddresses(uri);
    McpServerPolicy.validateAddresses(addresses);
    if (transport == 'sse') {
      return _discoverSse(
        uri,
        addresses.first,
        bearerToken,
        httpHeaders,
        _httpClientFactory,
        dispatchFence,
      );
    }
    final client = _httpClientFactory(uri, addresses.first)
      ..connectionTimeout = _timeout
      ..autoUncompress = false;
    var clientClosed = false;
    try {
      late final ({Map<String, Object?> result, String? sessionId}) initialized;
      try {
        initialized = await _rpc(
          client,
          uri,
          bearerToken,
          httpHeaders,
          1,
          'initialize',
          {
            'protocolVersion': '2025-06-18',
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 'AuraVibes Server', 'version': '1.0.0'},
          },
          dispatchFence: dispatchFence,
        );
      } on _McpHttpResponseException catch (error) {
        client.close(force: true);
        clientClosed = true;
        if (error.isJsonRpcError) {
          throw const HttpException('MCP request failed.');
        }
        return await _discoverSse(
          uri,
          addresses.first,
          bearerToken,
          httpHeaders,
          _httpClientFactory,
          dispatchFence,
        );
      }
      await _rpc(
        client,
        uri,
        bearerToken,
        httpHeaders,
        null,
        'notifications/initialized',
        const <String, Object?>{},
        sessionId: initialized.sessionId,
        notification: true,
        dispatchFence: dispatchFence,
      );
      var requestId = 2;
      final tools = await collectCloudMcpTools((cursor) async {
        final page = await _rpc(
          client,
          uri,
          bearerToken,
          httpHeaders,
          requestId++,
          'tools/list',
          {'cursor': ?cursor},
          sessionId: initialized.sessionId,
          dispatchFence: dispatchFence,
        );
        return page.result;
      }).timeout(const Duration(seconds: 30));
      final serverInfo = initialized.result['serverInfo'];
      final info = serverInfo is Map<Object?, Object?> ? serverInfo : null;
      return DiscoverMcpServerResult(
        health: McpServerHealth.healthy,
        serverName: info?['name'] is String ? info!['name']! as String : null,
        serverVersion: info?['version'] is String
            ? info!['version']! as String
            : null,
        protocolVersion: initialized.result['protocolVersion'] is String
            ? initialized.result['protocolVersion']! as String
            : null,
        tools: tools,
      );
    } finally {
      if (!clientClosed) client.close(force: true);
    }
  }

  Future<DiscoverMcpServerResult> _discoverSse(
    Uri uri,
    InternetAddress address,
    String? bearerToken,
    Map<String, String> httpHeaders,
    McpProbeHttpClientFactory httpClientFactory,
    McpOutboundRequestFence? dispatchFence,
  ) async {
    final session = await McpSseSession.connect(
      uri,
      address,
      bearerToken: bearerToken,
      httpHeaders: httpHeaders,
      httpClient: httpClientFactory(uri, address),
      dispatchFence: dispatchFence,
    );
    try {
      final initialized = await session.request(1, 'initialize', {
        'protocolVersion': '2025-06-18',
        'capabilities': <String, Object?>{},
        'clientInfo': {'name': 'AuraVibes Server', 'version': '1.0.0'},
      });
      await session.notify('notifications/initialized', const {});
      var requestId = 2;
      final tools = await collectCloudMcpTools(
        (cursor) => session.request(
          requestId++,
          'tools/list',
          {'cursor': ?cursor},
        ),
      ).timeout(const Duration(seconds: 30));
      final serverInfo = initialized['serverInfo'];
      final info = serverInfo is Map<Object?, Object?> ? serverInfo : null;
      return DiscoverMcpServerResult(
        health: McpServerHealth.healthy,
        serverName: info?['name'] is String ? info!['name']! as String : null,
        serverVersion: info?['version'] is String
            ? info!['version']! as String
            : null,
        protocolVersion: initialized['protocolVersion'] is String
            ? initialized['protocolVersion']! as String
            : null,
        tools: tools,
      );
    } finally {
      await session.close();
    }
  }

  Future<({Map<String, Object?> result, String? sessionId})> _rpc(
    HttpClient client,
    Uri uri,
    String? token,
    Map<String, String> httpHeaders,
    int? id,
    String method,
    Map<String, Object?> params, {
    String? sessionId,
    bool notification = false,
    McpOutboundRequestFence? dispatchFence,
  }) async {
    final request = await client.postUrl(uri).timeout(_timeout);
    request
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers.contentType = ContentType.json
      ..headers.set('Accept', 'application/json');
    if (token != null) request.headers.set('Authorization', 'Bearer $token');
    httpHeaders.forEach(request.headers.set);
    if (sessionId != null) request.headers.set('Mcp-Session-Id', sessionId);
    request.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': ?id,
        'method': method,
        'params': params,
      }),
    );
    final response = await _sendRequest(
      dispatchFence,
      request.close,
    ).timeout(_timeout);
    if (response.isRedirect ||
        response.statusCode != HttpStatus.ok &&
            (!notification || response.statusCode != HttpStatus.accepted)) {
      if (method == 'initialize' &&
          id != null &&
          const {
            HttpStatus.badRequest,
            HttpStatus.notFound,
            HttpStatus.methodNotAllowed,
          }.contains(response.statusCode)) {
        final bytes = await _readResponseBody(response);
        throw _McpHttpResponseException(
          isJsonRpcError: _isRecognizedJsonRpcError(bytes, id),
        );
      }
      await _drain(response);
      throw const HttpException('MCP request failed.');
    }
    if (notification) {
      await _drain(response);
      return (
        result: const <String, Object?>{},
        sessionId: response.headers.value('Mcp-Session-Id'),
      );
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(_timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('MCP response is too large.');
      }
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?> || decoded['result'] is! Map) {
      throw const FormatException('Invalid MCP response.');
    }
    return (
      result: Map<String, Object?>.from(decoded['result']! as Map),
      sessionId: response.headers.value('Mcp-Session-Id'),
    );
  }

  Future<List<int>> _readResponseBody(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response.timeout(_timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('MCP response is too large.');
      }
    }
    return bytes;
  }

  Future<void> _drain(HttpClientResponse response) async {
    var length = 0;
    await for (final chunk in response.timeout(_timeout)) {
      length += chunk.length;
      if (length > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('MCP response is too large.');
      }
    }
  }
}

Future<T> _sendRequest<T>(
  McpOutboundRequestFence? dispatchFence,
  Future<T> Function() start,
) => dispatchFence == null ? start() : dispatchFence(start);

final class _McpHttpResponseException implements Exception {
  const _McpHttpResponseException({required this.isJsonRpcError});

  final bool isJsonRpcError;
}

bool _isRecognizedJsonRpcError(List<int> body, int requestId) {
  try {
    final decoded = jsonDecode(utf8.decode(body));
    if (decoded is! Map ||
        decoded['jsonrpc'] != '2.0' ||
        decoded['id'] != requestId) {
      return false;
    }
    final error = decoded['error'];
    return error is Map && error['code'] is num && error['message'] is String;
  } on FormatException {
    return false;
  }
}

Future<List<DiscoveredMcpTool>> collectCloudMcpTools(
  Future<Map<String, Object?>> Function(String? cursor) fetchPage,
) async {
  final rawTools = await collectMcpToolsCatalog(fetchPage);
  final discovered = parseMcpToolsList(
    {'tools': rawTools},
    maxTools: McpServerPolicy.maxTools,
    validateInputSchema: (schema) {
      McpServerPolicy.boundedSchema(schema);
    },
  );
  return [
    for (final tool in discovered)
      DiscoveredMcpTool(
        name: tool.name,
        description: tool.description,
        inputSchemaJson: McpServerPolicy.boundedSchema(tool.inputSchema),
        outputSchemaJson: tool.outputSchema == null
            ? null
            : McpServerPolicy.boundedSchema(tool.outputSchema),
      ),
  ];
}
