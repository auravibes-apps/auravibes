import 'dart:async';
import 'dart:convert';

const int _maxMcpAppMessageBytes = 1 << 20;
const _teardownTimeout = Duration(seconds: 1);
const _invalidRequestCode = -32600;
const _methodNotFoundCode = -32601;
const _invalidParamsCode = -32602;
const _appNotInitializedCode = -32002;
const _toolCallFailedCode = -32000;

typedef McpAppToolCall = Future<Map<String, Object?>> Function(
  String toolName,
  Map<String, dynamic> arguments,
);

typedef _ToolCallValidation = ({
  String? toolName,
  Map<String, dynamic>? arguments,
  String? errorMessage,
});
typedef _RawMcpAppToolCall = ({String name, Object? arguments});

class McpAppMessageBridge {
  new({
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
  var _teardownRequestId = '';
  var _nextTeardownRequestId = 0;
  Completer<void>? _teardownResponse;

  void reset() {
    _initializeReceived = false;
    _initialized = false;
    _initialDataSent = false;
    _teardownRequestId = '';
    _teardownResponse?.complete();
    _teardownResponse = null;
  }

  ({Map<String, Object?> message, Future<void> response})?
  beginResourceTeardown() {
    if (!_initialized) return null;

    final id = 'mcp-app-teardown-${++_nextTeardownRequestId}';
    final response = Completer<void>();
    _teardownRequestId = id;
    _teardownResponse = response;

    return _resourceTeardown(this, id, response);
  }

  Future<List<Map<String, Object?>>> handleMessage(String message) =>
      _handleMcpAppMessage(this, message);

  List<Map<String, Object?>> _initialize(Object id) {
    _initializeReceived = true;

    return [
      _success(id, {
        'protocolVersion': '2026-01-26',
        'hostInfo': {'name': 'AuraVibes', 'version': hostVersion},
        'hostCapabilities': {'serverTools': <String, Object?>{}},
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
      return [
        _error(id, _appNotInitializedCode, 'MCP App is not initialized.'),
      ];
    }

    return await _callInitializedTool(this, id, params);
  }
}

({Map<String, Object?> message, Future<void> response}) _resourceTeardown(
  McpAppMessageBridge bridge,
  String id,
  Completer<void> response,
) => (
  message: _resourceTeardownMessage(id),
  response: response.future.timeout(
    _teardownTimeout,
    onTimeout: () => _clearTeardownResponse(bridge, id),
  ),
);

Future<List<Map<String, Object?>>> _handleMcpAppMessage(
  McpAppMessageBridge bridge,
  String message,
) async {
  // Shortcut: 1 MiB inbound cap. Raise after measured demand.
  if (utf8.encode(message).length > _maxMcpAppMessageBytes) {
    return [_error(null, _invalidRequestCode, 'MCP App request is too large.')];
  }
  final request = _decodeMcpAppMessage(message);
  if (request == null) return const [];

  return await _dispatchMcpAppMessage(bridge, request);
}

Future<List<Map<String, Object?>>> _dispatchMcpAppMessage(
  McpAppMessageBridge bridge,
  Map<String, Object?> request,
) async {
  final method = request['method'];
  if (method is! String) {
    _completeTeardownResponse(bridge, request);

    return const [];
  }
  if (!request.containsKey('id')) return bridge._handleNotification(method);

  final requestId = _mcpAppRpcId(request['id']);
  if (requestId == null) return const [];

  return await _handleMcpAppRequest(
    bridge,
    requestId,
    method,
    request['params'],
  );
}

Future<List<Map<String, Object?>>> _callInitializedTool(
  McpAppMessageBridge bridge,
  Object id,
  Object? params,
) async {
  final validation = _validateToolCall(params);
  if (validation case (
    toolName: final String name,
    arguments: final Map<String, dynamic> args,
    errorMessage: null,
  )) {
    return await _runMcpAppTool(bridge.callTool, id, name, args);
  }

  return [
    _error(
      id,
      _invalidParamsCode,
      validation.errorMessage ?? 'Invalid tools/call parameters.',
    ),
  ];
}

Future<List<Map<String, Object?>>> _runMcpAppTool(
  McpAppToolCall callTool,
  Object id,
  String toolName,
  Map<String, dynamic> arguments,
) async {
  try {
    return [_success(id, await callTool(toolName, arguments))];
  } on Object {
    return [_error(id, _toolCallFailedCode, 'MCP tool call failed.')];
  }
}

Map<String, Object?> _resourceTeardownMessage(String id) => {
  'jsonrpc': '2.0',
  'id': id,
  'method': 'ui/resource-teardown',
  'params': {'reason': 'View is closing.'},
};

void _clearTeardownResponse(McpAppMessageBridge bridge, String id) {
  if (bridge._teardownRequestId != id) return;
  bridge
    .._teardownResponse = null
    .._teardownRequestId = '';
}

Map<String, Object?>? _decodeMcpAppMessage(String message) {
  try {
    final decoded = jsonDecode(message);
    if (decoded is Map && decoded['jsonrpc'] == '2.0') {
      return Map<String, Object?>.from(decoded);
    }
  } on FormatException {
    return null;
  }

  return null;
}

Object? _mcpAppRpcId(Object? value) => switch (value) {
  final String id => id,
  final num id => id,
  _ => null,
};

void _completeTeardownResponse(
  McpAppMessageBridge bridge,
  Map<String, Object?> response,
) {
  if (!response.containsKey('id') ||
      response['id'] != bridge._teardownRequestId) {
    return;
  }
  bridge._teardownResponse?.complete();
  bridge
    .._teardownResponse = null
    .._teardownRequestId = '';
}

Future<List<Map<String, Object?>>> _handleMcpAppRequest(
  McpAppMessageBridge bridge,
  Object id,
  String method,
  Object? params,
) async => switch (method) {
  'ui/initialize' => bridge._initialize(id),
  'ping' => [_success(id, const {})],
  'tools/call' => await bridge._callTool(id, params),
  _ => [_error(id, _methodNotFoundCode, 'Unsupported MCP App request.')],
};

_ToolCallValidation _validateToolCall(Object? params) {
  final call = _rawMcpAppToolCall(params);
  if (call == null) return _invalidToolCall('Invalid tools/call parameters.');
  final arguments = _validMcpAppToolArguments(call.arguments);
  if (arguments == null) {
    return _invalidToolCall('Invalid tools/call arguments.');
  }

  return (toolName: call.name, arguments: arguments, errorMessage: null);
}

_RawMcpAppToolCall? _rawMcpAppToolCall(Object? params) =>
    params is Map && params['name'] is String
    ? (name: params['name'] as String, arguments: params['arguments'])
    : null;

Map<String, dynamic>? _validMcpAppToolArguments(Object? value) {
  if (value != null && value is! Map) return null;
  if (value is Map && value.keys.any((key) => key is! String)) return null;

  return _toolCallArguments(value);
}

_ToolCallValidation _invalidToolCall(String errorMessage) =>
    (toolName: null, arguments: null, errorMessage: errorMessage);

Map<String, dynamic> _toolCallArguments(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

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
