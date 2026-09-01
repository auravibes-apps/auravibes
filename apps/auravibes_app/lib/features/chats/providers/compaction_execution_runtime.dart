import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter for compaction execution notifier state changes.
class const CompactionExecutionRuntime({
  required final void Function(CompactionExecutionState executionState)
  markRunning,
  required final void Function(String conversationId) markSuccess,
  required final void Function(String conversationId) markFailure,
});

final compactionExecutionRuntimeProvider = Provider<CompactionExecutionRuntime>(
  (ref) {
    final notifier = ref.watch(compactionExecutionProvider.notifier);

    return CompactionExecutionRuntime(
      markRunning: notifier.markRunning,
      markSuccess: notifier.markSuccess,
      markFailure: notifier.markFailure,
    );
  },
);
