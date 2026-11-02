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
  }) async {
    if (_closed ||
        mcpServerId != serverId ||
        toolIdentifier != this.toolIdentifier ||
        onElicitation != null ||
        arguments['protocol'] != ScopedVerificationLimits.protocol) {
      throw StateError('Invalid verification session request.');
    }
    final cleanup = arguments['operation'] == 'cancel';
    if (_elicited.isCompleted && !cleanup) {
      throw const FormatException('Verification cannot request interaction.');
    }
    // This private client permits start/cancel concurrency. It never enters
    // the ordinary connection's serialized elicitation queue.
    final pending = _client.callTool(toolIdentifier, arguments);
    final result = cleanup
        ? await pending
        : await Future.any([pending, _rejectPendingInteraction()]);
    final adapted = McpSdkAdapter.toolResult(result);

    return McpToolCallerResult(
      modelText: adapted.toModelText(),
      appData: const {},
      structuredContent: adapted.structuredContent,
      isError: adapted.isError,
    );
  }

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
