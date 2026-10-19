import 'dart:convert';

typedef McpAppToolCall = Future<Map<String, Object?>> Function(
  String toolName,
  Map<String, dynamic> arguments,
);

class McpAppMessageBridge {
  McpAppMessageBridge({
    required this.initialArguments,
    required this.initialResult,
    required this.callTool,
    this.hostVersion = '0.0.6',
  });

  final Map<String, dynamic> initialArguments;
  final Map<String, Object?> initialResult;
  final McpAppToolCall callTool;
  final String hostVersion;

  var _initializeReceived = false;
  var _initialized = false;
  var _initialDataSent = false;

  Future<List<Map<String, Object?>>> handleMessage(String message) async {
    // shortcut: caps inbound app messages at 1 MiB, raise after measured demand.
    if (utf8.encode(message).length > (1 << 20)) {
      return [_error(null, -32600, 'MCP App request is too large.')];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      return const [];
    }
    if (decoded is! Map || decoded['jsonrpc'] != '2.0') return const [];
    final request = Map<String, Object?>.from(decoded);
    final method = request['method'];
    if (method is! String) return const [];
    final id = request['id'];
    final hasId = request.containsKey('id');

    if (!hasId) return _handleNotification(method);
    if (id is! String && id is! num) return const [];
    final requestId = id as Object;

    return switch (method) {
      'ui/initialize' => _initialize(requestId),
      'ping' => [_success(requestId, const {})],
      'tools/call' => await _callTool(requestId, request['params']),
      _ => [_error(requestId, -32601, 'Unsupported MCP App request.')],
    };
  }

  List<Map<String, Object?>> _initialize(Object id) {
    _initializeReceived = true;

    return [
      _success(id, {
        'protocolVersion': '2026-01-26',
        'hostInfo': {'name': 'AuraVibes', 'version': hostVersion},
        'hostCapabilities': {'serverTools': {}},
        'hostContext': {
          'displayMode': 'inline',
          'availableDisplayModes': ['inline'],
        },
      }),
    ];
  }

  List<Map<String, Object?>> _handleNotification(String method) {
    if (method != 'ui/notifications/initialized' ||
        !_initializeReceived ||
        _initialDataSent) {
      return const [];
    }
    _initialized = true;
    _initialDataSent = true;

    return [
      {
        'jsonrpc': '2.0',
        'method': 'ui/notifications/tool-input',
        'params': {'arguments': initialArguments},
      },
      {
        'jsonrpc': '2.0',
        'method': 'ui/notifications/tool-result',
        'params': initialResult,
      },
    ];
  }

  Future<List<Map<String, Object?>>> _callTool(
    Object id,
    Object? params,
  ) async {
    if (!_initialized) {
      return [_error(id, -32002, 'MCP App is not initialized.')];
    }
    if (params is! Map || params['name'] is! String) {
      return [_error(id, -32602, 'Invalid tools/call parameters.')];
    }
    final Object? rawArguments = params['arguments'];
    if (rawArguments != null && rawArguments is! Map) {
      return [_error(id, -32602, 'Invalid tools/call arguments.')];
    }
    if (rawArguments is Map && rawArguments.keys.any((key) => key is! String)) {
      return [_error(id, -32602, 'Invalid tools/call arguments.')];
    }

    try {
      final result = await callTool(
        params['name']! as String,
        rawArguments is Map
            ? Map<String, dynamic>.from(rawArguments)
            : <String, dynamic>{},
      );

      return [_success(id, result)];
    } on Object {
      return [_error(id, -32000, 'MCP tool call failed.')];
    }
  }
}

Map<String, Object?> _success(Object id, Map<String, Object?> result) => {
  'jsonrpc': '2.0',
  'id': id,
  'result': result,
};

Map<String, Object?> _error(Object? id, int code, String message) => {
  'jsonrpc': '2.0',
  'id': id,
  'error': {'code': code, 'message': message},
};
