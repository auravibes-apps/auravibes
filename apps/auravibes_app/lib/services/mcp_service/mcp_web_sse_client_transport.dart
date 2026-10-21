import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/services/mcp_service/mcp_legacy_sse_unavailable_exception.dart';
import 'package:http/http.dart' as http;
import 'package:mcp_client/mcp_client.dart' as mcp;

/// Browser-compatible HTTP+SSE transport for legacy MCP servers.
class McpWebSseClientTransport implements mcp.ClientTransport {
  static const _timeout = Duration(seconds: 10);
  static const int _maxEventBytes = 1024 * 1024;
  static const int _okStatusCode = 200;
  static const int _acceptedStatusCode = 202;

  new internal({
    required this._client,
    required Map<String, String> headers,
    required this._headersProvider,
  }) : _headers = Map.unmodifiable(headers);

  final http.Client _client;
  final Map<String, String> _headers;
  final Future<Map<String, String>> Function(String method)? _headersProvider;
  final _messages = StreamController<Object?>.broadcast(sync: true);
  final _endpoint = Completer<Uri>();
  final _closed = Completer<void>();
  StreamSubscription<String>? _subscription;
  var _isClosed = false;

  @override
  Stream<Object?> get onMessage => _messages.stream;

  @override
  Future<void> get onClose => _closed.future;

  /// Opens SSE stream and resolves its same-origin message endpoint.
  static Future<McpWebSseClientTransport> create({
    required String serverUrl,
    Map<String, String> headers = const {},
    Future<Map<String, String>> Function(String method)? headersProvider,
    http.Client? client,
  }) => _McpWebSseTransportConnector(
    serverUri: .parse(serverUrl),
    headers: headers,
    headersProvider: headersProvider,
    client: client ?? http.Client(),
  ).connect();

  @override
  void send(Object? message) {
    if (_isClosed) return;

    unawaited(_send(message));
  }

  @override
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _client.close();
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (!_closed.isCompleted) _closed.complete();
    if (!_messages.isClosed) {
      scheduleMicrotask(() {
        if (!_messages.isClosed) unawaited(_messages.close());
      });
    }
  }

  Future<void> _send(Object? message) async {
    try {
      await _McpWebSseMessageSender(
        client: _client,
        endpoint: _endpoint,
        headersFor: _headersFor,
      ).send(message);
    } on Object catch (error, stackTrace) {
      _fail(error, stackTrace);
    }
  }

  Future<Map<String, String>> _headersFor(String method) async {
    final headers = {..._headers};
    final provider = _headersProvider;
    if (provider != null) headers.addAll(await provider(method));

    return headers;
  }

  void _fail(Object error, StackTrace stackTrace) {
    if (_isClosed) return;
    final failure = error is http.ClientException || error is TimeoutException
        ? const McpLegacySseUnavailableException()
        : error;
    if (!_endpoint.isCompleted) _endpoint.completeError(failure, stackTrace);
    if (!_messages.isClosed) _messages.addError(failure, stackTrace);
    close();
  }
}

final class _McpWebSseTransportConnector {
  new({
    required this._serverUri,
    required Map<String, String> headers,
    required this._headersProvider,
    required this._client,
  }) : _headers = Map.unmodifiable(headers);

  final Uri _serverUri;
  final Map<String, String> _headers;
  final Future<Map<String, String>> Function(String method)? _headersProvider;
  final http.Client _client;

  Future<McpWebSseClientTransport> connect() {
    final transport = McpWebSseClientTransport.internal(
      client: _client,
      headers: _headers,
      headersProvider: _headersProvider,
    );

    return _connect(transport);
  }

  Future<McpWebSseClientTransport> _connect(
    McpWebSseClientTransport transport,
  ) async {
    try {
      await _openEventStream(transport);
      final _ = await transport._endpoint.future.timeout(
        McpWebSseClientTransport._timeout,
      );

      return transport;
    } on Object catch (error, stackTrace) {
      transport.close();
      if (error is http.ClientException || error is TimeoutException) {
        Error.throwWithStackTrace(
          const McpLegacySseUnavailableException(),
          stackTrace,
        );
      }
      rethrow;
    }
  }

  Future<void> _openEventStream(McpWebSseClientTransport transport) async {
    final request = await _createStreamRequest(transport);
    final response = await _client
        .send(request)
        .timeout(McpWebSseClientTransport._timeout);
    if (!_isEventStreamResponse(response)) {
      await response.stream.drain<void>();
      throw const FormatException('MCP SSE handshake failed.');
    }

    _listenForEvents(response, transport);
  }

  Future<http.Request> _createStreamRequest(
    McpWebSseClientTransport transport,
  ) async {
    return http.Request('GET', _serverUri)
      ..headers['Accept'] = 'text/event-stream'
      ..headers.addAll(await transport._headersFor('GET'));
  }

