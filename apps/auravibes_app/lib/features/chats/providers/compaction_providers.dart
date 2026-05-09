import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compaction_providers.g.dart';

@Riverpod(keepAlive: true)
class CompactionExecution extends _$CompactionExecution {
  @override
  Map<String, CompactionExecutionState> build() {
    return {};
  }

  void markRunning(CompactionExecutionState executionState) {
    state = {
      ...state,
      executionState.conversationId: executionState.copyWith(
        status: CompactionExecutionStatus.running,
      ),
    };
  }

  void markSuccess(String conversationId) {
    final current = state[conversationId];
    if (current == null) return;

    state = {
      ...state,
      conversationId: current.copyWith(
        status: CompactionExecutionStatus.success,
      ),
    };

    Future.delayed(const Duration(milliseconds: 500), () {
      if (state[conversationId]?.status == CompactionExecutionStatus.success) {
        state = {
          for (final entry in state.entries)
            if (entry.key != conversationId) entry.key: entry.value,
        };
      }
    });
  }

  void markFailure(String conversationId) {
    final current = state[conversationId];
    if (current == null) return;

    state = {
      ...state,
      conversationId: current.copyWith(
        status: CompactionExecutionStatus.failure,
      ),
    };

    Future.delayed(const Duration(seconds: 3), () {
      if (state[conversationId]?.status == CompactionExecutionStatus.failure) {
        state = {
          for (final entry in state.entries)
            if (entry.key != conversationId) entry.key: entry.value,
        };
      }
    });
  }

  bool isCompacting(String conversationId) {
    final entry = state[conversationId];
    return entry != null && entry.status == CompactionExecutionStatus.running;
  }
}

@riverpod
CompactionExecutionState? compactionExecutionState(
  Ref ref,
  String conversationId,
) {
  final all = ref.watch(compactionExecutionProvider);
  return all[conversationId];
}
