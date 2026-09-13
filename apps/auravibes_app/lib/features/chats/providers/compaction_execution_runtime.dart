import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter for compaction execution notifier state changes.
class const CompactionExecutionRuntime({
  required final bool Function(CompactionExecutionState executionState)
  tryMarkRunning,
  required final void Function(CompactionExecutionState executionState)
  markRunning,
  required final void Function(String conversationId) markSuccess,
  required final void Function(String conversationId) markFailure,
});

extension CompactionExecutionLifecycle on CompactionExecutionRuntime {
  Future<CompactionExecutionState> run({
    required CompactionExecutionState runningState,
    required Future<CompactionExecutionState> Function() operation,
  }) async {
    if (!tryMarkRunning(runningState)) return runningState;

    try {
      final result = await operation();
      markSuccess(runningState.conversationId);

      return result;
    } on Exception {
      markFailure(runningState.conversationId);
      rethrow;
    }
  }
}

final compactionExecutionRuntimeProvider = Provider<CompactionExecutionRuntime>(
  (ref) {
    final notifier = ref.watch(compactionExecutionProvider.notifier);

    return CompactionExecutionRuntime(
      tryMarkRunning: notifier.tryMarkRunning,
      markRunning: notifier.markRunning,
      markSuccess: notifier.markSuccess,
      markFailure: notifier.markFailure,
    );
  },
);
