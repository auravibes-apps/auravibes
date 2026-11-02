import 'dart:async';

import 'package:auravibes_app/features/chats/models/scoped_verification_invocation.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Approval actions may verify outside a foreground agent loop. Own only their
/// temporary scope, sharing it until concurrent verification calls settle.
class ScopedVerificationCancellation {
  new(this.runtime);
  final AgentCancellationRuntime runtime;
  final _leases = <String, _ScopeLease>{};

  Future<ScopedVerificationResult> run(
    ScopedVerificationInvocation invocation,
    Future<ScopedVerificationResult> Function(AgentCancellationScope scope) execute,
  ) async {
    final lease = _acquire(invocation.conversationId);
    final child = AgentCancellationScope();
    final globalStop = lease.scope.registerCleanup(child.requestStop);
    final completion = Completer<Object?>();
    ScopedVerificationResult? terminal;
    final handle = runtime.registerToolCancellationHandle((
      conversationId: invocation.conversationId,
      toolCallId: invocation.toolCallId,
      isSupported: true,
      cancel: () async { child.requestStop(); final _ = await completion.future; },
      operationResult: completion.future,
      isCancellationConfirmed: () => terminal?.outcome == ScopedVerificationOutcome.cancelled,
    ));
    try {
      final result = await execute(child);
      terminal = result;

      return result;
    } finally {
      completion.complete(terminal);
      runtime.completeToolCancellationHandle(conversationId: invocation.conversationId, toolCallId: invocation.toolCallId, handle: handle);
      final _ = globalStop.remove();
      child.close();
      _release(invocation.conversationId, lease);
    }
  }

  _ScopeLease _acquire(String conversationId) {
    final existing = _leases[conversationId];
    final current = runtime.current(conversationId);
    if (existing != null && identical(existing.scope, current)) { existing.users++; return existing; }
    final lease = _ScopeLease(current ?? runtime.start(conversationId), current == null);
    _leases[conversationId] = lease;

    return lease;
  }

  void _release(String conversationId, _ScopeLease lease) {
    lease.users--;
    if (lease.users > 0) return;
    if (identical(_leases[conversationId], lease)) { final _ = _leases.remove(conversationId); }
    if (lease.owned) runtime.clear(conversationId, lease.scope);
  }
}

final class _ScopeLease {
  _ScopeLease(this.scope, this.owned);
  final AgentCancellationScope scope;
  final bool owned;
  int users = 1;
}
