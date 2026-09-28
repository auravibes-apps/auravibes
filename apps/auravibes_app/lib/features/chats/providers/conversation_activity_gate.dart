import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:riverpod/riverpod.dart';

class ConversationActivityGate {
  final Map<String, int> _activeActivities = {};
  final Set<String> _checkpointRestores = {};

  bool tryBeginActivity(String conversationId) =>
      tryBeginActivities([conversationId]);

  Future<T> runActivity<T>(
    String conversationId,
    Future<T> Function() action,
  ) => runActivities([conversationId], action);

  Future<T> runActivities<T>(
    Iterable<String> conversationIds,
    Future<T> Function() action,
  ) async {
    final ids = conversationIds.toSet();
    if (!tryBeginActivities(ids)) {
      throw const CompactionCheckpointRestoreException();
    }
    try {
      return await action();
    } finally {
      endActivities(ids);
    }
  }

  bool tryBeginActivities(Iterable<String> conversationIds) {
    final uniqueIds = conversationIds.toSet();
    if (uniqueIds.any(isCheckpointRestoreInProgress)) return false;

    for (final conversationId in uniqueIds) {
      final _ = _activeActivities.update(
        conversationId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return true;
  }

  void endActivity(String conversationId) => endActivities([conversationId]);

  void endActivities(Iterable<String> conversationIds) {
    for (final conversationId in conversationIds.toSet()) {
      final count = _activeActivities[conversationId];
      if (count == null) continue;
      if (count == 1) {
        final _ = _activeActivities.remove(conversationId);
      } else {
        _activeActivities[conversationId] = count - 1;
      }
    }
  }

  bool tryBeginCheckpointRestore(String conversationId) {
    if (_checkpointRestores.contains(conversationId) ||
        _activeActivities.containsKey(conversationId)) {
      return false;
    }
    final _ = _checkpointRestores.add(conversationId);

    return true;
  }

  bool isCheckpointRestoreInProgress(String conversationId) =>
      _checkpointRestores.contains(conversationId);

  void endCheckpointRestore(String conversationId) {
    final _ = _checkpointRestores.remove(conversationId);
  }

  Future<T> runCheckpointRestore<T>(
    String conversationId,
    Future<T> Function() action,
  ) async {
    if (!tryBeginCheckpointRestore(conversationId)) {
      throw const CompactionCheckpointRestoreException();
    }
    try {
      return await action();
    } finally {
      endCheckpointRestore(conversationId);
    }
  }
}

final conversationActivityGateProvider = Provider<ConversationActivityGate>(
  (_) => ConversationActivityGate(),
);
