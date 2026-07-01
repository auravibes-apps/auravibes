import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:riverpod/riverpod.dart';

extension AgentCancellationRuntimeSubscriptions on AgentCancellationRuntime {
  void registerStreamSubscription<T>(
    String conversationId,
    StreamSubscription<T> subscription,
  ) {
    registerCleanup(
      conversationId,
      subscription.cancel,
    );
  }

  void registerCancelableOperation<T>(
    String conversationId,
    CancelableOperation<T> operation,
  ) {
    registerCleanup(
      conversationId,
      operation.cancel,
    );
  }
}

final agentCancellationRuntimeProvider = Provider<AgentCancellationRuntime>((
  ref,
) {
  return AgentCancellationRuntime();
});