  void _listenForEvents(
    http.StreamedResponse response,
    McpWebSseClientTransport transport,
  ) {
    final parser = _createParser(transport);
    transport._subscription = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          parser.addLine,
          onError: transport._fail,
          onDone: parser._onDone,
        );
  }

  _McpSseEventParser _createParser(McpWebSseClientTransport transport) =>
      _McpSseEventParser(
        serverUri: _serverUri,
        endpoint: transport._endpoint,
        onMessage: transport._messages.add,
        onError: transport._fail,
        onClose: transport.close,
      );

  bool _isEventStreamResponse(http.StreamedResponse response) =>
      response.statusCode == McpWebSseClientTransport._okStatusCode &&
      response.headers['content-type']?.split(';').first.trim().toLowerCase() ==
          'text/event-stream';
}

final class _McpWebSseMessageSender {
  new({
    required this._client,
    required this._endpoint,
    required this._headersFor,
  });

  final http.Client _client;
  final Completer<Uri> _endpoint;
  final Future<Map<String, String>> Function(String method) _headersFor;

  Future<void> send(Object? message) async {
    final request = await _createRequest(message);
    final response = await _client
        .send(request)
        .timeout(McpWebSseClientTransport._timeout);
    await _consumeResponse(response);
  }

  Future<http.Request> _createRequest(Object? message) async {
    final endpoint = await _endpoint.future;
    final headers = await _headersFor('POST');

    return http.Request('POST', endpoint)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json'
      ..headers.addAll(headers)
      ..body = jsonEncode(message);
  }

  Future<void> _consumeResponse(http.StreamedResponse response) async {
    if (response.statusCode != McpWebSseClientTransport._okStatusCode &&
        response.statusCode != McpWebSseClientTransport._acceptedStatusCode) {
      await response.stream.drain<void>();
      throw FormatException(
        'MCP SSE message rejected (${response.statusCode}).',
      );
    }
    await response.stream.drain<void>().timeout(
      McpWebSseClientTransport._timeout,
    );
  }
}

final class _McpSseEventParser {
  new({
    required this._serverUri,
    required this._endpoint,
    required this._onMessage,
    required this._onError,
    required this._onClose,
  });

  final Uri _serverUri;
  final Completer<Uri> _endpoint;
  final void Function(Object?) _onMessage;
  final void Function(Object, StackTrace) _onError;
  final void Function() _onClose;
  final _eventData = <String>[];
  var _eventType = 'message';
  var _eventSize = 0;
  var _firstLine = true;

  void addLine(String line) {
    final currentLine = _normalizeFirstLine(line);
    if (currentLine.isEmpty) {
      _dispatchEvent();

      return;
    }
    _eventSize += utf8.encode(currentLine).length;
    if (_eventSize > McpWebSseClientTransport._maxEventBytes) {
      _onError(const FormatException('MCP SSE event is too large.'), .current);

      return;
    }
    if (!currentLine.startsWith(':')) _parseField(currentLine);
  }

  String _normalizeFirstLine(String line) {
    var currentLine = line;
    if (_firstLine) {
      _firstLine = false;
      if (currentLine.isNotEmpty && currentLine.codeUnitAt(0) == 0xFEFF) {
        currentLine = String.fromCharCodes(currentLine.codeUnits.skip(1));
      }
    }

    return currentLine;
  }

  void _parseField(String line) {
    final separator = line.indexOf(':');
    final parts = line.split(':');
    final field = parts.firstOrNull ?? '';
    final value = _fieldValue(parts, separator);
    if (field == 'event') {
      _eventType = value;
    } else if (field == 'data') {
      _eventData.add(value);
    }
  }

  String _fieldValue(List<String> parts, int separator) {
    var value = separator < 0 ? '' : parts.skip(1).join(':');
    if (value.startsWith(' ')) value = value.replaceFirst(' ', '');

    return value;
  }

  void _dispatchEvent() {
    if (_eventData.isNotEmpty) {
      final data = _eventData.join('\n');
      if (_eventType == 'endpoint') {
        _completeEndpoint(data);
      } else if (_eventType == 'message') {
        _dispatchMessage(data);
      }
    }
    _eventType = 'message';
    _eventData.clear();
    _eventSize = 0;
  }

  void _dispatchMessage(String data) {
    try {
      final message = jsonDecode(data);
      if (message is! Map) {
        throw const FormatException('Invalid MCP SSE message.');
      }
      _onMessage(Map<String, Object?>.from(message));
    } on Object catch (error, stackTrace) {
      _onError(error, stackTrace);
    }
  }

  void _completeEndpoint(String value) {
    if (_endpoint.isCompleted) return;
    try {
      final endpointValue = value.trim();
      if (endpointValue.isEmpty) {
        throw const FormatException('MCP SSE endpoint missing.');
      }
      final endpoint = _serverUri.resolve(endpointValue);
      if (!_isSameOrigin(endpoint)) {
        throw const FormatException('MCP SSE endpoint changed origin.');
      }
      _endpoint.complete(endpoint);
    } on Object catch (error, stackTrace) {
      _endpoint.completeError(error, stackTrace);
    }
  }

  bool _isSameOrigin(Uri endpoint) =>
      endpoint.scheme == _serverUri.scheme &&
      endpoint.host == _serverUri.host &&
      endpoint.port == _serverUri.port &&
      endpoint.userInfo.isEmpty &&
      !endpoint.hasFragment;

  void _onDone() {
    if (!_endpoint.isCompleted) {
      _endpoint.completeError(
        const FormatException('MCP SSE endpoint missing.'),
      );
    }
    _onClose();
  }
}
