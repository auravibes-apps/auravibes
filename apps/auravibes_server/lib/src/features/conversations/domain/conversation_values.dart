abstract final class ConversationStatuses {
  static const queued = 'queued';
  static const running = 'running';
  static const awaitingApproval = 'awaitingApproval';
  static const cancelRequested = 'cancelRequested';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
  static const failed = 'failed';

  static bool isTerminal(String status) =>
      status == cancelled || status == completed || status == failed;

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
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const failed = 'failed';
}
