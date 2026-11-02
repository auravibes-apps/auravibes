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
    Future<ScopedVerificationResult> Function(AgentCancellationScope scope)
    execute,
  ) => _ScopedVerificationRun(
    owner: this,
    invocation: invocation,
    lease: _acquire(invocation.conversationId),
    execute: execute,
  ).run();

  _ScopeLease _acquire(String conversationId) {
    final existing = _leases[conversationId];
    final current = runtime.current(conversationId);
    if (existing != null && identical(existing.scope, current)) {
      existing.users++;

      return existing;
    }
    final lease = _ScopeLease(
      current ?? runtime.start(conversationId),
      owned: current == null,
    );
    _leases[conversationId] = lease;

    return lease;
  }

  void _release(String conversationId, _ScopeLease lease) {
    lease.users--;
    if (lease.users > 0) return;
    if (identical(_leases[conversationId], lease)) {
      final _ = _leases.remove(conversationId);
    }
    if (lease.owned) runtime.clear(conversationId, lease.scope);
  }
}

final class _ScopedVerificationRun {
  _ScopedVerificationRun({
    required this.owner,
    required this.invocation,
    required this.lease,
    required this.execute,
  });

  final ScopedVerificationCancellation owner;
  final ScopedVerificationInvocation invocation;
  final _ScopeLease lease;
  final Future<ScopedVerificationResult> Function(AgentCancellationScope scope)
  execute;
  ScopedVerificationResult? _terminal;

  AgentCancellationRuntime get runtime => owner.runtime;

  Future<ScopedVerificationResult> run() async {
    final child = AgentCancellationScope();
    final globalStop = lease.scope.registerCleanup(child.requestStop);
    final completion = Completer<Object?>();
    final handle = _registerHandle(child, completion);
    try {
      final result = await execute(child);
      _terminal = result;

      return result;
    } finally {
      _finish(child, globalStop, completion, handle);
    }
  }

  AgentToolCancellationHandle _registerHandle(
    AgentCancellationScope child,
    Completer<Object?> completion,
  ) => runtime.registerToolCancellationHandle((
    conversationId: invocation.conversationId,
    toolCallId: invocation.toolCallId,
    isSupported: true,
    cancel: () async {
      child.requestStop();
      final _ = await completion.future;
    },
    operationResult: completion.future,
    isCancellationConfirmed: () =>
        _terminal?.outcome == ScopedVerificationOutcome.cancelled,
  ));

  void _finish(
    AgentCancellationScope child,
    AgentCancellationCleanupRegistration globalStop,
    Completer<Object?> completion,
    AgentToolCancellationHandle handle,
  ) {
    completion.complete(_terminal);
    runtime.completeToolCancellationHandle(
      conversationId: invocation.conversationId,
      toolCallId: invocation.toolCallId,
      handle: handle,
    );
    final _ = globalStop.remove();
    child.close();
    owner._release(invocation.conversationId, lease);
  }
}

final class _ScopeLease {
  new(this.scope, {required this.owned});
  final AgentCancellationScope scope;
  final bool owned;
  int users = 1;
}
