import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mcp_server_policy.dart';
import 'pinned_http_client.dart';

/// Legacy HTTP+SSE MCP session, bound to one validated origin and IP.
class McpSseSession {
  McpSseSession._(
    this._client,
    this._events,
    this._bearerToken,
    this._headers,
  );

  static const _timeout = Duration(seconds: 10);
  static const _operationTimeout = Duration(seconds: 30);
  final HttpClient _client;
  final StreamIterator<List<int>> _events;
  final String? _bearerToken;
  final Map<String, String> _headers;
  Uri? _endpoint;
  List<int> _chunk = const [];
  int _chunkOffset = 0;

  HttpClient get client => _client;

  static Future<McpSseSession> connect(
    Uri uri,
    InternetAddress address, {
    String? bearerToken,
    Map<String, String> httpHeaders = const {},
  }) async {
    final client = pinnedHttpClient(uri, address)
      ..connectionTimeout = _timeout
      ..autoUncompress = false;
    try {
      final request = await client.getUrl(uri).timeout(_timeout);
      request
        ..followRedirects = false
        ..maxRedirects = 0
        ..headers.set(HttpHeaders.acceptHeader, 'text/event-stream')
        ..headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      _applyAuth(request, bearerToken, httpHeaders);
      final response = await request.close().timeout(_timeout);
      if (response.isRedirect ||
          response.statusCode != HttpStatus.ok ||
          response.headers.contentType?.mimeType != 'text/event-stream') {
        throw const HttpException('MCP SSE handshake failed.');
      }
      final session = McpSseSession._(
        client,
        StreamIterator(response),
        bearerToken,
        Map.unmodifiable(httpHeaders),
      );
      await (() async {
        while (session._endpoint == null) {
          final event = await session._readEvent();
          if (event == null) {
            throw const FormatException('MCP SSE endpoint missing.');
          }
          if (event.type != 'endpoint') continue;
          final endpoint = uri.resolve(event.data.trim());
          if (endpoint.scheme != uri.scheme ||
              endpoint.host != uri.host ||
              endpoint.port != uri.port ||
              endpoint.userInfo.isNotEmpty ||
              endpoint.hasFragment) {
            throw const FormatException('MCP SSE endpoint changed origin.');
          }
          session._endpoint = endpoint;
        }
      })().timeout(_operationTimeout);
      return session;
    } on Object {
      client.close(force: true);
      rethrow;
    }
  }

  Future<Map<String, Object?>> request(
    int id,
    String method,
    Map<String, Object?> params,
  ) async {
    try {
      return await (() async {
        await _post({
          'jsonrpc': '2.0',
          'id': id,
          'method': method,
          'params': params,
        });
        while (true) {
          final event = await _readEvent();
          if (event == null) {
            throw const FormatException('MCP SSE response missing.');
          }
          if (event.type != 'message') continue;
          final value = jsonDecode(event.data);
          if (value is! Map<String, dynamic> || value['id'] != id) continue;
          if (value['error'] != null || value['result'] is! Map) {
            throw const FormatException('Invalid MCP SSE response.');
          }
          return Map<String, Object?>.from(value['result']! as Map);
        }
      })().timeout(_operationTimeout);
    } on TimeoutException {
      _client.close(force: true);
      rethrow;
    }
  }

  Future<void> notify(String method, Map<String, Object?> params) async {
    try {
      await _post({
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
      }).timeout(_operationTimeout);
    } on TimeoutException {
      _client.close(force: true);
      rethrow;
    }
  }

  Future<void> _post(Map<String, Object?> body) async {
    final endpoint = _endpoint;
    if (endpoint == null) {
      throw const FormatException('MCP SSE endpoint missing.');
    }
    final request = await _client.postUrl(endpoint).timeout(_timeout);
    request
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers.contentType = ContentType.json
      ..headers.set(HttpHeaders.acceptHeader, 'application/json')
      ..headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    _applyAuth(request, _bearerToken, _headers);
    request.write(jsonEncode(body));
    final response = await request.close().timeout(_timeout);
    if (response.isRedirect ||
        response.statusCode != HttpStatus.accepted &&
            response.statusCode != HttpStatus.ok) {
      throw const HttpException('MCP SSE message rejected.');
    }
    await (() async {
      var size = 0;
      await for (final chunk in response.timeout(_timeout)) {
        size += chunk.length;
        if (size > McpServerPolicy.maxResponseBytes) {
          throw const FormatException('MCP SSE response is too large.');
        }
      }
    })().timeout(_operationTimeout);
  }

  Future<({String type, String data})?> _readEvent() async {
    var type = 'message';
    final data = <String>[];
    var size = 0;
    while (true) {
      final line = await _readLine();
      if (line == null) return null;
      size += utf8.encode(line).length;
      if (size > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('MCP SSE event is too large.');
      }
      if (line.isEmpty) {
        if (data.isNotEmpty) return (type: type, data: data.join('\n'));
        type = 'message';
        size = 0;
        continue;
      }
      if (line.startsWith('event:')) type = line.substring(6).trimLeft();
      if (line.startsWith('data:')) data.add(line.substring(5).trimLeft());
    }
  }

  Future<String?> _readLine() async {
    final bytes = <int>[];
    while (true) {
      if (_chunkOffset == _chunk.length) {
        if (!await _events.moveNext().timeout(_timeout)) return null;
        _chunk = _events.current;
        _chunkOffset = 0;
      }
      final byte = _chunk[_chunkOffset++];
      if (byte == 10) {
        if (bytes.isNotEmpty && bytes.last == 13) bytes.removeLast();
        return utf8.decode(bytes);
      }
      bytes.add(byte);
      if (bytes.length > McpServerPolicy.maxResponseBytes) {
        throw const FormatException('MCP SSE line is too large.');
      }
    }
  }

  Future<void> close() async {
    await _events.cancel();
    _client.close(force: true);
  }
}

void _applyAuth(
  HttpClientRequest request,
  String? bearerToken,
  Map<String, String> headers,
) {
  if (bearerToken != null) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
  }
  headers.forEach(request.headers.set);
}
