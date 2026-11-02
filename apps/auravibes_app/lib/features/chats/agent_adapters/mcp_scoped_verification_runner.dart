import 'dart:convert';

import 'package:auravibes_app/services/agent_harness/mcp_tool_caller.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Uses only an owner-bound remote runner on the editing tool's MCP server.
/// Create a fresh instance per verification invocation. Cleanup authority is
/// retained only for that instance's single host-created start intent.
class McpScopedVerificationRunner implements ScopedVerificationRunner, ScopedVerificationRunnerLifecycle {
  new({
    required this.mcpServerId,
    required this.editMcpServerId,
    required this.runnerToolIdentifier,
    required this.caller,
    required this.isAllowed,
    this.onClose,
  });

  final String mcpServerId;
  final String editMcpServerId;
  final String runnerToolIdentifier;
  final McpToolCaller caller;
  final Future<bool> Function() isAllowed;
  final void Function()? onClose;
  ({String operationId, String workspaceRoot, int deadlineMs, String fingerprint})? _bound;
  bool _cancelRequested = false;
  @override
  void close() => onClose?.call();
  @override
  Future<ScopedVerificationCapabilities> capabilities() async =>
      ScopedVerificationCapabilities.fromJson(await _dispatch('capabilities', const {}));

  @override
  Future<ScopedVerificationJob> start(ScopedVerificationRequest request) async =>
      ScopedVerificationJob.fromJson(await _dispatch('start', request.toJson()));

  @override
  Future<ScopedVerificationJob> poll(String operationId) async =>
      ScopedVerificationJob.fromJson(await _dispatch('poll', {'operationId': operationId}));

  @override
  Future<ScopedVerificationJob> cancel(String operationId) async =>
      ScopedVerificationJob.fromJson(await _dispatch('cancel', {'operationId': operationId}));

  Future<Object?> _dispatch(String operation, Map<String, Object?> arguments) async {
    if (mcpServerId.isEmpty || mcpServerId != editMcpServerId || runnerToolIdentifier.isEmpty) {
      throw const FormatException('Verification needs the editing server binding.');
    }
    final payload = await _authorizedPayload(operation, arguments);
    if (operation == 'start' && _cancelRequested) {
      throw StateError('Cancelled verification cannot dispatch start.');
    }
    final result = await caller(
      mcpServerId: mcpServerId,
      toolIdentifier: runnerToolIdentifier,
      arguments: {...payload, 'protocol': ScopedVerificationLimits.protocol, 'operation': operation},
    );
    if (result is! McpToolCallerResult || result.isError == true) {
      throw const FormatException('Verification needs a structured MCP receipt.');
    }

    return result.structuredContent;
  }

  Future<Map<String, Object?>> _authorizedPayload(String operation, Map<String, Object?> arguments) async {
    if (operation == 'start') _bindStartIntent(arguments);
    if (operation == 'cancel') {
      final bound = _bound;
      if (bound == null || arguments['operationId'] != bound.operationId) {
        throw StateError('Cleanup is restricted to this admitted operation.');
      }

      // Revoking execution permission must not prevent stopping admitted work.
      _cancelRequested = true;
      return {...arguments, 'workspaceRoot': bound.workspaceRoot, 'deadlineMs': bound.deadlineMs};
    }
    if (!await isAllowed()) throw StateError('Verification permission is unavailable.');
    if (operation == 'start' && _cancelRequested) {
      throw StateError('Cancelled verification cannot start after admission.');
    }

    return arguments;
  }

  void _bindStartIntent(Map<String, Object?> arguments) {
    final bound = _bound;
    final fingerprint = jsonEncode(arguments);
    if (_cancelRequested || (bound != null && bound.fingerprint != fingerprint)) {
      throw StateError('A verification runner cannot replace its start intent.');
    }
    // Bind synchronously, before any permission future can yield to a stop.
    _bound = (
      operationId: arguments['operationId']! as String,
      workspaceRoot: arguments['workspaceRoot']! as String,
      deadlineMs: arguments['deadlineMs']! as int,
      fingerprint: fingerprint,
    );
  }
}
