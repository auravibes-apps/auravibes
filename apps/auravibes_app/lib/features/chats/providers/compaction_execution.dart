import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compaction_execution.g.dart';

@Riverpod(keepAlive: true)
class CompactionExecution extends _$CompactionExecution {
  final Map<String, Timer> _cleanupTimers = {};

  @override
  Map<String, CompactionExecutionState> build() {
    final _ = ref.onDispose(() {
      for (final timer in _cleanupTimers.values) {
        timer.cancel();
      }
    });
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

    _cleanupTimers[conversationId]?.cancel();
    _cleanupTimers[conversationId] = Timer(
      const Duration(milliseconds: 500),
      () => markSuccessCleanup(conversationId),
    );
  }

  /// @visibleForTesting
  void markSuccessCleanup(String conversationId) {
    if (state[conversationId]?.status == CompactionExecutionStatus.success) {
      state = {
        for (final entry in state.entries)
          if (entry.key != conversationId) entry.key: entry.value,
      };
    }
    final _ = _cleanupTimers.remove(conversationId);
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

    _cleanupTimers[conversationId]?.cancel();
    _cleanupTimers[conversationId] = Timer(
      const Duration(seconds: 3),
      () => markFailureCleanup(conversationId),
    );
  }

  /// @visibleForTesting
  void markFailureCleanup(String conversationId) {
    if (state[conversationId]?.status == CompactionExecutionStatus.failure) {
      state = {
        for (final entry in state.entries)
          if (entry.key != conversationId) entry.key: entry.value,
      };
    }
    final _ = _cleanupTimers.remove(conversationId);
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
