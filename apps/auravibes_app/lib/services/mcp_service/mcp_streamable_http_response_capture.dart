import 'dart:convert';

import 'package:http/http.dart' as http;

/// Captures legacy transport rejection signals from the initialize request.
final class McpStreamableHttpResponseCapture extends http.BaseClient {
  new({http.Client? innerClient}) : _innerClient = innerClient ?? http.Client();

  final http.Client _innerClient;
  var _legacySseSignal = false;
  var _isClosed = false;

  bool get shouldFallbackToLegacySse => _legacySseSignal;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final initializeRequest = _initializeRequest(request);
    final response = await _innerClient.send(request);
    if (initializeRequest == null ||
        !_isCompatibilityStatus(response.statusCode)) {
      return response;
    }

    final body = await response.stream.toBytes();
    _legacySseSignal = !_isJsonRpcErrorResponse(body, initializeRequest['id']);

    return _replayResponse(response, body);
  }

  @override
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _innerClient.close();
  }

  static Map<String, Object?>? _initializeRequest(http.BaseRequest request) {
    if (request is! http.Request || request.method != 'POST') return null;
    try {
      final decoded = jsonDecode(request.body);
      if (decoded is! Map) return null;
      final message = Map<String, Object?>.from(decoded);
      if (message['jsonrpc'] != '2.0' || message['method'] != 'initialize') {
        return null;
      }

      return message;
    } on FormatException {
      return null;
    }
  }

  static bool _isCompatibilityStatus(int statusCode) =>
      statusCode == 400 || statusCode == 404 || statusCode == 405;

  static bool _isJsonRpcErrorResponse(List<int> body, Object? requestId) {
    if (requestId == null || body.isEmpty) return false;
    final decoded = _decodeResponseBody(body);
    if (decoded == null) return false;

    return decoded['jsonrpc'] == '2.0' &&
        decoded['id'] == requestId &&
        _hasJsonRpcError(decoded['error']);
  }

  static Map<Object?, Object?>? _decodeResponseBody(List<int> body) {
    try {
      final decoded = jsonDecode(utf8.decode(body));
      if (decoded is Map<Object?, Object?>) return decoded;

      return null;
    } on FormatException {
      return null;
    }
  }

  static bool _hasJsonRpcError(Object? value) {
    if (value is! Map<Object?, Object?>) return false;

    return value['code'] is num && value['message'] is String;
  }

  static http.StreamedResponse _replayResponse(
    http.StreamedResponse response,
    List<int> body,
  ) => http.StreamedResponse(
    Stream<List<int>>.value(body),
    response.statusCode,
    contentLength: body.length,
    request: response.request,
    headers: response.headers,
    isRedirect: response.isRedirect,
    persistentConnection: response.persistentConnection,
    reasonPhrase: response.reasonPhrase,
  );
}
