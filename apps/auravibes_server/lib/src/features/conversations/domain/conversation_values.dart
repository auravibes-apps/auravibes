import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class ConversationStatuses {
  static const queued = 'queued';
  static const running = 'running';
  static const awaitingApproval = 'awaitingApproval';
  static const awaitingUserAction = 'awaitingUserAction';
  static const cancelRequested = 'cancelRequested';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
  static const failed = 'failed';

  static bool isTerminal(String status) =>
      status == cancelled || status == completed || status == failed;

  static bool isMessageTerminal(String status) =>
      status == 'sent' || status == 'error' || isTerminal(status);

  static bool isActive(String status) => !isTerminal(status);
}

abstract final class ConversationJobKinds {
  static const turn = 'turn';
  static const compact = 'compact';
  static const title = 'title';
  static const subAgent = 'subAgent';
}

abstract final class ConversationJobStatuses {
  static const queued = 'queued';
  static const leased = 'leased';
  static const waitingForSubAgents = 'waitingForSubAgents';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const failed = 'failed';
}

abstract final class ConversationSystemActorIds {
  /// Audit actor for automatic cancellation after an account has been erased.
  /// This stable sentinel records the cleanup action without attributing it to
  /// the deleted user whose queued turn is being terminalized.
  static const accountErasure = 'system:account-erasure';

  /// Audit actor for cleanup when workspace membership is unavailable.
  static const unavailableMembershipCleanup = 'system:conversation-cleanup';
}

abstract final class ConversationLimits {
  static const maxPinnedPerWorkspace = 10;
  static const maxPendingForksPerWorkspace = 32;
  static const maxForkHistoryMessages = 1000;

  /// At most eight detached operations may run across all server workspaces.
  /// A ninth detach stays attached to its foreground turn until capacity frees.
  static const maxConcurrentDetachedWork = 8;

  /// Completion turns remain durable and FIFO while the global job drain is busy.
  /// This is a steady-state bound; failover may briefly overlap an in-flight
  /// provider request before the previous worker observes lease loss.
  static const maxConcurrentBackgroundContinuations = 1;
}

abstract final class BackgroundWorkPreviews {
  /// Marker used while a durable completion message waits for its turn.
  static const queuedForContinuation = 'queued_for_continuation';

  /// Marker used while the completion follow-up is being executed.
  static const continuationInProgress = 'continuation_in_progress';

  /// Marker used when the completion follow-up ends without succeeding.
  static const continuationFailed = 'continuation_failed';
}

/// Stable cloud representation, independent of Dart enum names.
extension ConversationToolAccessModeStorage on ConversationToolAccessMode {
  String get storedValue => switch (this) {
    ConversationToolAccessMode.defaultMode => 'default',
    ConversationToolAccessMode.allowAll => 'allow_all',
  };

  static ConversationToolAccessMode decode(String value) => value == 'allow_all'
      ? ConversationToolAccessMode.allowAll
      : ConversationToolAccessMode.defaultMode;
}
