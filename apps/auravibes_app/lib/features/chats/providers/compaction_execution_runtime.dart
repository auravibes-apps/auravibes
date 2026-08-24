import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter for compaction execution notifier state changes.
class CompactionExecutionRuntime {
  const CompactionExecutionRuntime({
    required this.markRunning,
    required this.markSuccess,
    required this.markFailure,
  });

  final void Function(CompactionExecutionState executionState) markRunning;
  final void Function(String conversationId) markSuccess;
  final void Function(String conversationId) markFailure;
}

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
