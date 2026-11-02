import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_app/services/mcp_service/mcp_sdk_adapter.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

/// An owned verification-only client. No ordinary call's handler is touched.
class McpVerificationSession {
  new({required mcp.Client client, required this.serverId, required this.toolIdentifier}) : _client = client {
    _client.onElicitationRequestTyped(_rejectElicitation);
  }

  final mcp.Client _client;
  final String serverId;
  final String toolIdentifier;
  final _elicited = Completer<void>();
  bool _closed = false;

  mcp.ClientTransport guardTransport(mcp.ClientTransport transport) => _VerificationTransport(transport, _inspectMessage);

  void _inspectMessage(Object? message) {
    Object? value = message;
    if (value is String) {
      try { value = jsonDecode(value); } on FormatException { return; }
    }
    if (value is Map<Object?, Object?> && value['method'] == 'elicitation/create' && !_elicited.isCompleted) _elicited.complete();
  }

  Future<Object?> call({required String mcpServerId, required String toolIdentifier, required Map<String, dynamic> arguments, McpElicitationHandler? onElicitation}) async {
    if (_closed || mcpServerId != serverId || toolIdentifier != this.toolIdentifier || onElicitation != null || arguments['protocol'] != ScopedVerificationLimits.protocol) {
      throw StateError('Invalid verification session request.');
    }
    final cleanup = arguments['operation'] == 'cancel';
    if (_elicited.isCompleted && !cleanup) throw const FormatException('Verification cannot request interaction.');
    // This private client permits start/cancel concurrency. It never enters
    // the ordinary connection's serialized elicitation queue.
    final pending = _client.callTool(toolIdentifier, arguments);
    final result = cleanup ? await pending : await Future.any([
      pending, _elicited.future.then<mcp.CallToolResult>((_) => throw const FormatException('Verification cannot request interaction.')),
    ]);
    final adapted = McpSdkAdapter.toolResult(result);

    return McpToolCallerResult(modelText: adapted.toModelText(), appData: const {}, structuredContent: adapted.structuredContent, isError: adapted.isError);
  }

  Future<mcp.ElicitResult> _rejectElicitation(mcp.ElicitRequestParams request) async {
    if (!_elicited.isCompleted) _elicited.complete();

    return mcp.ElicitResult(action: mcp.ElicitResultAction.cancel);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (!_elicited.isCompleted) _elicited.complete();
    _client.disconnect();
  }
}

final class _VerificationTransport(final mcp.ClientTransport inner, final void Function(Object? message) inspect) implements mcp.ClientTransport {
  @override
  Stream<Object?> get onMessage => inner.onMessage.map((Object? message) { inspect(message); return message; });
  @override
  Future<void> get onClose => inner.onClose;
  @override
  void send(Object? message) => inner.send(message);
  @override
  void close() => inner.close();
}
