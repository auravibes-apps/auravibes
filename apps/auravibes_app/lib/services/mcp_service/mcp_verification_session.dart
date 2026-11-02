import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_app/services/mcp_service/mcp_sdk_adapter.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

/// An owned verification-only client. No ordinary call's handler is touched.
class McpVerificationSession {
  new({
    required this._client,
    required this.serverId,
    required this.toolIdentifier,
  }) {
    _client.onElicitationRequestTyped(_rejectElicitation);
  }

  final String serverId;
  final String toolIdentifier;
  final mcp.Client _client;
  final _elicited = Completer<void>();
  StreamSubscription<Object?>? _transportObserver;
  bool _closed = false;

  mcp.ClientTransport guardTransport(mcp.ClientTransport transport) {
    if (_closed || _transportObserver != null) {
      transport.close();
      throw StateError('Verification transport is already bound or closed.');
    }
    // The SDK uses the concrete transport type to set protocol headers.
    // Observe its broadcast stream without replacing that transport.
    _transportObserver = transport.onMessage.listen(
      _inspectMessage,
      onError: (Object _) => close(),
      onDone: close,
    );

    return transport;
  }

  Future<Object?> call({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
    McpElicitationHandler? onElicitation,
  }) => _callVerificationTool(this, (
    mcpServerId: mcpServerId,
    toolIdentifier: toolIdentifier,
    arguments: arguments,
    onElicitation: onElicitation,
  ));

  void close() {
    if (_closed) return;
    _closed = true;
    unawaited(_transportObserver?.cancel());
    _transportObserver = null;
    if (!_elicited.isCompleted) _elicited.complete();
    _client.disconnect();
  }

  void _inspectMessage(Object? message) {
    var value = message;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        return;
      }
    }
    if (value is Map<Object?, Object?> &&
        value['method'] == 'elicitation/create' &&
        !_elicited.isCompleted) {
      _elicited.complete();
    }
  }

  Future<mcp.CallToolResult> _rejectPendingInteraction() async {
    await _elicited.future;
    throw const FormatException('Verification cannot request interaction.');
  }

  Future<mcp.ElicitResult> _rejectElicitation(
    mcp.ElicitRequestParams request,
  ) async {
    if (!_elicited.isCompleted) _elicited.complete();

    return mcp.ElicitResult(action: mcp.ElicitResultAction.cancel);
  }
}

typedef _VerificationToolCall = ({
  String mcpServerId,
  String toolIdentifier,
  Map<String, dynamic> arguments,
  McpElicitationHandler? onElicitation,
});

Future<Object?> _callVerificationTool(
  McpVerificationSession session,
  _VerificationToolCall request,
) async {
  _validateVerificationToolCall(session, request);
  final pending = session._client.callTool(
    request.toolIdentifier,
    request.arguments,
  );
  final result = _isVerificationCleanup(request.arguments)
      ? await pending
      : await Future.any([pending, session._rejectPendingInteraction()]);

  return _adaptVerificationToolResult(result);
}

void _validateVerificationToolCall(
  McpVerificationSession session,
  _VerificationToolCall request,
) {
  if (!_matchesVerificationSession(session, request)) {
    throw StateError('Invalid verification session request.');
  }
  if (session._elicited.isCompleted &&
      !_isVerificationCleanup(request.arguments)) {
    throw const FormatException('Verification cannot request interaction.');
  }
}

bool _matchesVerificationSession(
  McpVerificationSession session,
  _VerificationToolCall request,
) =>
    !session._closed &&
    request.mcpServerId == session.serverId &&
    request.toolIdentifier == session.toolIdentifier &&
    request.onElicitation == null &&
    request.arguments['protocol'] == ScopedVerificationLimits.protocol;

bool _isVerificationCleanup(Map<String, dynamic> arguments) =>
    arguments['operation'] == 'cancel';

Object _adaptVerificationToolResult(mcp.CallToolResult result) {
  final adapted = McpSdkAdapter.toolResult(result);

  return McpToolCallerResult(
    modelText: adapted.toModelText(),
    appData: const {},
    structuredContent: adapted.structuredContent,
    isError: adapted.isError,
  );
}
