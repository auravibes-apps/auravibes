import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../generated/protocol.dart';
import 'mcp_server_policy.dart';

typedef McpAddressLookup = Future<List<InternetAddress>> Function(String host);

class McpServerProbe {
  McpServerProbe({McpAddressLookup? lookup})
    : _lookup = lookup ?? InternetAddress.lookup;

  static const _timeout = Duration(seconds: 10);
  final McpAddressLookup _lookup;

  Future<DiscoverMcpServerResult> call({
    required Uri uri,
    required String transport,
    required bool useHttp2,
    String? bearerToken,
  }) async {
    if (transport != 'streamableHttp') {
      throw const FormatException('Unsupported MCP transport.');
    }
    if (useHttp2) {
      throw const FormatException('HTTP/2 MCP discovery is not supported.');
    }
    final addresses = await _lookup(uri.host).timeout(_timeout);
    McpServerPolicy.validateAddresses(addresses);
    final client = HttpClient()
      ..connectionTimeout = _timeout
      ..autoUncompress = false
      ..connectionFactory = (target, proxyHost, proxyPort) =>
          Socket.startConnect(addresses.first, target.port);
    try {
      final initialized = await _rpc(
        client,
        uri,
        bearerToken,
        1,
        'initialize',
        {
          'protocolVersion': '2025-06-18',
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'AuraVibes Server', 'version': '1.0.0'},
        },
      );
      await _rpc(
        client,
        uri,
        bearerToken,
        null,
        'notifications/initialized',
        const <String, Object?>{},
        sessionId: initialized.sessionId,
        notification: true,
      );
      final toolsResult = await _rpc(
        client,
        uri,
        bearerToken,
        2,
        'tools/list',
        const <String, Object?>{},
        sessionId: initialized.sessionId,
      );
      final toolsJson = toolsResult.result['tools'];
      if (toolsJson is! List || toolsJson.length > McpServerPolicy.maxTools) {
        throw const FormatException('Invalid MCP tools response.');
      }
      final tools = toolsJson
          .map((value) {
            if (value is! Map<Object?, Object?> || value['name'] is! String) {
              throw const FormatException('Invalid MCP tool.');
            }
            final name = value['name']! as String;
            if (name.isEmpty || name.length > 200) {
              throw const FormatException('Invalid MCP tool name.');
            }
            final description = value['description'];
            if (description != null &&
                (description is! String || description.length > 4000)) {
              throw const FormatException('Invalid MCP tool description.');
            }
            return DiscoveredMcpTool(
              name: name,
              description: description as String?,
              inputSchemaJson: McpServerPolicy.boundedSchema(
                value['inputSchema'] ?? const <String, Object?>{},
              ),
            );
          })
          .toList(growable: false);
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
      client.close(force: true);
    }
  }

  Future<({Map<String, Object?> result, String? sessionId})> _rpc(
    HttpClient client,
    Uri uri,
    String? token,
    int? id,
    String method,
    Map<String, Object?> params, {
    String? sessionId,
    bool notification = false,
  }) async {
    final request = await client.postUrl(uri).timeout(_timeout);
    request
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers.contentType = ContentType.json
      ..headers.set('Accept', 'application/json');
    if (token != null) request.headers.set('Authorization', 'Bearer $token');
    if (sessionId != null) request.headers.set('Mcp-Session-Id', sessionId);
    request.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': ?id,
        'method': method,
        'params': params,
      }),
    );
    final response = await request.close().timeout(_timeout);
    if (response.isRedirect ||
        response.statusCode != HttpStatus.ok &&
            (!notification || response.statusCode != HttpStatus.accepted)) {
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
