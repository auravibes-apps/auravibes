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
  ) {
    final lease = _acquire(invocation.conversationId);

    return _startRun(invocation, lease, execute);
  }

  Future<ScopedVerificationResult> _startRun(
    ScopedVerificationInvocation invocation,
    _ScopeLease lease,
    Future<ScopedVerificationResult> Function(AgentCancellationScope scope)
    execute,
  ) => _ScopedVerificationRun(
    owner: this,
    invocation: invocation,
    lease: lease,
    execute: execute,
  ).run();

  _ScopeLease _acquire(String conversationId) {
    final existing = _leases[conversationId];
    final current = runtime.current(conversationId);
    final reusable = _reusableLease(existing, current);
    if (reusable != null) return reusable;

    return _replaceLease(conversationId, current);
  }

  _ScopeLease? _reusableLease(_ScopeLease? existing, AgentCancellationScope? current) {
    if (existing == null || !identical(existing.scope, current)) return null;
    existing.users++;

    return existing;
  }

  _ScopeLease _replaceLease(
    String conversationId,
    AgentCancellationScope? current,
  ) {
    final scope = current ?? runtime.start(conversationId);
    final lease = _ScopeLease(scope, owned: current == null);
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
  new({
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
    final state = _beginRun();
    try {
      final result = await execute(state.child);
      _terminal = result;

      return result;
    } finally {
      _finish(
        state.child,
        state.globalStop,
        state.completion,
        state.handle,
      );
    }
  }

  _ScopedVerificationRunState _beginRun() {
    final child = AgentCancellationScope();
    final globalStop = lease.scope.registerCleanup(child.requestStop);
    final completion = Completer<Object?>();
    final handle = _registerHandle((child: child, completion: completion));

    return (
      child: child,
      globalStop: globalStop,
      completion: completion,
      handle: handle,
    );
  }

  AgentToolCancellationHandle _registerHandle(
    ({AgentCancellationScope child, Completer<Object?> completion}) request,
  ) => runtime.registerToolCancellationHandle((
    conversationId: invocation.conversationId,
    toolCallId: invocation.toolCallId,
    isSupported: true,
    cancel: () => _cancelChild(request),
    operationResult: request.completion.future,
    isCancellationConfirmed: _isCancellationConfirmed,
  ));

  Future<void> _cancelChild(
    ({AgentCancellationScope child, Completer<Object?> completion}) request,
  ) async {
    request.child.requestStop();
    final _ = await request.completion.future;
  }

  bool _isCancellationConfirmed() =>
      _terminal?.outcome == ScopedVerificationOutcome.cancelled;

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

typedef _ScopedVerificationRunState = ({
  AgentCancellationScope child,
  AgentCancellationCleanupRegistration globalStop,
  Completer<Object?> completion,
  AgentToolCancellationHandle handle,
});

final class _ScopeLease {
  new(this.scope, {required this.owned});
  final AgentCancellationScope scope;
  final bool owned;
  int users = 1;
}
